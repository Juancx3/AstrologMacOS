#!/bin/bash
#
# make-app.sh - Create Astrolog.app, which opens Astrolog from the Dock,
# Launchpad, Spotlight or Finder. install.sh runs it for you.
#
#   bash macos/make-app.sh [DEST]
#       For a copy built from source: the app runs ./astrolog in this folder,
#       which also holds your astrolog.as and charts. Rebuilding Astrolog
#       doesn't require running this again; moving the folder does.
#
#   bash macos/make-app.sh --standalone [DEST]
#       Self-contained app, as published in the releases: the program and its
#       data files go inside the app, and your settings live in ~/Astrolog.
#
# DEST is the folder where the app is created, ~/Applications by default.
# The app opens a Terminal window (macos/astrolog.command) and runs Astrolog
# there, so text output, help lists and error messages appear as usual.

set -euo pipefail

STANDALONE=0
if [ "${1:-}" = "--standalone" ]; then
  STANDALONE=1
  shift
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)"   # the Astrolog source folder
DEST="${1:-$HOME/Applications}"
APP="$DEST/Astrolog.app"
RES="$APP/Contents/Resources"

LAUNCHER="$SRC/build/AstrologLauncher"
if [ ! -x "$SRC/astrolog" ] || [ ! -x "$LAUNCHER" ]; then
  echo "Can't find the compiled program at $SRC/astrolog, or the app's"
  echo "launcher at $LAUNCHER."
  echo "Build Astrolog first (make -f macos/Makefile), then run this script again."
  exit 1
fi

VERSION="$(sed -n 's/^#define szVersionCore "\(.*\)".*/\1/p' "$SRC/astrolog.h" 2>/dev/null || true)"
VERSION="${VERSION:-8.00}"
BUILD="${ASTROLOG_RELEASE_TAG:-$VERSION}"   # e.g. v8.00-mac3 when built for a release
BUILD="${BUILD#v}"

mkdir -p "$DEST"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$RES"

cp "$SRC/macos/Astrolog.icns" "$RES/Astrolog.icns"
cp "$SRC/macos/astrolog.command" "$RES/astrolog.command"
chmod +x "$RES/astrolog.command"

if [ "$STANDALONE" = 1 ]; then
  # The program and every file it reads at run time. Not astrolog.as: the
  # program looks in its own folder first, and settings must come from the
  # user's settings folder instead.
  mkdir -p "$RES/program"
  cp "$SRC/astrolog" "$RES/program/"
  cp -R "$SRC/ephem" "$SRC/font" "$RES/program/"
  for f in atlas.as timezone.as sefstars.txt seorbel.txt astexo.csv; do
    cp "$SRC/$f" "$RES/program/"
  done
  cp "$SRC/macos/astrolog-default.as" "$RES/program/"
  cp "$SRC/macos/setup.sh" "$RES/setup.sh"
  chmod +x "$RES/setup.sh"
  cp "$SRC/license.htm" "$SRC/README-macOS.md" "$RES/"
  cat > "$RES/SOURCE.txt" <<EOF
Astrolog $BUILD for macOS. Astrolog is Copyright (C) 1991-2026 Walter D. Pullen
and is distributed under the GNU General Public License, version 2 or later
(see license.htm). The source code of this version is available at:
https://github.com/Juancx3/AstrologMacOS
EOF
  echo "MODE=standalone" > "$RES/launcher.conf"
else
  printf 'MODE=source\nSOURCE_DIR=%q\n' "$SRC" > "$RES/launcher.conf"
fi

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
  <key>CFBundleVersion</key>            <string>$BUILD</string>
  <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
  <key>LSMinimumSystemVersion</key>     <string>11.0</string>
  <key>NSHumanReadableCopyright</key>   <string>Astrolog (C) 1991-2026 Walter D. Pullen. GPL v2 or later.</string>
</dict>
</plist>
EOF

# The app's own executable opens astrolog.command in Terminal. It must be a
# compiled program, not a script: macOS runs script-only apps under Rosetta.
cp "$LAUNCHER" "$APP/Contents/MacOS/Astrolog"
chmod +x "$APP/Contents/MacOS/Astrolog"

if [ "$STANDALONE" = 0 ]; then
  # A locally made app doesn't need the quarantine flag. Then nudge Finder
  # to pick up the icon.
  xattr -cr "$APP" 2>/dev/null || true
  touch "$APP"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$APP" 2>/dev/null || true
fi

echo "Created $APP"
