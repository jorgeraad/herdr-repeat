# herdr-repeat

tmux's `bind -r` and `repeat-time` for [Herdr](https://herdr.dev). Press the prefix and the
entry key once, then keep tapping `h`/`j`/`k`/`l`, `n`/`p`, `M-h`... while each press lands within
the repeat time.

Herdr plugins cannot hold prefix mode open, so the plugin opens a tiny popup that reads keys
until the repeat time runs out. Differences from tmux:

- You enter repeat mode with its own key (for example `prefix+r`), not with the first repeatable key.
- A small popup is visible while repeat mode is active.
- An unbound key ends repeat mode and is typed into the pane, like tmux. Escape just ends it.
- Changing tabs reopens the popup on the new tab, so a key pressed in that ~0.1-0.3 s gap is typed
  into the pane instead.
- `repeat-time` has 100 ms resolution.

## Install

```sh
herdr plugin install jorgeraad/herdr-repeat
# or pinned to a commit
herdr plugin install jorgeraad/herdr-repeat --ref <sha>
```

Bind the entry key in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+r"
type = "plugin_action"
command = "jorgeraad.repeat.start"
description = "repeat mode"
```

Requires Herdr 0.9.1 or newer on Linux or macOS. Only `sh` and coreutils are used.

## Configure

Put overrides in `repeat.conf` inside `herdr plugin config-dir jorgeraad.repeat`. Lines are read
after the defaults below, and later lines win. `bind -r` is repeatable, plain `bind` runs once and
exits, and `unbind` removes a key. Keys are single characters, `Space`, `Escape`, `M-x` and `C-x`.

| tmux | herdr-repeat (defaults) |
|---|---|
| `set -g repeat-time 500` | `set repeat-time 500` |
| `bind -r h select-pane -L` (and `j`, `k`, `l`) | `bind -r h focus left` (`down`, `up`, `right`) |
| `bind -r p previous-window` | `bind -r p tab prev` |
| `bind -r n next-window` | `bind -r n tab next` |
| `bind -r M-h resize-pane -L 5` (and `M-j`, `M-k`, `M-l`) | `bind -r M-h resize left` (Herdr's 5% step) |
| `bind -r '"' split-window -v` | `bind -r '"' split down` |
| `bind -r % split-window -h` | `bind -r % split right` |
| `bind -r '{' swap-pane -U` / `'}' swap-pane -D` | `bind -r { swap up` / `bind -r } swap down` |
| `bind -r Space next-layout` | `bind -r Space action jorgeraad.layouts.next-layout` |

Actions: `focus`, `resize`, `swap` and `split` take `left`/`right`/`up`/`down`, `tab` takes `next`/`prev`,
and `action` runs any Herdr plugin action. `Space` needs
[herdr-layouts](https://github.com/jorgeraad/herdr-layouts); without it, Space just ends repeat mode.
There is no equivalent for tmux's `swap-window` or `rotate-window`.

Example `repeat.conf`:

```
set repeat-time 700
bind -r H resize left
bind x resize right
unbind %
```

## Test

```sh
sh test.sh
```

Security: this plugin runs `repeat.sh` as your user with full access to the Herdr CLI; read it before installing.
