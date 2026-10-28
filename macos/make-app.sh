#!/bin/bash
#
# make-app.sh - Create Astrolog.app, a launcher you can open from the Dock,
# Launchpad, Spotlight or Finder.
#
# Run it once from the Astrolog folder, after building the program:
#
#     cd ~/Astrolog
#     bash macos/make-app.sh                 # installs in ~/Applications
#     bash macos/make-app.sh /Applications   # or in the main Applications folder
#
# The app opens a Terminal window and runs ./astrolog there, so text output,
# help lists and error messages appear as usual. It runs the program from this
# folder, so rebuilding Astrolog does not require running this script again.
# Run it again only if you move the Astrolog folder.

set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"   # the Astrolog folder
DEST="${1:-$HOME/Applications}"
APP="$DEST/Astrolog.app"

if [ ! -x "$SRC/astrolog" ]; then
  echo "Can't find the compiled program at $SRC/astrolog."
  echo "Build Astrolog first (see README-macOS.md), then run this script again."
  exit 1
fi
if [ ! -f "$SRC/macos/Astrolog.icns" ]; then
  echo "Can't find the icon at $SRC/macos/Astrolog.icns."
  exit 1
fi

VERSION="$(sed -n 's/^#define szVersionCore "\(.*\)".*/\1/p' "$SRC/astrolog.h" 2>/dev/null || true)"
VERSION="${VERSION:-8.00}"

mkdir -p "$DEST"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# --- Icon -------------------------------------------------------------------
cp "$SRC/macos/Astrolog.icns" "$APP/Contents/Resources/Astrolog.icns"

# --- Info.plist -------------------------------------------------------------
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>               <string>Astrolog</string>
  <key>CFBundleDisplayName</key>        <string>Astrolog</string>
  <key>CFBundleIdentifier</key>         <string>io.github.juancx3.astrolog</string>
  <key>CFBundleExecutable</key>         <string>Astrolog</string>
  <key>CFBundleIconFile</key>           <string>Astrolog</string>
  <key>CFBundlePackageType</key>        <string>APPL</string>
  <key>CFBundleShortVersionString</key> <string>$VERSION</string>
  <key>CFBundleVersion</key>            <string>$VERSION</string>
  <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
  <key>NSHumanReadableCopyright</key>   <string>Astrolog (C) 1991-2026 Walter D. Pullen. GPL v2 or later.</string>
</dict>
</plist>
EOF

# --- Script that runs inside Terminal --------------------------------------
QSRC="$(printf '%q' "$SRC")"
cat > "$APP/Contents/Resources/astrolog.command" <<EOF
#!/bin/bash
# Started by Astrolog.app. Runs Astrolog from its folder.
printf '\033]0;Astrolog\007'          # window title
ASTRODIR=$QSRC
cd "\$ASTRODIR" || { echo "Astrolog folder not found: \$ASTRODIR"; echo "Run macos/make-app.sh again from its new location."; read -n 1 -s; exit 1; }

# Make sure the X11 display is reachable. Normally macOS sets DISPLAY and
# starts XQuartz on demand; this is only a fallback.
if [ -z "\${DISPLAY:-}" ]; then
  open -a XQuartz
  for i in \$(seq 1 30); do [ -S /tmp/.X11-unix/X0 ] && break; sleep 0.5; done
  export DISPLAY=:0
fi

./astrolog "\$@"
status=\$?
if [ \$status -ne 0 ]; then
  echo
  echo "Astrolog ended with an error (code \$status). Press any key to close."
  read -n 1 -s
fi
exit 0
EOF
chmod +x "$APP/Contents/Resources/astrolog.command"

# --- The app's own executable: open the script above in Terminal ------------
cat > "$APP/Contents/MacOS/Astrolog" <<'EOF'
#!/bin/bash
HERE="$(cd "$(dirname "$0")/../Resources" && pwd)"
exec open -a Terminal "$HERE/astrolog.command"
EOF
chmod +x "$APP/Contents/MacOS/Astrolog"

# Files downloaded from the web carry a quarantine flag; a locally made app
# doesn't need it. Then nudge Finder to pick up the icon.
xattr -cr "$APP" 2>/dev/null || true
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$APP" 2>/dev/null || true

echo "Created $APP"
echo "Open it from Launchpad or Spotlight (Command+Space, type Astrolog),"
echo "or drag it to the Dock to keep it there."
