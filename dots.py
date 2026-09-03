#!/usr/bin/env python3
"""dots -- deploy this repository's packages as symlinks, and check the result.

The manifest is dots.toml at the repo root: one [packages.<name>] table per
package, each stating a mode and where it lands. Nothing is inferred from
paths. Files are enumerated with `git ls-files`, so an untracked file is never
deployed and .gitignore is the only ignore list.

    dots status|plan|apply|unlink|diff [PKG...]
    dots check | validate | doctor | deps | packages
    dots tools | install <name>

`dots check` is the repository gate CI runs: manifest and documentation rules,
then every linter and formatter the repo pins, then the tests. It reads only
the repository, never $HOME. `dots doctor` is the opposite: it inspects this
machine. Standard library only.
"""

from __future__ import annotations

import argparse
import difflib
import io
import json
import os
import re
import shutil
import string
import subprocess
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path

MODES = ("link", "tree")
MANIFEST = "dots.toml"

# What the gate lints, by language. Bash files are recognised by shebang or a
# ShellCheck directive, wherever they sit under these paths.
BASH_PATHS = ("shell", "tools", "config")
LUA_PATHS = ("config/nvim", "config/wezterm")
PYTHON_PATHS = ("dots.py", "tests")

REQUIRED_TOOLS = ("bash", "git", "python3", "find", "sed", "awk", "grep", "diff", "readlink", "file")
# fmt: off
OPTIONAL_TOOLS = [
    "shellcheck", "shfmt", "stylua", "prettierd", "eslint_d", "ruff", "luac", "fc-cache",
    "starship", "vim", "nvim", "tmux", "fzf", "bat", "rg", "fd", "ast-grep", "delta", "lazygit", "glow", "qmk",
    "git", "gh", "direnv", "uv", "rustup", "cargo", "go", "bun", "node", "npm", "pnpm", "yarn", "tldr",
    "kanata", "pi", "claude", "agy", "cf", "wrangler", "herdr", "nix",
]
# fmt: on


class DotsError(Exception):
    """A user-facing failure: printed as one line, no traceback."""


# --- output ------------------------------------------------------------------


class Out:
    def __init__(self, stream=sys.stdout):
        self.stream = stream
        color = stream.isatty() and not os.environ.get("NO_COLOR")
        self.bold, self.red, self.green, self.yellow, self.dim, self.reset = (
            ("\033[1m", "\033[31m", "\033[32m", "\033[33m", "\033[2m", "\033[0m") if color else ("",) * 6
        )

    def line(self, text: str = "") -> None:
        print(text, file=self.stream)

    def ok(self, text: str) -> None:
        self.line(f"{self.green}✓{self.reset} {text}")

    def warn(self, text: str) -> None:
        self.line(f"{self.yellow}!{self.reset} {text}")

    def title(self, text: str) -> None:
        self.line(f"{self.bold}{text}{self.reset}")


def err(text: str) -> None:
    print(f"error: {text}", file=sys.stderr)


def pretty(path: Path, home: Path) -> str:
    try:
        return "~/" + str(path.relative_to(home))
    except ValueError:
        return str(path)


# --- manifest ----------------------------------------------------------------


@dataclass(frozen=True)
class Link:
    package: str
    mode: str
    source: Path  # repo-relative
    target: str  # unexpanded, as written in the manifest


def load_manifest(root: Path) -> list[Link]:
    path = root / MANIFEST
    if not path.is_file():
        raise DotsError(f"manifest not found: {path}")
    try:
        data = tomllib.loads(path.read_text())
    except tomllib.TOMLDecodeError as exc:
        raise DotsError(f"{MANIFEST}: {exc}") from exc
    packages = data.get("packages")
    if not isinstance(packages, dict) or not packages:
        raise DotsError(f"{MANIFEST}: no [packages.<name>] tables")

    links: list[Link] = []
    for name, spec in packages.items():
        if not isinstance(spec, dict):
            raise DotsError(f"{name}: expected a table")
        mode = spec.get("mode")
        if mode not in MODES:
            raise DotsError(f"{name}: mode must be one of {', '.join(MODES)}; got {mode!r}")
        has_target, has_links = "target" in spec, "links" in spec
        if has_target == has_links:
            raise DotsError(f"{name}: give exactly one of target or links")
        base = Path(spec.get("source", f"config/{name}"))
        if has_target:
            links.append(Link(name, mode, base, str(spec["target"])))
            continue
        entries = spec["links"]
        if not isinstance(entries, list) or not entries:
            raise DotsError(f"{name}: links must be a non-empty list")
        for entry in entries:
            if not isinstance(entry, dict) or set(entry) != {"source", "target"}:
                raise DotsError(f"{name}: each links entry needs exactly source and target")
            links.append(Link(name, mode, base / entry["source"], str(entry["target"])))
    return links


def package_names(links: list[Link]) -> list[str]:
    seen: dict[str, None] = {}
    for link in links:
        seen.setdefault(link.package, None)
    return list(seen)


def select(links: list[Link], wanted: list[str]) -> list[Link]:
    """Filter by package name. An unknown name is an error, never a silent no-op."""
    if not wanted:
        return links
    known = set(package_names(links))
    unknown = [w for w in wanted if w not in known]
    if unknown:
        raise DotsError(f"unknown package: {', '.join(unknown)} (list them with `dots packages`)")
    return [link for link in links if link.package in wanted]


# --- filesystem --------------------------------------------------------------


class Repo:
    def __init__(self, root: Path, env: dict[str, str]):
        self.root = root
        self.env = env
        self.home = Path(env["HOME"])

    def tracked(self, rel: Path) -> list[Path]:
        out = subprocess.run(
            ["git", "-C", str(self.root), "ls-files", "-z", "--", str(rel)],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        return [Path(p) for p in out.split("\0") if p]

    def candidates(self) -> list[Path]:
        """Tracked files plus untracked ones .gitignore does not exclude.

        The gate lints these rather than only tracked files, so a new script is
        checked before it is added, while an ignored file like shell/local.sh
        never is.
        """
        out = subprocess.run(
            ["git", "-C", str(self.root), "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        return [Path(p) for p in out.split("\0") if p and (self.root / p).is_file()]

    def expand(self, target: str) -> Path:
        vars_ = {
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": self.env.get("XDG_CONFIG_HOME") or str(self.home / ".config"),
            "XDG_DATA_HOME": self.env.get("XDG_DATA_HOME") or str(self.home / ".local/share"),
        }
        text = target
        if text == "~" or text.startswith("~/"):
            text = str(self.home) + text[1:]
        return Path(string.Template(text).safe_substitute(vars_))

    def pairs(self, link: Link) -> list[tuple[Path, Path]]:
        """Every (absolute source, absolute target) symlink a manifest entry implies."""
        src = self.root / link.source
        dst = self.expand(link.target)
        if link.mode == "link":
            return [(src, dst)]
        return [(self.root / f, dst / f.relative_to(link.source)) for f in self.tracked(link.source)]

    def count_files(self, source: Path, dst: Path) -> tuple[int, int, int]:
        """Per-file tally for a directory source under a real target dir: ok, missing, conflict."""
        ok = missing = conflict = 0
        for f in self.tracked(source):
            target = dst / f.relative_to(source)
            if target.is_symlink() or target.exists():
                if same_path(target, self.root / f):
                    ok += 1
                else:
                    conflict += 1
            else:
                missing += 1
        return ok, missing, conflict


def same_path(a: Path, b: Path) -> bool:
    """Two paths are the same deployment if they resolve to the same place.

    An absent path resolves to nothing, so it never compares equal -- even to
    an absent source.
    """
    if not (a.exists() or a.is_symlink()):
        return False
    return os.path.realpath(a) == os.path.realpath(b)


def is_text(path: Path) -> bool:
    try:
        data = path.read_bytes()[:8192]
    except OSError:
        return False
    return b"\0" not in data


# --- commands: status / plan / apply / unlink / diff -------------------------


def state_of(repo: Repo, link: Link) -> tuple[str, str]:
    """Classify one manifest entry: (state, detail).

    `drift` means every file resolves into the repo but the link shape differs
    from the declared mode -- harmless, but worth seeing.
    """
    src = repo.root / link.source
    dst = repo.expand(link.target)
    if same_path(dst, src):
        if link.mode == "tree" and dst.is_symlink():
            return ("drift", "dir symlink; files resolve")
        return ("ok", "-" if dst.is_symlink() else "resolves via a symlinked parent")
    if not (dst.exists() or dst.is_symlink()):
        return ("missing", "-")
    if dst.is_dir() and src.is_dir():
        ok, missing, conflict = repo.count_files(link.source, dst)
        if missing == 0 and conflict == 0:
            if link.mode == "link":
                return ("drift", f"{ok} files resolve; not a dir symlink")
            return ("ok", f"{ok} files")
        return ("partial", f"ok={ok} missing={missing} conflict={conflict}")
    return ("conflict", "not a link into the repo")


def cmd_status(repo: Repo, links: list[Link], out: Out) -> int:
    out.title("Manifest status")
    out.line(f"  repo: {repo.root}\n")
    clean = drift = problems = 0
    for link in links:
        state, detail = state_of(repo, link)
        if state == "ok":
            clean += 1
            color = out.green
        elif state == "drift":
            drift += 1
            color = out.yellow
        else:
            problems += 1
            color = out.red
        target = pretty(repo.expand(link.target), repo.home)
        out.line(f"  {color}{state:<9}{out.reset} {link.mode:<4} {target:<44} {out.dim}{detail}{out.reset}")
    out.line(f"\n  {clean} ok, {drift} drift, {problems} problem(s)")
    return 1 if problems else 0


def place(repo: Repo, src: Path, dst: Path, apply: bool, out: Out) -> int:
    """Create or repoint one symlink. Returns 0 done, 1 conflict, 2 unfolded."""
    # Resolution first, link-ness second: a target can resolve into its source
    # through a symlinked ancestor without being a symlink itself.
    if same_path(dst, src):
        return 0
    shown = pretty(dst, repo.home)
    if dst.is_symlink():
        out.line(f"  {'relink':<8} {shown}")
        if apply:
            dst.unlink()
            dst.symlink_to(src)
        return 0
    if dst.exists():
        if dst.is_dir() and src.is_dir():
            ok, missing, conflict = repo.count_files(src.relative_to(repo.root), dst)
            if missing == 0 and conflict == 0:
                out.line(
                    f"  {out.yellow}unfolded{out.reset} {shown} "
                    f"{out.dim}({ok} files already resolve; a link-mode row wants one dir symlink){out.reset}"
                )
                return 2
        note = "existing real file -- remove or adopt it"
        out.line(f"  {out.red}CONFLICT{out.reset} {shown} {out.dim}({note}){out.reset}")
        return 1
    out.line(f"  {'link':<8} {shown}")
    if apply:
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.symlink_to(src)
    return 0


def cmd_link(repo: Repo, links: list[Link], out: Out, apply: bool) -> int:
    out.title("Applying" if apply else "Dry run (nothing will be modified; `dots apply` commits)")
    in_scope = unfolded = conflicts = 0
    for link in links:
        for src, dst in repo.pairs(link):
            rc = place(repo, src, dst, apply, out)
            if rc == 0:
                in_scope += 1
            elif rc == 2:
                unfolded += 1
            else:
                conflicts += 1
    out.line(f"\n  {in_scope} link(s) in scope, {unfolded} unfolded, {conflicts} conflict(s)")
    return 1 if conflicts else 0


def cmd_unlink(repo: Repo, links: list[Link], out: Out) -> int:
    removed = 0
    for link in links:
        for src, dst in repo.pairs(link):
            if dst.is_symlink() and same_path(dst, src):
                out.line(f"  {'unlink':<8} {pretty(dst, repo.home)}")
                dst.unlink()
                removed += 1
    out.line(f"\n  {removed} link(s) removed")
    return 0


def cmd_diff(repo: Repo, links: list[Link], out: Out) -> int:
    """Content differences for targets that are real files rather than links.

    A correctly deployed target cannot differ from its source -- it is its
    source -- so anything shown here is a target that drifted.
    """
    shown = False
    for link in links:
        for src, dst in repo.pairs(link):
            if same_path(dst, src):
                continue
            shown = True
            name = pretty(dst, repo.home)
            if not (dst.exists() or dst.is_symlink()):
                out.warn(f"missing in target: {name}")
                continue
            out.line(f"\n{out.bold}== {name} =={out.reset}")
            if src.is_file() and dst.is_file() and is_text(src) and is_text(dst):
                for line in difflib.unified_diff(
                    dst.read_text().splitlines(), src.read_text().splitlines(), str(dst), str(src), lineterm=""
                ):
                    out.line(line)
            else:
                out.warn("differs and is not a text file pair")
    if not shown:
        out.ok("no differences; every target resolves to its repo source")
    return 0


# --- commands: validate / packages -------------------------------------------


def cmd_validate(repo: Repo, links: list[Link], out: Out) -> int:
    """Repository-only checks, safe for CI: the manifest, and the doc rules."""
    errors: list[str] = []
    for link in links:
        src = repo.root / link.source
        if not (src.exists() or src.is_symlink()):
            errors.append(f"{link.package}: source does not exist: {link.source}")
        elif not repo.tracked(link.source):
            errors.append(f"{link.package}: source has no tracked files: {link.source}")
        if not (link.target.startswith("~/") or link.target.startswith("$")):
            errors.append(f"{link.package}: target must start with ~/ or a $VARIABLE: {link.target}")

    # A package directory holds only deployable content, because git ls-files
    # enumerates it. A README inside one would be deployed with the package.
    for link in links:
        for f in repo.tracked(link.source):
            if f.name == "README.md":
                errors.append(f"{link.package}: README.md inside a package source would be deployed: {f}")

    for name in package_names(links):
        if not (repo.root / "docs" / f"{name}.md").is_file():
            errors.append(f"{name}: no docs/{name}.md")

    for entry in sorted(repo.root.iterdir()):
        if entry.is_dir() and not entry.name.startswith(".") and not (entry / "README.md").is_file():
            errors.append(f"{entry.name}/: top-level directory without a README.md")

    for e in errors:
        err(e)
    if not errors:
        out.ok(f"{MANIFEST}: {len(package_names(links))} packages, {len(links)} entries, docs complete")
    return 1 if errors else 0


def cmd_packages(repo: Repo, links: list[Link], out: Out) -> int:
    for name in package_names(links):
        out.line(name)
    return 0


# --- commands: deps / doctor / check / tools ---------------------------------


def cmd_deps(repo: Repo, links: list[Link], out: Out) -> int:
    missing = 0
    out.title("Required:")
    for tool in REQUIRED_TOOLS:
        path = shutil.which(tool)
        if path:
            out.ok(f"{tool}: {path}")
        else:
            out.warn(f"{tool} missing")
            missing = 1
    out.title("\nOptional / package-specific:")
    for tool in OPTIONAL_TOOLS:
        path = shutil.which(tool)
        out.ok(f"{tool}: {path}") if path else out.warn(f"{tool} missing")
    return missing


def shadowed_flake_binaries(repo: Repo) -> list[str]:
    """Flake binaries that an earlier PATH entry provides first.

    Installed but never run is silent: `nix profile list` and `dots deps` both
    look healthy. ~/.local/bin sits ahead of the profile and cannot be reordered
    from this repo, so detect it and delete the older copy when it shows up.
    """
    profile = repo.home / ".nix-profile/bin"
    found = []
    if profile.is_dir():
        for binary in sorted(profile.iterdir()):
            if binary.is_dir() or not os.access(binary, os.X_OK):
                continue
            resolved = shutil.which(binary.name)
            if resolved and resolved.startswith("/") and resolved != str(binary):
                found.append(f"{binary.name}: {resolved}")
    return found


def cmd_doctor(repo: Repo, links: list[Link], out: Out) -> int:
    """Live-machine health: shell wiring, the deployed entrypoint, link state."""
    fail = 0
    out.title("Dotfiles doctor\n")

    git_status = ["git", "-C", str(repo.root), "status", "--porcelain"]
    dirty = subprocess.run(git_status, capture_output=True, text=True).stdout
    out.ok("git working tree clean") if not dirty else out.warn("git working tree has changes")

    expected = repo.root / "config/scripts/dots"
    deployed = repo.home / ".local/bin/dots"
    if same_path(deployed, expected):
        out.ok("~/.local/bin/dots points at config/scripts/dots")
    else:
        out.warn("~/.local/bin/dots is not linked to config/scripts/dots; run: dots apply scripts")
        fail = 1

    bashrc = repo.home / ".bashrc"
    if bashrc.is_file() and ".dots/shell/_init_.sh" in bashrc.read_text():
        out.ok("~/.bashrc sources shell/_init_.sh")
    else:
        out.warn("~/.bashrc does not appear to source shell/_init_.sh")
        fail = 1

    if (repo.root / "shell/local.sh").is_file():
        out.ok("shell/local.sh exists")
    else:
        out.warn("shell/local.sh missing; copy shell/local.sh.example")

    # kanata needs the binary, the input group, and a running service; each
    # fails independently and none is visible from the config alone.
    if shutil.which("kanata"):
        groups = subprocess.run(["id", "-nG"], capture_output=True, text=True).stdout.split()
        if "input" in groups:
            out.ok("user is in the input group")
        else:
            out.warn("user is not in the input group; see docs/kanata.md (needs re-login)")
            fail = 1
        active = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "kanata.service"]).returncode == 0
        if active:
            out.ok("kanata.service is running")
        else:
            out.warn("kanata.service is not running; start it: systemctl --user start kanata.service")
            fail = 1
    else:
        out.warn("kanata unavailable; skipping keyboard remapper checks")

    shadowed = shadowed_flake_binaries(repo)
    if shadowed:
        out.warn("flake binaries shadowed by an earlier PATH entry (delete the older copy):")
        for line in shadowed:
            out.line(f"    {line}")
        fail = 1
    else:
        out.ok("no flake binary is shadowed on PATH")

    gate_log = io.StringIO()
    if cmd_check(repo, links, Out(stream=gate_log)) == 0:
        out.ok("repository checks pass")
    else:
        out.warn("repository checks failed")
        out.line(gate_log.getvalue())
        fail = 1

    if cmd_status(repo, links, Out(stream=io.StringIO())) == 0:
        out.ok("all manifest entries resolve into the repo")
    else:
        out.warn("manifest entries report missing or conflicting targets; see `dots status`")
        fail = 1

    out.line()
    out.warn("doctor found issues") if fail else out.ok("doctor passed")
    return fail


# --- commands: check (the repository gate) -----------------------------------


def is_bash_file(path: Path) -> bool:
    """Scripts carry a shebang; sourced files declare their shell with a directive."""
    try:
        with path.open("rb") as fh:
            first = fh.readline().decode(errors="replace")
    except OSError:
        return False
    return re.match(r"^#!.*\bbash\b|^# shellcheck shell=bash$", first) is not None


def under(path: Path, prefixes: tuple[str, ...]) -> bool:
    return any(path == Path(p) or Path(p) in path.parents for p in prefixes)


def broken_doc_links(repo: Repo) -> list[str]:
    """Relative markdown links whose target does not exist.

    Nothing renders this repo's markdown, so a broken link is invisible until
    someone follows it; the stow-to-manifest migration broke 29 in one commit.
    """
    broken = []
    for f in repo.tracked(Path(".")):
        if f.suffix != ".md":
            continue
        for m in re.finditer(r"\[[^\]]*\]\(([^)#][^)]*)\)", (repo.root / f).read_text()):
            target = m.group(1)
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            if not (repo.root / f.parent / target.split("#")[0]).exists():
                broken.append(f"{f} -> {target}")
    return broken


class Gate:
    """Runs the gate steps, tallying failures; REQUIRE_LINTERS=1 makes a missing tool fatal."""

    def __init__(self, repo: Repo, out: Out):
        self.repo = repo
        self.out = out
        self.require = os.environ.get("REQUIRE_LINTERS") == "1"
        self.failed = False

    def fail(self, message: str) -> None:
        err(message)
        self.failed = True

    def have(self, tool: str) -> bool:
        if shutil.which(tool):
            return True
        if self.require:
            self.fail(f"{tool} is required but unavailable")
        else:
            self.out.line(f"Skipping {tool} (not installed).")
        return False

    def run(self, *cmd: str, quiet: bool = False) -> bool:
        result = subprocess.run(cmd, cwd=self.repo.root, capture_output=quiet, text=True)
        if result.returncode != 0:
            self.failed = True
        return result.returncode == 0


def cmd_check(repo: Repo, links: list[Link], out: Out) -> int:
    gate = Gate(repo, out)
    files = repo.candidates()

    out.line("Validating manifest and documentation rules...")
    if cmd_validate(repo, links, Out(stream=io.StringIO())) != 0:
        gate.failed = True

    out.line("Checking documentation links...")
    for entry in broken_doc_links(repo):
        gate.fail(f"broken doc link: {entry}")

    bash_files = [str(f) for f in files if under(f, BASH_PATHS) and is_bash_file(repo.root / f)]
    out.line("Checking Bash syntax...")
    for f in bash_files:
        gate.run("bash", "-n", f)
    if bash_files and gate.have("shellcheck"):
        out.line("Running ShellCheck...")
        gate.run("shellcheck", "-x", "-S", "warning", *bash_files)
    # No flags on purpose: shfmt then reads .editorconfig, the same rules the
    # editor's format-on-save applies. Any formatting flag would make it ignore
    # .editorconfig and silently diverge.
    if bash_files and gate.have("shfmt"):
        out.line("Checking Bash formatting...")
        if not gate.run("shfmt", "--diff", *bash_files):
            err("bash files are not shfmt-formatted; run: shfmt -w <file>")

    out.line("Parsing JSON and TOML configuration...")
    for f in files:
        if "node_modules" in f.parts:
            continue
        try:
            if f.suffix == ".json":
                json.loads((repo.root / f).read_text())
            elif f.suffix == ".toml":
                tomllib.loads((repo.root / f).read_text())
        except (ValueError, UnicodeDecodeError) as exc:
            gate.fail(f"{f}: {exc}")

    lua_files = [str(f) for f in files if under(f, LUA_PATHS) and f.suffix == ".lua"]
    if lua_files and gate.have("luac"):
        out.line("Checking Lua syntax...")
        for f in lua_files:
            gate.run("luac", "-p", f)
    if lua_files and gate.have("stylua"):
        out.line("Checking Lua formatting...")
        gate.run("stylua", "--check", *LUA_PATHS)

    # A kanata config that does not parse leaves the keyboard unmapped, and the
    # failure only shows up when the service restarts. --check parses without
    # touching any device. Never escalated: it is package-specific software.
    kanata_cfg = repo.root / "config/kanata/kanata.kbd"
    if kanata_cfg.is_file():
        if shutil.which("kanata"):
            out.line("Checking kanata configuration...")
            gate.run("kanata", "--cfg", str(kanata_cfg), "--check", quiet=True)
        else:
            out.line("Skipping kanata config check (kanata not installed).")

    python_paths = [p for p in PYTHON_PATHS if (repo.root / p).exists()]
    if python_paths and gate.have("ruff"):
        out.line("Checking Python lint and formatting...")
        gate.run("ruff", "check", "--quiet", *python_paths)
        gate.run("ruff", "format", "--check", "--quiet", *python_paths)

    if (repo.root / "tests").is_dir():
        out.line("Running tests...")
        gate.run(sys.executable, "-m", "unittest", "discover", "--quiet", "-s", "tests")

    if gate.failed:
        err("repository checks failed")
        return 1
    out.line("Repository checks passed.")
    return 0


def installers(repo: Repo) -> list[str]:
    return sorted(p.name[len("install-") : -len(".sh")] for p in (repo.root / "tools").glob("install-*.sh"))


def cmd_tools(repo: Repo, links: list[Link], out: Out) -> int:
    for name in installers(repo):
        out.line(name)
    return 0


def cmd_install(repo: Repo, links: list[Link], out: Out, name: str) -> int:
    if name not in installers(repo):
        raise DotsError(f"no installer tools/install-{name}.sh (list them with `dots tools`)")
    return subprocess.run(["bash", str(repo.root / "tools" / f"install-{name}.sh")]).returncode


# --- entry point -------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dots", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--repo", type=Path, help="repository root (default: the one this script lives in)")
    sub = parser.add_subparsers(dest="command", metavar="command")
    for name, doc in (
        ("status", "what is deployed, and does it match the manifest"),
        ("plan", "preview link changes; never mutates"),
        ("apply", "create or repoint symlinks"),
        ("unlink", "remove symlinks that resolve into this repo"),
        ("diff", "content differences for targets that drifted"),
    ):
        p = sub.add_parser(name, help=doc)
        p.add_argument("packages", nargs="*", metavar="PKG")
    sub.add_parser("packages", help="list the package names the manifest knows about")
    sub.add_parser("validate", help="manifest and documentation rules (repository only, CI-safe)")
    sub.add_parser("check", help="the full repository gate CI runs")
    sub.add_parser("doctor", help="health checks against this machine")
    sub.add_parser("deps", help="which expected tools are installed")
    sub.add_parser("tools", help="list the installers under tools/")
    sub.add_parser("install", help="run tools/install-<name>.sh").add_argument("name")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    root = (args.repo or Path(__file__).resolve().parent).resolve()
    repo = Repo(root, dict(os.environ))
    out = Out()
    try:
        links = load_manifest(root)
        wanted = getattr(args, "packages", [])
        chosen = select(links, wanted)
        command = args.command or "status"
        if command == "status":
            return cmd_status(repo, chosen, out)
        if command == "plan":
            return cmd_link(repo, chosen, out, apply=False)
        if command == "apply":
            return cmd_link(repo, chosen, out, apply=True)
        if command == "unlink":
            return cmd_unlink(repo, chosen, out)
        if command == "diff":
            return cmd_diff(repo, chosen, out)
        if command == "install":
            return cmd_install(repo, links, out, args.name)
        handlers = {
            "packages": cmd_packages,
            "validate": cmd_validate,
            "check": cmd_check,
            "doctor": cmd_doctor,
            "deps": cmd_deps,
            "tools": cmd_tools,
        }
        return handlers[command](repo, links, out)
    except DotsError as exc:
        err(str(exc))
        return 2


if __name__ == "__main__":
    sys.exit(main())
