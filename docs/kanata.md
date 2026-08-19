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
| `kanata.kbd` | The remap itself. |
| `systemd/user/kanata.service` | Runs `kanata` for the login user, restarting on failure. |

## The mapping

| Key | Tap | Hold |
|-----|-----|------|
| `caps` | escape | — |
| `esc` | caps lock | — |
| `;` | `;` | activates the mods layer |
| `s` `d` `f` | themselves | ctrl, alt, super — **only while `;` is held** |

Four remapped keys, and only `;` has any timing behaviour. caps and escape are a
straight swap. On the base layer `s`, `d`, and `f` are ordinary letters that emit
the instant they are pressed.

Since `;` is held by the right pinky and the modifiers are left-hand, every chord
is cross-hand: `;`+`s`+`c` is ctrl+c.

`hold-time` and `repress-time` are `defvar`s at the top of the config, and now
apply to `;` alone. Lower `hold-time` for a snappier layer; raise it if `;` turns
into a layer while typing — worth watching in code, where `;` is far more common
than in prose. `repress-time` is why tapping `;` and immediately pressing it
again repeats the semicolon instead of engaging the layer.

## Why a layer instead of home row mods

Home row mods were built first — `a`/`s`/`d`/`f` and `j`/`k`/`l`/`;` each a
tap-hold — and backed out. Two findings worth keeping:

**Timing-based tap-hold has unavoidable input lag.** A tap-hold key cannot emit
its letter on press, because it does not yet know whether the key is a letter or
a modifier. The letter lands on *release*, and anything typed meanwhile queues
behind it to preserve order. Fast typing overlaps keystrokes, so the queue fills
and flushes in bursts — typing feels rubber-banded, worst in words with several
home row letters in a row. This is inherent to home row mods; QMK and ZMK share
it. Putting the modifiers on a layer removes the ambiguity entirely rather than
tuning around it.

**`tap-hold-opposite-hand` is not the fix it appears to be.** It resolves the
hold when the next key is on the other hand, which sounds ideal but made typing
unusable here: hand alternation is constant in English, so a burst starting on a
home row key (`sl` typed fast) fired a modifier and swallowed the keystroke. Its
`(timeout tap)` default also means a bare hold resolves as a *tap* and then
autorepeats, so a held key never becomes a modifier at all, and same-hand combos
silently type letters.

Mirrored modifiers on `j`/`k`/`l` were also tried on the layer and removed: they
never took effect, in either right-side (`rctl`/`rmet`/`ralt`) or left-side
form. Debug logging confirmed the layer *was* active and kanata *was* emitting
the modifier, so the cause is downstream of kanata. Not chased further. If it
comes up again, the decisive test is watching output keycodes with `evtest` on
kanata's virtual device while holding `;`+`j`.

## Panic button

**LCtrl+Space+Escape** triggers kanata's emergency exit and hands the raw
keyboard back. The chord refers to `defsrc` input — the physical keys, before
remapping. It exits 0, so systemd treats it as a clean stop and does not restart
the service.

This is the escape hatch if a config change makes the keyboard unusable.

`~/.config/kanata/kanata.kbd` is also kanata's own default config path, so a
foreground `kanata` with no arguments picks up the same file the service uses.

## Which devices get grabbed

Left alone, kanata claims every device exposing a `kbd` handler — which on this
machine included a monitor (`DP-2`), the laptop's extra buttons, the Keychron's
media-key endpoints, and a Logitech G Pro Wireless *mouse*, whose receiver
presents a keyboard interface alongside `mouse3`.

`linux-dev-names-include` in the config allowlists the laptop's internal
keyboard and nothing else. External keyboards and everything mouse-shaped pass
through to the kernel untouched. This replaced an exclude list of known
non-keyboards: an allowlist can't be surprised by a new device.

The internal keyboard is two devices: typing actually arrives on
`ITE Tech. Inc. ITE Device(8258) Keyboard` (the keyboard is wired through the
ITE embedded controller — confirmed by capturing evdev events while typing),
while `AT Translated Set 2 keyboard` is the legacy PS/2 endpoint, mostly idle
but included in case some keys still route through it.

Names must match **in full** — no partial matches, no regex, and trailing
spaces count. Get them from the startup log:

```bash
journalctl --user -u kanata.service | grep registering
```

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

The service starts at login, not at boot, so caps and escape are unswapped at
the display manager's password prompt. `sudo loginctl enable-linger "$USER"`
changes that if it matters.

## Verify

`just check` parses the config with `kanata --check` whenever kanata is
installed, and `just doctor` reports whether the service is running and the
`input` group took. Neither is escalated by `REQUIRE_LINTERS`, since CI runs on
a machine with no reason to install kanata.

By hand:

```bash
kanata --cfg ~/.config/kanata/kanata.kbd --check   # config parses
systemctl --user status kanata.service
dots status kanata
```

Then tap caps (expect escape), type `sdf` at speed (expect the letters), and
hold `;` while tapping `c` with `s` held (expect ctrl+c).

## Editing the config

**Validate before restarting.** A config that fails to parse leaves the keyboard
unmapped; one that parses but is wrong can leave it unusable. Keep a second
keyboard or a TTY (`Ctrl+Alt+F3`) reachable the first few times.

```bash
kanata --cfg ~/.config/kanata/kanata.kbd --check
systemctl --user restart kanata.service
```

If a bad config does lock you out, use the panic button above, or
`systemctl --user stop kanata.service` from a TTY or over SSH.

To debug behaviour rather than syntax, stop the service and run kanata directly
with `-d --log-layer-changes`; it logs every layer entry and the keycodes it
emits, which distinguishes "kanata is not sending it" from "something ignores
it":

```bash
systemctl --user stop kanata.service
kanata -d --no-wait --log-layer-changes --cfg ~/.config/kanata/kanata.kbd
```

The [config guide](https://github.com/jtroo/kanata/blob/main/docs/config.adoc)
is the reference for layers, aliases, and the tap-hold variants.

## Notable choices

- **`process-unmapped-keys yes`** — keeps output ordered while `;` is still
  deciding tap vs hold. Nothing strictly requires it at the current layer count;
  it was mandatory when an `unshift`-based arrow layer existed, since shift is
  not in `defsrc` and its state has to be tracked.
- **`linux-continue-if-no-devs-found yes`** — kanata exits by default when it
  finds no input devices, and the user service can start before a USB keyboard
  enumerates.
- **`--no-wait` in the unit** — without it kanata stops at a "Press enter to
  exit" prompt on failure rather than exiting, so the process never dies and
  `Restart=on-failure` never fires.
- **Non-`cmd` build** — the release zip ships two binaries; the installer takes
  the one compiled without the `cmd` action, so a config can never execute shell
  commands from a process that sees every keystroke.
- **No `f24` workaround** — many tap-hold configs wrap each action in
  `(multi f24 ...)` for a Linux key-repeat bug
  ([discussion #422](https://github.com/jtroo/kanata/discussions/422)): kanata
  emits nothing while deciding tap vs hold, so the desktop never learns a new
  key went down and keeps autorepeating the previous one — `type` comes out
  `typee`. With only `;` doing tap-hold this is unlikely to bite. If doubled
  letters appear, that is the fix; note that several `f24`-wrapped keys pressed
  in sequence also need a `(release-key f24)` virtual key, which most configs
  found in the wild are missing.

## External dependencies

Not managed by this repo:

- **kanata** — the binary. See [`tools/install-kanata.sh`](../tools/README.md).
- **`input` group membership and the udev rule** — see [Permissions](#permissions).
