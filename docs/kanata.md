# kanata

[kanata](https://github.com/jtroo/kanata) config. A cross-platform software
keyboard remapper — QMK-style layers, tap-hold, and macros for any keyboard.

Deployed to `~/.config/kanata/` and `~/.config/systemd/user/`.

See the root [README](../README.md) for shared deployment mechanics.

## Why kanata here

This machine runs Wayland (COSMIC), which rules out `xmodmap`, `setxkbmap`, and
every other X11-era remapper. kanata works at the evdev/uinput layer — below the
display server — so it is unaffected by the Wayland switch and remaps every
keyboard, built-in or USB, with one config.

## Files

| File | Role |
|------|------|
| `kanata.kbd` | The remap itself: caps lock as escape/control, plus home row mods. |
| `systemd/user/kanata.service` | Runs `kanata` for the login user, restarting on failure. |

## The mapping

| Key | Tap | Hold |
|-----|-----|------|
| `caps` | escape | left control |
| `a` `s` `d` `f` | themselves | meta, alt, ctrl, shift |
| `j` `k` `l` `;` | themselves | shift, ctrl, alt, meta |

Home row mods are GACS order — meta, alt, ctrl, shift moving inward from each
pinky, which puts shift on the strongest finger. Every other key is untouched.

The home row is **purely time-based**. Release a key in under `hold-time`
(200 ms) and it types its letter; hold it longer and it becomes its modifier.
Nothing else influences the decision, so same-hand combos like `d`+`c` for
ctrl+c behave exactly like cross-hand ones.

`hold-time` and `repress-time` are `defvar`s at the top of the config. Raise
`hold-time` if modifiers fire while typing; lower it if they feel sluggish.
`repress-time` is what keeps held-key repeats working: tap a key, press it again
within the window and keep holding, and the letter repeats instead of the
modifier engaging — `jjjj` in vim rather than shift.

## Panic button

**LCtrl+Space+Escape** triggers kanata's emergency exit and hands the raw
keyboard back. The chord refers to `defsrc` input — the physical keys, before
remapping. It exits 0, so systemd treats it as a clean stop and does not restart
the service.

This is the escape hatch if a config change makes the keyboard unusable. Worth
committing to memory before editing the home row.

`~/.config/kanata/kanata.kbd` is also kanata's own default config path, so a
foreground `kanata` with no arguments picks up the same file the service uses.

## Permissions

kanata reads `/dev/input/event*` and writes `/dev/uinput`. Neither is available
to an ordinary user by default, so this is the one part of the setup that is a
real system change rather than a symlink.

**This is a security trade-off, not a formality.** Membership in the `input`
group lets *anything* running as you read every keystroke on the machine,
password prompts included. The alternative — running kanata as root via a system
unit — moves the same capability to a root process instead. The user-service
route below is the smaller blast radius of the two, but it is not free.

```bash
# Read access to keyboards. Takes effect at the next login, not immediately.
sudo usermod -aG input "$USER"

# Write access to /dev/uinput. Pop!_OS already grants the seat owner an ACL on
# it, but that is a logind detail; this rule makes it explicit and durable.
echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' |
    sudo tee /etc/udev/rules.d/99-kanata.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Log out and back in, then confirm the group took:

```bash
id -nG | tr ' ' '\n' | grep -x input
```

## Activate

```bash
just install kanata      # binary → /usr/local/bin (see tools/README.md)
just apply kanata        # link the config and the unit file
# ...permissions, then log out and back in...
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
```

To remove the symlinks: `cd ~/.dots && just unlink kanata`. Disable the service
first, or systemd keeps running the last-loaded unit until it is stopped.

## Verify

```bash
kanata --cfg ~/.config/kanata/kanata.kbd --check   # config parses
systemctl --user status kanata.service
dots status kanata
```

Then tap caps lock (expect escape), hold it while pressing `c` (expect ctrl+c),
type `asdf` and `sl` at speed (expect the letters, no modifiers), hold `d` while
pressing `c` (expect ctrl+c), and tap-then-hold `j` (expect `jjjj`).

## Editing the config

**Validate before restarting.** A config that fails to parse leaves the keyboard
unmapped; one that parses but is wrong can leave it unusable. Keep a second
keyboard or a TTY (`Ctrl+Alt+F3`) reachable the first few times.

```bash
kanata --cfg ~/.config/kanata/kanata.kbd --check
systemctl --user restart kanata.service
```

If a bad config does lock you out, `systemctl --user stop kanata.service` from a
TTY or over SSH restores the raw keyboard.

The [config guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
is the reference for layers, aliases, and the tap-hold variants.

## Notable choices

- **Plain `tap-hold` for the home row** — purely time-based, and chosen after
  trying the alternative. `tap-hold-opposite-hand` resolves the hold when the
  next key is on the other hand, which sounds better but made ordinary typing
  unusable here: hand alternation is constant in English, so a burst starting on
  a home row key (`sl` typed fast) fired a modifier and swallowed the keystroke.
  Its `(timeout tap)` default also means a bare hold resolves as a *tap* and
  then autorepeats, so a held key never becomes a modifier at all, and same-hand
  combos like `d`+`c` silently type letters instead of ctrl+c.
- **No `require-prior-idle`** — the "was a key pressed in the last N ms?" guard
  suppresses the hold during fast typing. Deliberately omitted to keep the model
  purely time-based: with it, a key held long enough would sometimes still
  refuse to activate. It is the first thing to add if mid-typing misfires become
  the main annoyance; it is supported on all tap-hold variants.
- **`tap-hold-press` for caps** — caps resolves on the next key press rather
  than on elapsed time, making caps+`c` ctrl+c immediately. Caps is not part of
  normal typing, so early resolution costs nothing there.
- **No `f24` workaround** — many home row configs wrap each `tap-hold` in
  `(multi f24 ...)` for a Linux key-repeat bug
  ([discussion #422](https://github.com/jtroo/kanata/discussions/422)): kanata
  emits nothing while deciding tap vs hold, so the desktop never learns a new
  key went down and keeps autorepeating the previous one — `type` comes out
  `typee`. Left out to keep the config simple, since the bug may not show up in
  practice. If doubled letters appear, that is the fix. Note that several
  `f24`-wrapped keys pressed in sequence also need a `(release-key f24)` virtual
  key, which most configs found in the wild are missing:

  ```lisp
  (defvirtualkeys relf24 (release-key f24))
  (defalias
    d (multi f24 (tap-hold $repress-time $hold-time d lctl)
        (macro 5 (on-press tap-vkey relf24))))
  ```

- **`process-unmapped-keys yes`** — required by `tap-hold-press` on caps, which
  can only decide based on the next key if it observes that key.
- **`linux-continue-if-no-devs-found yes`** — kanata exits by default when it
  finds no input devices, and the user service can start before a USB keyboard
  enumerates.
- **`--no-wait` in the unit** — without it kanata stops at a "Press enter to
  exit" prompt on failure rather than exiting, so the process never dies and
  `Restart=on-failure` never fires.
- **Non-`cmd` build** — the release zip ships two binaries; the installer takes
  the one compiled without the `cmd` action, so a config can never execute shell
  commands from a process that sees every keystroke.

## Adapting

Home row mods take one to two weeks of adjustment, and misfires land hardest in
terminals and vim. Tune `hold-time` first — it is the only thing deciding letter
vs modifier.

To back out the home row entirely while keeping caps→escape/control, drop the
home row aliases and cut `defsrc`/`deflayer` down to `caps` alone. Check the file
history for that version:

```bash
cd ~/.dots && git log --oneline -- config/kanata/kanata.kbd
systemctl --user restart kanata.service   # after editing
```

## External dependencies

Not managed by this repo:

- **kanata** — the binary. See [`tools/install-kanata.sh`](../tools/README.md).
- **`input` group membership and the udev rule** — see [Permissions](#permissions).
