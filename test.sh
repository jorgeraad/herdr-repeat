#!/bin/sh
# Drives repeat.sh with scripted keys against a fake herdr that logs its arguments.
set -eu
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/herdr" <<'FAKE'
#!/bin/sh
echo "$*" >> "$LOG"
case "$1 $2" in
  "pane focus") echo '{"focused_pane_id":"w1:p2"}' ;;
  "pane current") echo '{"pane_id":"w1:p9"}' ;;
  "tab list") echo '{"tabs":[{"tab_id":"w1:t1"},{"tab_id":"w1:t2"},{"tab_id":"w1:t3"}]}' ;;
esac
FAKE
chmod +x "$tmp/herdr"
printf '%s\n' 'bind x resize right' 'unbind {' 'bind -r C-o swap up' > "$tmp/repeat.conf"

keys() {
  : > "$tmp/log"
  for k in "$@"; do printf '%b' "$k"; sleep 0.2; done |
    LOG=$tmp/log HERDR_BIN_PATH=$tmp/herdr HERDR_PLUGIN_CONFIG_DIR=$tmp HERDR_PLUGIN_ID=jorgeraad.repeat \
    REPEAT_PANE=w1:p1 REPEAT_TAB=w1:t1 REPEAT_WORKSPACE=w1 sh "$(dirname "$0")/repeat.sh"
  cat "$tmp/log"
}

expect() {
  if [ "$1" = "$2" ]; then echo "ok: $3"; else printf 'FAIL: %s\n--- want\n%s\n--- got\n%s\n' "$3" "$2" "$1"; exit 1; fi
}

expect "$(keys l '\033j' ' ' p l)" "pane focus --direction right --pane w1:p1
pane resize --direction down --pane w1:p2
plugin action invoke jorgeraad.layouts.next-layout
tab list --workspace w1
tab focus w1:t3
pane current
plugin action invoke jorgeraad.repeat.start" "repeatable keys track focus; a tab change reopens the popup on the new tab"

expect "$(keys x l)" "pane resize --direction right --pane w1:p1" "non-repeatable key runs once and exits"

expect "$(keys '\017' { l)" "pane swap --direction up --pane w1:p1
pane send-text w1:p1 {" "user config adds C-o, unbound key passes through and exits"

expect "$(keys '\033' l)" "" "Escape exits without passthrough"
