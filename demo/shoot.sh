#!/usr/bin/env bash
set -euo pipefail
demo=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$demo")
out=${1:-$demo}
mkdir -p "$out"
music=$demo/music
export CMUS_HOME=$demo/cmus-home CMUS_SOCKET=$demo/cmus-home/socket PULSE_SINK=tern_demo_null XDG_CACHE_HOME=$demo/cache
magick=$(nix build --no-link --print-out-paths nixpkgs#imagemagick)/bin/magick
mod=$(pactl load-module module-null-sink sink_name=tern_demo_null sink_properties=device.description=tern-demo)
work=$(mktemp -d)
cleanup() {
  [ -n "${KEEP-}" ] && { echo "$run" > "$demo/.run"; return; }
  [ -n "${run-}" ] && TERN_DAEMON_SOCKET=$run/daemon.sock TERN_CONFIG_DIR=$run/cfg tern send @focused text q >/dev/null 2>&1 || true
  sleep 2
  pactl unload-module "$mod" || true
  rm -rf "$work"
}
trap cleanup EXIT
sed_script=$work/tern-script
python3 - "$repo/tern-script" "$sed_script" <<'EOF'
import sys
s = open(sys.argv[1]).read().replace('(cd / && exec', '(cd "$run" && exec')
open(sys.argv[2], 'w').write(s)
EOF
chmod +x "$sed_script"
cp "$repo"/{plugin.toml,bare.css,window.luau} "$work/"
mkdir -p "$CMUS_HOME"
before=$(ls -d /run/user/$(id -u)/tern-script.* 2>/dev/null || true)
TERN_SCRIPT_SETTINGS=${SETTINGS:-'{"font_size":26}'} TERN_SCRIPT_PLUGINS=${OZETTE:-ozette} TERN_SCRIPT_NAME=cmus setsid -f "$sed_script" env CMUS_HOME="$CMUS_HOME" CMUS_SOCKET="$CMUS_SOCKET" PULSE_SINK="$PULSE_SINK" XDG_CACHE_HOME="$XDG_CACHE_HOME" cmus-tsp </dev/null >/dev/null 2>&1
for _ in $(seq 100); do
  run=$(comm -13 <(printf '%s\n' $before) <(ls -d /run/user/$(id -u)/tern-script.* 2>/dev/null) | head -1)
  [ -n "$run" ] && [ -S "$run/control.sock" ] && break
  sleep 0.1
done
export TERN_DAEMON_SOCKET=$run/daemon.sock TERN_CONFIG_DIR=$run/cfg
ctl() { tern ctl --control "$run/control.sock" "$@"; }
sleep 1
ctl resize ${SIZE:-2400 1350} >/dev/null
tern new tab cmus -- sleep 0.2 >/dev/null
sleep 1
tid=$(tern ls | awk '/^  tab 2/{getline; print $1}')
[ -n "$tid" ] && tern close "$tid"
r() { cmus-remote --server "$CMUS_SOCKET" "$@"; }
for _ in $(seq 50); do r -Q >/dev/null 2>&1 && break; sleep 0.2; done
r -C 'set softvol=true'
r -C 'clear -q'
r -v 80%
r -f "$music/Darude/Before the Storm/Sandstorm.opus"
for t in 'Rick Astley/Whenever You Need Somebody/Never Gonna Give You Up' 'Smash Mouth/Astro Lounge/All Star' 'Eiffel 65/Europop/Blue (Da Ba Dee)' 'Toto/Toto IV/Africa' 'Toby Fox/Undertale Soundtrack/Megalovania'; do r -q "$music/$t.opus"; done
sleep 0.5
r -k 72
[ -n "${CSS-}" ] && ctl css ozcmus-dev "$CSS" >/dev/null
shoot() {
  tern send @focused text "$1"
  r -k 72
  sleep 3
  ctl shot "$2" >/dev/null
  "$magick" "$run/target/shots/tern/live/$2.png" -bordercolor '#ecebe7' -border 56 "$out/$2.png"
}
shoot 1 cmus-now-playing
shoot 2 cmus-songs
shoot 4 cmus-albums
