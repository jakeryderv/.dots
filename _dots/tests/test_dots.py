"""Behaviour tests for _dots/dots.py, against a throwaway fixture repo.

The CLI is driven through subprocess with --repo pointing at the fixture and
HOME at a scratch directory, so every test exercises the real entry point.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

DOTS = Path(__file__).resolve().parent.parent / "dots.py"

MANIFEST = """
[packages.alpha]
mode = "link"
target = "~/.config/alpha"

[packages.beta]
mode = "tree"
target = "$XDG_CONFIG_HOME/beta"

[packages.gitcfg]
mode = "link"
source = "config/gitcfg/gitconfig"
target = "~/.gitconfig"

[packages.tools]
mode = "tree"
target = "~/.local/bin"

[packages.fanout]
mode = "link"
links = [
  { source = "one.conf", target = "~/.config/one/one.conf" },
  { source = "two.service", target = "~/.config/systemd/user/two.service" },
]
"""


def git(repo: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)


class Fixture:
    def __init__(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.repo = self.tmp / "repo"
        self.home = self.tmp / "home"
        self.home.mkdir()
        for rel, text in {
            "config/alpha/alpha.conf": "alpha\n",
            "config/beta/beta.conf": "beta\n",
            "config/beta/nested/deep.conf": "nested\n",
            "config/gitcfg/gitconfig": "[user]\n\tname = fixture\n",
            "config/tools/tool": "#!/bin/sh\n",
            "config/fanout/one.conf": "one\n",
            "config/fanout/two.service": "[Unit]\n",
            "config/README.md": "# config\n",
            "docs/alpha.md": "a\n",
            "docs/beta.md": "b\n",
            "docs/gitcfg.md": "g\n",
            "docs/tools.md": "t\n",
            "docs/fanout.md": "f\n",
            "docs/README.md": "d\n",
            "dots.toml": MANIFEST,
        }.items():
            path = self.repo / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        git(self.repo, "init", "-q")
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "init")
        # Created after the commit and never added: the git ls-files enumerator
        # must skip it. This is what makes .gitignore the only ignore list.
        (self.repo / "config/beta/untracked.conf").write_text("untracked\n")

    def run(self, *args: str) -> subprocess.CompletedProcess[str]:
        env = {
            **os.environ,
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "NO_COLOR": "1",
        }
        return subprocess.run(
            [sys.executable, str(DOTS), "--repo", str(self.repo), *args],
            env=env,
            capture_output=True,
            text=True,
        )

    def cleanup(self) -> None:
        shutil.rmtree(self.tmp)


class DeployTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fx = Fixture()
        self.addCleanup(self.fx.cleanup)
        self.home = self.fx.home
        self.repo = self.fx.repo

    def assert_rc(self, result: subprocess.CompletedProcess[str], rc: int) -> None:
        self.assertEqual(result.returncode, rc, result.stdout + result.stderr)

    def test_plan_is_a_dry_run(self) -> None:
        self.assert_rc(self.fx.run("plan"), 0)
        self.assertFalse((self.home / ".config/alpha").exists())

    def test_status_reports_missing_before_apply(self) -> None:
        result = self.fx.run("status")
        self.assert_rc(result, 1)
        self.assertIn("6 problem(s)", result.stdout)

    def test_validate_passes_on_the_fixture(self) -> None:
        self.assert_rc(self.fx.run("validate"), 0)

    def test_apply_deploys_every_mode(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        self.assert_rc(self.fx.run("status"), 0)
        # link mode: one symlink at the target
        alpha = self.home / ".config/alpha"
        self.assertTrue(alpha.is_symlink())
        self.assertEqual(os.readlink(alpha), str(self.repo / "config/alpha"))
        # tree mode: real directories, one symlink per tracked file
        beta = self.home / ".config/beta"
        self.assertTrue(beta.is_dir() and not beta.is_symlink())
        self.assertTrue((beta / "beta.conf").is_symlink())
        self.assertTrue((beta / "nested/deep.conf").is_symlink())
        self.assertFalse((beta / "untracked.conf").exists(), "untracked file was deployed")
        # single-file source, and a tree row into a shared directory
        self.assertEqual(os.readlink(self.home / ".gitconfig"), str(self.repo / "config/gitcfg/gitconfig"))
        self.assertTrue((self.home / ".local/bin/tool").is_symlink())
        # links: one package, two places, real parent directories
        self.assertTrue((self.home / ".config/one/one.conf").is_symlink())
        self.assertTrue((self.home / ".config/systemd/user/two.service").is_symlink())
        self.assertFalse((self.home / ".config/one").is_symlink())

    def test_apply_is_idempotent(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        result = self.fx.run("apply")
        self.assert_rc(result, 0)
        self.assertIn("0 conflict(s)", result.stdout)
        self.assert_rc(self.fx.run("status"), 0)

    def test_package_filter_and_unknown_package(self) -> None:
        result = self.fx.run("plan", "alpha")
        self.assert_rc(result, 0)
        self.assertNotIn("beta", result.stdout)
        result = self.fx.run("plan", "nosuchpkg")
        self.assert_rc(result, 2)
        self.assertIn("unknown package: nosuchpkg", result.stderr)

    def test_diff_is_quiet_when_everything_resolves(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        result = self.fx.run("diff")
        self.assert_rc(result, 0)
        self.assertIn("no differences", result.stdout)

    def test_real_file_at_target_is_a_conflict_never_clobbered(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        target = self.home / ".gitconfig"
        target.unlink()
        target.write_text("pre-existing\n")
        result = self.fx.run("apply", "gitcfg")
        self.assert_rc(result, 1)
        self.assertIn("CONFLICT", result.stdout)
        self.assertEqual(target.read_text(), "pre-existing\n")
        result = self.fx.run("diff", "gitcfg")
        self.assertIn("-pre-existing", result.stdout)

    def test_relink_repoints_a_stale_symlink(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        target = self.home / ".gitconfig"
        target.unlink()
        target.symlink_to("/etc/hostname")
        result = self.fx.run("apply", "gitcfg")
        self.assert_rc(result, 0)
        self.assertIn("relink", result.stdout)
        self.assertEqual(os.readlink(target), str(self.repo / "config/gitcfg/gitconfig"))

    def test_unlink_removes_only_links_into_the_repo(self) -> None:
        self.assert_rc(self.fx.run("apply"), 0)
        foreign = self.home / ".local/bin/foreign"
        foreign.symlink_to("/etc/hostname")
        self.assert_rc(self.fx.run("unlink"), 0)
        self.assertFalse((self.home / ".config/alpha").exists())
        self.assertFalse((self.home / ".config/beta/beta.conf").exists())
        self.assertFalse((self.home / ".config/one/one.conf").exists())
        self.assertTrue(foreign.is_symlink())


class ValidateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fx = Fixture()
        self.addCleanup(self.fx.cleanup)

    def rewrite_manifest(self, extra: str) -> None:
        (self.fx.repo / "dots.toml").write_text(MANIFEST + extra)

    def test_bad_mode_is_rejected(self) -> None:
        self.rewrite_manifest('[packages.bad]\nmode = "copy"\ntarget = "~/x"\n')
        result = self.fx.run("validate")
        self.assertEqual(result.returncode, 2)
        self.assertIn("mode must be one of", result.stderr)

    def test_target_and_links_are_exclusive(self) -> None:
        self.rewrite_manifest('[packages.bad]\nmode = "link"\ntarget = "~/x"\nlinks = []\n')
        result = self.fx.run("validate")
        self.assertEqual(result.returncode, 2)
        self.assertIn("exactly one of target or links", result.stderr)

    def test_untracked_source_and_missing_doc_are_errors(self) -> None:
        (self.fx.repo / "config/ghost").mkdir()
        (self.fx.repo / "config/ghost/x").write_text("x\n")
        self.rewrite_manifest('[packages.ghost]\nmode = "link"\ntarget = "~/.config/ghost"\n')
        result = self.fx.run("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no tracked files", result.stderr)
        self.assertIn("no docs/ghost.md", result.stderr)

    def test_relative_target_is_an_error(self) -> None:
        self.rewrite_manifest('[packages.rel]\nmode = "link"\nsource = "config/alpha"\ntarget = "config/alpha"\n')
        result = self.fx.run("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("must start with ~/", result.stderr)

    def test_readme_inside_a_package_is_an_error(self) -> None:
        (self.fx.repo / "config/alpha/README.md").write_text("no\n")
        git(self.fx.repo, "add", "-A")
        result = self.fx.run("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("README.md inside a package source", result.stderr)


if __name__ == "__main__":
    unittest.main()
