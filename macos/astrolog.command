#!/bin/bash
#
# astrolog.command - Runs Astrolog in a Terminal window. Astrolog.app opens
# this script in Terminal, so text output, help lists and error messages have
# a place to appear. macos/make-app.sh copies it into the app, next to
# launcher.conf, which says where the program and your settings are:
#
#   MODE=standalone   The program and its data files are inside the app, in
#                     Contents/Resources/program. Your settings (astrolog.as)
#                     and charts are in your settings folder: ~/Astrolog, or
#                     the folder chosen with install.sh --dir.
#   MODE=source       The app runs ./astrolog in the source folder SOURCE_DIR,
#                     which also holds astrolog.as and charts.
#
# Arguments are passed on to Astrolog.

HERE="$(cd "$(dirname "$0")" && pwd)"
printf '\033]0;Astrolog\007'

pause() {
  echo
  echo "Press any key to close this window."
  read -r -n 1 -s
}

MODE=standalone
SOURCE_DIR=""
# shellcheck source=/dev/null
[ -f "$HERE/launcher.conf" ] && . "$HERE/launcher.conf"

EXTRA=()
if [ "$MODE" = source ]; then
  PROG="$SOURCE_DIR"
  DATA="$SOURCE_DIR"
  SETUP="$SOURCE_DIR/macos/setup.sh"
  if [ ! -x "$PROG/astrolog" ]; then
    echo "Can't find Astrolog in $SOURCE_DIR."
    echo "If you moved that folder, run 'bash macos/install.sh' from its new location."
    pause; exit 1
  fi
else
  PROG="$HERE/program"
  DATA="$(defaults read io.github.juancx3.astrolog DataFolder 2>/dev/null || true)"
  DATA="${DATA:-$HOME/Astrolog}"
  SETUP="$HERE/setup.sh"
  # The program is inside the app, so relative chart folders in astrolog.as
  # (such as -Yi4 "charts") point inside the app too. This adds the charts
  # folder in your settings folder.
  EXTRA=(-Yi9 "$DATA/charts")
fi

if [ ! -f /opt/X11/lib/libX11.6.dylib ]; then
  echo "Astrolog needs XQuartz to show its window, and XQuartz isn't installed."
  echo "Opening https://www.xquartz.org: install it, restart the Mac, and open"
  echo "Astrolog again."
  open "https://www.xquartz.org"
  pause; exit 1
fi

if [ ! -f "$DATA/astrolog.as" ]; then
  echo "Welcome to Astrolog. First, a few settings; this happens only once."
  if ! bash "$SETUP" --data "$DATA" --files "$PROG"; then
    pause; exit 1
  fi
  echo
fi

cd "$DATA" || { echo "Can't open the settings folder $DATA."; pause; exit 1; }

# Normally macOS sets DISPLAY and starts XQuartz on demand; this is only a
# fallback.
if [ -z "${DISPLAY:-}" ]; then
  open -a XQuartz
  for _ in $(seq 1 30); do [ -S /tmp/.X11-unix/X0 ] && break; sleep 0.5; done
  export DISPLAY=:0
fi

"$PROG/astrolog" "${EXTRA[@]}" "$@"
status=$?
if [ $status -ne 0 ]; then
  echo
  echo "Astrolog ended with an error (code $status)."
  pause
fi
exit 0
