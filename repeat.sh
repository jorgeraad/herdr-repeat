#!/bin/sh
herdr=${HERDR_BIN_PATH:-herdr}

if [ "${1-}" = start ]; then
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    "$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint repeat --env REPEAT_PANE="$HERDR_PANE_ID" \
      --env REPEAT_TAB="$HERDR_TAB_ID" --env REPEAT_WORKSPACE="$HERDR_WORKSPACE_ID" >/dev/null 2>&1 && exit
    sleep 0.05
  done
  exit 1
fi
pane=$REPEAT_PANE tab=$REPEAT_TAB workspace=$REPEAT_WORKSPACE

config() {
  cat <<'CONF'
set repeat-time 500
bind -r h focus left
bind -r j focus down
bind -r k focus up
bind -r l focus right
bind -r p tab prev
bind -r n tab next
bind -r M-h resize left
bind -r M-j resize down
bind -r M-k resize up
bind -r M-l resize right
bind -r '"' split down
bind -r % split right
bind -r { swap up
bind -r } swap down
bind -r Space action jorgeraad.layouts.next-layout
CONF
  cat "$HERDR_PLUGIN_CONFIG_DIR/repeat.conf" 2>/dev/null
}

lookup() {
  config | awk -v k="$1" '
    { gsub(/^'\''|'\''$/, "", $3); gsub(/^'\''|'\''$/, "", $2) }
    $1 == "set" && $2 == k { v = $3 }
    $1 == "unbind" && $2 == k { v = "" }
    $1 == "bind" {
      r = $2 == "-r"; if ($(2 + r) != k) next
      $1 = ""; $2 = ""; if (r) $3 = ""
      v = (r ? "-r " : "") substr($0, 3 + r)
    }
    END { print v }'
}

keyname() {
  printf %s "$1" | od -An -tu1 | awk '{
    if (NF == 1 && $1 == 27) print "Escape"
    else if (NF == 1 && $1 == 32) print "Space"
    else if (NF == 1 && $1 > 0 && $1 < 27) printf "C-%c\n", $1 + 96
    else if (NF == 1 && $1 > 32 && $1 < 127) printf "%c\n", $1
    else if (NF == 2 && $1 == 27 && $2 > 32 && $2 < 127) printf "M-%c\n", $2
  }'
}

field() { sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"; }

next_tab() {
  case $1 in next) step=1 ;; prev) step=-1 ;; *) return 1 ;; esac
  "$herdr" tab list --workspace "$workspace" | grep -o '"tab_id":"[^"]*"' | cut -d'"' -f4 |
    awk -v cur="$tab" -v step="$step" '{ t[NR] = $0; if ($0 == cur) i = NR } END { if (i) print t[(i + step + NR - 1) % NR + 1] }'
}

run() {
  set -- $1
  case $1 in
    focus) pane=$("$herdr" pane focus --direction "$2" --pane "$pane" | field focused_pane_id) ;;
    resize) "$herdr" pane resize --direction "$2" --pane "$pane" >/dev/null ;;
    swap) "$herdr" pane swap --direction "$2" --pane "$pane" >/dev/null ;;
    split) pane=$("$herdr" pane split --pane "$pane" --direction "$2" --focus | field pane_id) ;;
    tab) tab=$(next_tab "$2") && [ -n "$tab" ] && "$herdr" tab focus "$tab" >/dev/null &&
      pane=$("$herdr" pane current | field pane_id) ;;
    action) "$herdr" plugin action invoke "$2" >/dev/null ;;
    *) false ;;
  esac && [ -n "$pane" ]
}

ms=$(lookup repeat-time)
stty -icanon -echo -icrnl min 0 time $(( (ms + 99) / 100 )) 2>/dev/null
while raw=$(dd bs=8 count=1 2>/dev/null; echo .) && raw=${raw%.} && [ -n "$raw" ]; do
  key=$(keyname "$raw")
  binding=$(lookup "$key")
  case $binding in
    -r\ *) run "${binding#-r }" || break
      [ "$tab" = "$REPEAT_TAB" ] || { "$herdr" plugin action invoke "$HERDR_PLUGIN_ID.start" >/dev/null; break; } ;;
    ?*) run "$binding"; break ;;
    *) [ "$key" = Escape ] || "$herdr" pane send-text "$pane" "$raw" >/dev/null; break ;;
  esac
done
