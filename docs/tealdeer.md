# tealdeer

Config for [tealdeer](https://github.com/tealdeer-rs/tealdeer), a fast Rust
client for [tldr-pages](https://tldr.sh). Deployed to `~/.config/tealdeer/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `.config/tealdeer/config.toml` | Cache auto-update policy. Partial by design — tealdeer merges it over its built-in defaults. |

The binary itself is **not** deployed. Install it with
[`tools/install-tealdeer.sh`](../tools/README.md), which places `tldr` in
`/usr/local/bin` and its bash completion in
`~/.local/share/bash-completion/completions/`.

## Colors

No `[style]` blocks are set. tealdeer's defaults use named colors (`cyan`,
`green`), which resolve through the terminal's ANSI palette, so `tldr` output
inherits carbonfox from whichever terminal is running it — the same indirection
that lets `syntax-theme = base16` in [`git`](git.md) follow the
palette instead of hardcoding one.

Setting hex values here would create a second copy of the palette to keep in
sync with the four terminal configs, for no gain.

## Activate

```bash
just apply tealdeer
```

Seed the page cache once after installing the binary:

```bash
tldr --update
```

Subsequent refreshes are automatic (`auto_update = true`, every 720 hours). To
remove the symlink: `cd ~/.dots && just unlink tealdeer`.

## Verify

```bash
tldr --show-paths   # confirms the config path resolves into this repo
tldr tar            # renders a page
dots status tealdeer
```

## External dependencies

Not managed by this repo:

- **tealdeer** — the `tldr` binary. See
  [`tools/install-tealdeer.sh`](../tools/README.md).
