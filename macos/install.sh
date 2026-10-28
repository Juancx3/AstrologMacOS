#!/bin/bash
#
# install.sh - Install or update Astrolog for macOS (XQuartz version).
#
# To install the ready-made app (no compiler needed), run in the Terminal:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/Juancx3/AstrologMacOS/Macos-AppleSilicon-x11/macos/install.sh)
#
# To build it from the source code instead, add --from-source to that
# command, or run "bash macos/install.sh" from a copy of this repository.
#
# Run it again at any time to update: it never overwrites your astrolog.as
# or your charts. Options are listed with --help.

set -euo pipefail

REPO_URL="https://github.com/Juancx3/AstrologMacOS.git"
BRANCH="Macos-AppleSilicon-x11"
RELEASE_URL="${ASTROLOG_RELEASE_URL:-https://github.com/Juancx3/AstrologMacOS/releases/latest/download}"
ZIP_NAME="Astrolog-macOS.zip"
APP_DIR="$HOME/Applications"
X11_DIR="/opt/X11"
XQUARTZ_APP="/Applications/Utilities/XQuartz.app"
PREFS_DOMAIN="io.github.juancx3.astrolog"

OPT_DIR=""
OPT_CITY=""
OPT_YES=0
OPT_APP=1
FROM_SOURCE=0
NEED_RESTART=0
DOWNLOAD_TMP=""

# --- Output and questions ----------------------------------------------------

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; N=""
fi
step() { printf '\n%s==> %s%s\n' "$B" "$1" "$N"; }
ok()   { printf '    %s✓%s %s\n' "$G" "$N" "$1"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '    %s!%s %s\n' "$Y" "$N" "$1"; }
die()  { printf '\n%sError:%s %s\n' "$R" "$N" "$1" >&2; exit 1; }

# Questions read from the keyboard even when the script itself comes from
# curl through a pipe.
TTY=/dev/tty
if ! { : < /dev/tty; } 2>/dev/null; then
  TTY=""
fi

# ask_yn "Question" Y|N  -> returns 0 for yes
ask_yn() {
  local def="$2" ans hint="[y/N]"
  [ "$def" = Y ] && hint="[Y/n]"
  if [ "$OPT_YES" = 1 ] || [ -z "$TTY" ]; then
    [ "$def" = Y ]; return
  fi
  printf '    %s %s ' "$1" "$hint"
  read -r ans < "$TTY" || ans=""
  ans="${ans:-$def}"
  case "$ans" in [Yy]*|[Ss]*) return 0 ;; *) return 1 ;; esac
}

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Installs the ready-made Astrolog.app in ~/Applications, with your settings in
~/Astrolog. Run it again at any time to update; it never overwrites your
astrolog.as or your charts.

  --from-source   Build Astrolog from the source code instead (needs Apple's
                  Command Line Tools). The default when you run it from a copy
                  of the repository.
  --dir FOLDER    Settings folder (or, with --from-source, the source folder)
                  instead of ~/Astrolog
  --city "NAME"   Default city for charts, e.g. "Madrid, ES" (skips the question)
  --yes           Don't ask questions; accept the default answers
  --no-app        With --from-source: don't create Astrolog.app
  --help          Show this help
EOF
  exit 0
}

# --- Common steps ------------------------------------------------------------

check_mac() {
  [ "$(uname -s)" = Darwin ] || die "This installer is for macOS."
}

check_xquartz() {
  step "XQuartz (graphics window)"
  local have=0
  if [ -d "$XQUARTZ_APP" ] && [ -f "$X11_DIR/lib/libX11.6.dylib" ]; then
    have=1
  fi
  if [ "$FROM_SOURCE" = 1 ] && [ ! -f "$X11_DIR/include/X11/Xlib.h" ]; then
    have=0
  fi
  if [ "$have" = 1 ]; then
    ok "Installed"
    if [ -z "${DISPLAY:-}" ]; then
      NEED_RESTART=1
      warn "It isn't active yet. You'll need to restart the Mac (or log out and in)."
    fi
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    if ask_yn "XQuartz is missing. Install it now with Homebrew? (asks for your password)" Y; then
      brew install --cask xquartz
      NEED_RESTART=1
      ok "Installed"
      return
    fi
  fi
  info "XQuartz is missing. Opening its download page:"
  info "  https://www.xquartz.org"
  info "Install the .pkg, restart the Mac, and run this installer again."
  open "https://www.xquartz.org" 2>/dev/null || true
  exit 0
}

run_setup() {
  local args=(--data "$DATA_DIR" --files "$FILES_DIR")
  [ -n "$OPT_CITY" ] && args+=(--city "$OPT_CITY")
  [ "$OPT_YES" = 1 ] && args+=(--yes)
  bash "$SETUP" "${args[@]}"
}

finish() {
  step "Finished"
  if [ "$NEED_RESTART" = 1 ]; then
    info "${B}Restart the Mac${N} so XQuartz can start, then open Astrolog from Spotlight"
    info "(Command+Space, type Astrolog)."
  elif [ "$OPT_APP" = 1 ]; then
    info "Open Astrolog from Spotlight (Command+Space, type Astrolog) or Launchpad."
    if ask_yn "Open it now?" Y; then
      open "$APP_DIR/Astrolog.app"
    fi
  else
    info "Run it with: cd \"$DATA_DIR\" && ./astrolog"
  fi
  info "Your settings and charts: $DATA_DIR"
  info "To update later, run this installer again."
}

# --- Ready-made app ----------------------------------------------------------

download_app() {
  step "Downloading Astrolog"
  local tmp expected actual app="$APP_DIR/Astrolog.app" version
  tmp="$(mktemp -d)"
  DOWNLOAD_TMP="$tmp"
  trap 'rm -rf "$DOWNLOAD_TMP"' EXIT
  curl -fL --progress-bar -o "$tmp/$ZIP_NAME" "$RELEASE_URL/$ZIP_NAME" \
    || die "Couldn't download $RELEASE_URL/$ZIP_NAME. Check your internet connection and try again."
  curl -fsSL -o "$tmp/$ZIP_NAME.sha256" "$RELEASE_URL/$ZIP_NAME.sha256" \
    || die "Couldn't download the checksum file to verify the download."
  expected="$(awk '{print $1}' "$tmp/$ZIP_NAME.sha256")"
  actual="$(shasum -a 256 "$tmp/$ZIP_NAME" | awk '{print $1}')"
  [ -n "$expected" ] && [ "$expected" = "$actual" ] \
    || die "The download is damaged or incomplete (checksum doesn't match). Please try again."
  ok "Downloaded and verified"

  mkdir -p "$tmp/x"
  ditto -x -k "$tmp/$ZIP_NAME" "$tmp/x"
  [ -x "$tmp/x/Astrolog.app/Contents/Resources/program/astrolog" ] \
    || die "The download doesn't contain Astrolog.app as expected."
  mkdir -p "$APP_DIR"
  rm -rf "$app"
  mv "$tmp/x/Astrolog.app" "$app"
  touch "$app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$app" 2>/dev/null || true
  version="$(sed -n '/CFBundleVersion/{s/.*<string>\(.*\)<\/string>.*/\1/p;}' "$app/Contents/Info.plist")"
  ok "Installed $app (version $version)"

  DATA_DIR="${OPT_DIR:-$HOME/Astrolog}"
  FILES_DIR="$app/Contents/Resources/program"
  SETUP="$app/Contents/Resources/setup.sh"
  # Tell the app where the settings folder is.
  if [ "$DATA_DIR" = "$HOME/Astrolog" ]; then
    defaults delete "$PREFS_DOMAIN" DataFolder 2>/dev/null || true
  else
    defaults write "$PREFS_DOMAIN" DataFolder "$DATA_DIR"
  fi
}

# --- Building from source ----------------------------------------------------

check_tools() {
  step "Command Line Tools (compiler and git)"
  if xcode-select -p >/dev/null 2>&1 && command -v c++ >/dev/null && command -v git >/dev/null; then
    ok "Installed"
    return
  fi
  info "They're missing. A macOS window will ask to install them: click Install"
  info "(not \"Get Xcode\"). This can take several minutes."
  xcode-select --install >/dev/null 2>&1 || true
  info "Waiting for the installation to finish..."
  for _ in $(seq 1 360); do
    if xcode-select -p >/dev/null 2>&1 && command -v c++ >/dev/null 2>&1; then
      ok "Installed"
      return
    fi
    sleep 5
  done
  die "The Command Line Tools still aren't installed. Install them, then run this installer again."
}

# When astrolog.as was still part of the repository (v8.00-mac1), a git pull
# would delete or block it. Keep the user's copy.
safe_pull() {
  local dir="$1" backup=""
  if git -C "$dir" ls-files --error-unmatch astrolog.as >/dev/null 2>&1 && [ -f "$dir/astrolog.as" ]; then
    backup="$dir/astrolog.as.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$dir/astrolog.as" "$backup"
    git -C "$dir" checkout -- astrolog.as
  fi
  if git -C "$dir" pull --ff-only --quiet; then
    ok "Updated to the latest version"
  else
    warn "Couldn't update (local changes?). Continuing with the version you have."
  fi
  if [ -n "$backup" ]; then
    if [ ! -f "$dir/astrolog.as" ] || ! cmp -s "$backup" "$dir/astrolog.as"; then
      cp "$backup" "$dir/astrolog.as"
    fi
    ok "Kept your astrolog.as (copy in $(basename "$backup"))"
  fi
}

get_source() {
  step "Astrolog source code"
  if [ -n "$CHECKOUT" ] && [ -z "$OPT_DIR" ]; then
    ASTRO_DIR="$CHECKOUT"
    ok "Using $ASTRO_DIR"
    return
  fi
  ASTRO_DIR="${OPT_DIR:-$HOME/Astrolog}"
  if [ -d "$ASTRO_DIR/.git" ]; then
    local url
    url="$(git -C "$ASTRO_DIR" remote get-url origin 2>/dev/null || true)"
    if [ ! -d "$ASTRO_DIR/macos" ] && [[ "$url" != *AstrologMacOS* ]]; then
      die "$ASTRO_DIR is a copy of the original Astrolog, not of this macOS version. Rename it (for example to Astrolog-old) and run the installer again, or use --dir."
    fi
    ok "Found $ASTRO_DIR"
    if ask_yn "Download the latest version?" Y; then
      safe_pull "$ASTRO_DIR"
    fi
    [ -f "$ASTRO_DIR/macos/Makefile" ] \
      || die "$ASTRO_DIR doesn't have the files this installer needs. Update it with git, or rename it and run the installer again."
  elif [ -f "$ASTRO_DIR/astrolog.as" ] && [ ! -f "$ASTRO_DIR/astrolog.h" ]; then
    die "$ASTRO_DIR is the settings folder of the ready-made app. To build from source, choose another folder with --dir."
  elif [ -e "$ASTRO_DIR" ] && [ -n "$(ls -A "$ASTRO_DIR" 2>/dev/null)" ]; then
    die "$ASTRO_DIR already exists and isn't a copy of this repository. Move it away or use --dir."
  else
    git clone --quiet --branch "$BRANCH" "$REPO_URL" "$ASTRO_DIR"
    ok "Downloaded to $ASTRO_DIR"
  fi
}

build() {
  step "Building (about a minute)"
  local log="$ASTRO_DIR/build/build.log" jobs
  mkdir -p "$ASTRO_DIR/build"
  jobs="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
  if ! make -C "$ASTRO_DIR" -f macos/Makefile -j"$jobs" > "$log" 2>&1; then
    printf '\n'
    if grep -qE "error:" "$log"; then
      grep -E "error:" "$log" | head -15 >&2
    else
      tail -15 "$log" >&2
    fi
    die "The build failed. The full log is in $log"
  fi
  ok "Built $(file -b "$ASTRO_DIR/astrolog" | sed 's/^Mach-O //')"
  DATA_DIR="$ASTRO_DIR"
  FILES_DIR="$ASTRO_DIR"
  SETUP="$ASTRO_DIR/macos/setup.sh"
}

make_app() {
  [ "$OPT_APP" = 1 ] || return 0
  step "Astrolog.app"
  bash "$ASTRO_DIR/macos/make-app.sh" "$APP_DIR" > /dev/null
  ok "Created $APP_DIR/Astrolog.app, which runs your build in $ASTRO_DIR"
}

# --- Main --------------------------------------------------------------------

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --from-source) FROM_SOURCE=1; shift ;;
      --dir)    OPT_DIR="${2:?--dir needs a folder}"; shift 2 ;;
      --city)   OPT_CITY="${2:?--city needs a name}"; shift 2 ;;
      --yes|-y) OPT_YES=1; shift ;;
      --no-app) OPT_APP=0; shift ;;
      --help|-h) usage ;;
      *) die "Unknown option: $1 (see --help)" ;;
    esac
  done

  # Run from a copy of the repository: build that copy.
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || true)"
  CHECKOUT=""
  if [ -f "$here/astrolog.h" ] && [ -f "$here/macos/Makefile" ]; then
    CHECKOUT="$here"
    FROM_SOURCE=1
  fi

  check_mac
  if [ "$FROM_SOURCE" = 1 ]; then
    printf '%sAstrolog for macOS - build from source%s\n' "$B" "$N"
    check_tools
    check_xquartz
    get_source
    build
    run_setup
    make_app
  else
    printf '%sAstrolog for macOS - installer%s\n' "$B" "$N"
    OPT_APP=1
    check_xquartz
    download_app
    run_setup
  fi
  finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
