#!/bin/bash
#
# install.sh - Install or update Astrolog for macOS (XQuartz version).
#
# Run it in the Terminal with:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/Juancx3/AstrologMacOS/Macos-AppleSilicon-x11/macos/install.sh)
#
# or, from a folder where you already downloaded this repository:
#
#   bash macos/install.sh
#
# It checks what's missing, builds Astrolog, sets up your settings file and
# XQuartz, and creates Astrolog.app. You can run it again at any time to
# update: it never overwrites your astrolog.as or your charts.
#
# Options:
#   --dir FOLDER    Install in FOLDER instead of ~/Astrolog
#   --city "NAME"   Default city for charts, e.g. "Madrid, ES" (skips the question)
#   --yes           Don't ask questions; accept the default answers
#   --no-app        Don't create Astrolog.app
#   --help          Show this help

set -euo pipefail

REPO_URL="https://github.com/Juancx3/AstrologMacOS.git"
BRANCH="Macos-AppleSilicon-x11"
X11_DIR="/opt/X11"
XQUARTZ_APP="/Applications/Utilities/XQuartz.app"

OPT_DIR=""
OPT_CITY=""
OPT_YES=0
OPT_APP=1
NEED_RESTART=0


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

# ask_text "Prompt" "default"  -> prints the answer
ask_text() {
  local ans
  if [ "$OPT_YES" = 1 ] || [ -z "$TTY" ]; then
    printf '%s' "$2"; return
  fi
  if [ -n "$2" ]; then
    printf '    %s [%s]: ' "$1" "$2" > "$TTY"
  else
    printf '    %s: ' "$1" > "$TTY"
  fi
  read -r ans < "$TTY" || ans=""
  printf '%s' "${ans:-$2}"
}

usage() {
  cat <<'EOF'
Usage: bash macos/install.sh [options]

  --dir FOLDER    Install in FOLDER instead of ~/Astrolog
  --city "NAME"   Default city for charts, e.g. "Madrid, ES" (skips the question)
  --yes           Don't ask questions; accept the default answers
  --no-app        Don't create Astrolog.app
  --help          Show this help

Run it again at any time to update. It never overwrites your astrolog.as
or your charts.
EOF
  exit 0
}

# --- City lookup in Astrolog's atlas -----------------------------------------

# Remove accents so "Bogotá" matches "Bogota" in the atlas.
ascii_fold() {
  local r loc
  for loc in en_US.UTF-8 C.UTF-8; do
    if r="$(printf '%s' "$1" | LC_ALL=$loc iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null)" \
       && [[ "$r" != *\?* ]]; then
      printf '%s' "$r" | tr -d "'\"^\`~"
      return
    fi
  done
  printf '%s' "$1"
}

# The Mac's time zone, e.g. America/Toronto.
system_tz() {
  local link
  link="$(readlink /etc/localtime 2>/dev/null || true)"
  printf '%s' "${link#*zoneinfo/}"
}

# atlas_find ATLAS "City[, region]" PREFERRED_TZ
# Prints the best match as: lon<TAB>lat<TAB>region<TAB>name<TAB>zone
# Longitude is positive West, latitude positive North, as in atlas.as.
atlas_find() {
  local atlas="$1" query tz="$3"
  query="$(ascii_fold "$2")"
  awk -F'\t' -v q="$query" -v tz="$tz" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    BEGIN {
      n = split(q, part, ",")
      city = tolower(trim(part[1]))
      reg = (n >= 2) ? toupper(trim(part[n])) : ""
      if (reg == "USA") reg = "US"
      split("AB BC MB NB NL NS NT NU ON PE QC SK YT", ca, " ")
      for (i in ca) isca[ca[i]] = 1
      best = -1
    }
    { sub(/\r$/, "") }
    /^[;@]/ || /^-[A-Za-z]/ || NF < 4 { next }
    {
      if (NF >= 5 && $5 != "") zone = $5
      name = tolower($4)
      if (name == city) s = 30
      else if (index(name, city) == 1) s = 20
      else if (city != "" && index(name, city) > 0) s = 10
      else next
      if (reg != "") {
        r = $3; R = toupper(r)
        lower = (r != R)
        if (R == reg) s += 100
        else if (lower && reg == "CA" && (R in isca)) s += 100
        else if (lower && reg == "US" && !(R in isca)) s += 100
      }
      if (zone == tz) s += 5
      if (s > best) { best = s; line = $1 "\t" $2 "\t" $3 "\t" $4 "\t" zone }
    }
    END { if (best >= 0) print line }
  ' "$atlas"
}

# Standard (winter) offset of a time zone, in Astrolog format, e.g. 5:00W.
std_offset() {
  local tz="$1" e o m best=""
  for e in 1768478400 1784116800; do   # Jan 15 and Jul 15, 2026
    o="$(TZ="$tz" date -r "$e" +%z 2>/dev/null || TZ="$tz" date -d "@$e" +%z)"
    m=$(( ${o:0:1}1 * (10#${o:1:2} * 60 + 10#${o:3:2}) ))
    if [ -z "$best" ] || [ "$m" -lt "$best" ]; then best=$m; fi
  done
  local dir=E
  if [ "$best" -le 0 ]; then dir=W; best=$(( -best )); fi
  printf '%d:%02d%s' $(( best / 60 )) $(( best % 60 )) "$dir"
}

# Decimal degrees to Astrolog's 79W23'55 format. $2 is the letter for positive.
deg_fmt() {
  awk -v v="$1" -v pos="$2" -v neg="$3" 'BEGIN {
    d = (v < 0) ? neg : pos; if (v < 0) v = -v
    t = int(v * 3600 + 0.5)
    printf "%d%s%02d%c%02d", int(t / 3600), d, int((t % 3600) / 60), 39, t % 60
  }'
}

# set_location FILE "lon<TAB>lat<TAB>region<TAB>name<TAB>zone"
set_location() {
  local file="$1" lon lat reg name zone zon place
  IFS=$'\t' read -r lon lat reg name zone <<< "$2"
  zon="$(std_offset "$zone")"
  place="$name, $(printf '%s' "$reg" | tr '[:lower:]' '[:upper:]')"
  local lonf latf
  lonf="$(deg_fmt "$lon" W E)"
  latf="$(deg_fmt "$lat" N S)"
  local tmp="$file.tmp"
  awk -v zon="$zon" -v loc="$lonf $latf" -v place="$place" '
    function pad(s, w) { while (length(s) < w) s = s " "; return s }
    /^-z / { c = substr($0, index($0, ";")); print pad("-z " zon, 24) c; next }
    /^-zl / { c = substr($0, index($0, ";")); print pad("-zl " loc, 24) c; next }
    /^-zv / { c = substr($0, index($0, ";")); print pad("-zv 0ft", 24) c; next }
    /^-zj / { c = substr($0, index($0, ";")); print "-zj \"Current moment now\" \"" place "\" " c; next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
  printf '%s (%s %s, time zone %s, standard offset %s)' "$place" "$latf" "$lonf" "$zone" "$zon"
}

choose_city() {
  local file="$1" atlas="$2" tz default="" q match
  tz="$(system_tz)"
  if [ -n "$tz" ]; then
    default="${tz##*/}"; default="${default//_/ }"
  fi
  if [ -n "$OPT_CITY" ]; then default="$OPT_CITY"; fi

  if [ -z "$TTY" ] || [ "$OPT_YES" = 1 ]; then
    match="$(atlas_find "$atlas" "$default" "$tz")"
    if [ -n "$default" ] && [ -n "$match" ]; then
      ok "Default city: $(set_location "$file" "$match")"
    else
      warn "Couldn't work out your city. Edit -z, -zl and -zj in astrolog.as."
    fi
    return
  fi

  info "Charts for \"now\" use a default city. Type it in English, and add the"
  info "country or state code if the name is common, e.g. \"Madrid, ES\" or \"Paris, FR\"."
  while :; do
    q="$(ask_text "Default city" "$default")"
    if [ -z "$q" ]; then
      warn "No city set. Edit -z, -zl and -zj in astrolog.as later."
      return
    fi
    match="$(atlas_find "$atlas" "$q" "$tz")"
    if [ -z "$match" ]; then
      warn "\"$q\" isn't in Astrolog's atlas (cities over 15,000 people). Try another spelling or a nearby city."
      default=""
      continue
    fi
    local lon lat reg name zone
    IFS=$'\t' read -r lon lat reg name zone <<< "$match"
    if ask_yn "Found $name, $(printf '%s' "$reg" | tr '[:lower:]' '[:upper:]') ($zone). Use it?" Y; then
      ok "Default city: $(set_location "$file" "$match")"
      return
    fi
    info "Add the country or state code to pick another one, e.g. \"$name, ES\"."
    default=""
  done
}

# --- Steps -------------------------------------------------------------------

check_mac() {
  [ "$(uname -s)" = Darwin ] || die "This installer is for macOS."
}

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

check_xquartz() {
  step "XQuartz (graphics window)"
  if [ -f "$X11_DIR/include/X11/Xlib.h" ] && [ -d "$XQUARTZ_APP" ]; then
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

# When astrolog.as was still part of the repository (versions before
# v8.00-mac2), a git pull would delete or block it. Keep the user's copy.
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
    if [ ! -f "$dir/astrolog.as" ]; then
      cp "$backup" "$dir/astrolog.as"
    elif ! cmp -s "$backup" "$dir/astrolog.as"; then
      cp "$backup" "$dir/astrolog.as"
    fi
    ok "Kept your astrolog.as (copy in $(basename "$backup"))"
  fi
}

get_source() {
  step "Astrolog source code"
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || true)"
  if [ -z "$OPT_DIR" ] && [ -f "$here/astrolog.h" ] && [ -f "$here/macos/Makefile" ]; then
    ASTRO_DIR="$here"
    ok "Using $ASTRO_DIR"
    return
  fi
  ASTRO_DIR="${OPT_DIR:-${ASTROLOG_DIR:-$HOME/Astrolog}}"
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
  elif [ -e "$ASTRO_DIR" ]; then
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
}

setup_settings() {
  step "Settings (astrolog.as)"
  local file="$ASTRO_DIR/astrolog.as"
  mkdir -p "$ASTRO_DIR/charts"
  if [ -f "$file" ]; then
    ok "Keeping your astrolog.as"
    # Settings files from Windows stop at the first Windows-only switch.
    if grep -qE '^[-_=:]W' "$file"; then
      warn "It has Windows-only lines (-W, _W, =W), which stop it from loading on a Mac."
      if ask_yn "Comment them out? (a copy of the original is kept)" Y; then
        cp "$file" "$file.windows"
        sed -i '' -E 's/^([-_=:]W)/;\1/' "$file" 2>/dev/null || sed -i -E 's/^([-_=:]W)/;\1/' "$file"
        ok "Done (original saved as astrolog.as.windows)"
      fi
    fi
    return
  fi
  cp "$ASTRO_DIR/macos/astrolog-default.as" "$file"
  ok "Created astrolog.as"
  choose_city "$file" "$ASTRO_DIR/atlas.as"
  info "Put your chart files (.as) in $ASTRO_DIR/charts"
}

setup_xquartz_prefs() {
  step "XQuartz keyboard settings"
  info "Astrolog's Command shortcuts and Option + function key macros need two"
  info "XQuartz settings: no key equivalents, and Option keys sending Alt."
  info "(With this, Command+Q doesn't quit XQuartz; use its menu instead.)"
  if ask_yn "Change them now?" Y; then
    defaults write org.xquartz.X11 enable_key_equivalents -bool false
    defaults write org.xquartz.X11 option_sends_alt -bool true
    ok "Done. They apply the next time XQuartz starts."
    if pgrep -xq X11.bin 2>/dev/null || pgrep -xq Xquartz 2>/dev/null; then
      warn "XQuartz is running now: quit it (XQuartz menu > Quit X11) to apply them."
    fi
  fi
}

setup_function_keys() {
  step "Function keys"
  info "Macros use F1-F12. On a Mac those control brightness and volume unless you"
  info "hold fn, or turn on \"Use F1, F2, etc. keys as standard function keys\" in"
  info "System Settings > Keyboard > Keyboard Shortcuts > Function Keys."
  if ask_yn "Open Keyboard settings now?" N; then
    open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" 2>/dev/null || true
  fi
}

make_app() {
  [ "$OPT_APP" = 1 ] || return 0
  step "Astrolog.app"
  bash "$ASTRO_DIR/macos/make-app.sh" > /dev/null
  ok "Created ~/Applications/Astrolog.app (open it from Spotlight or Launchpad)"
}

finish() {
  step "Finished"
  if [ "$NEED_RESTART" = 1 ]; then
    info "${B}Restart the Mac${N} so XQuartz can start, then open Astrolog from Spotlight"
    info "(Command+Space, type Astrolog)."
  else
    info "Open Astrolog from Spotlight (Command+Space, type Astrolog), or run:"
    info "  cd \"$ASTRO_DIR\" && ./astrolog"
    if [ "$OPT_APP" = 1 ] && ask_yn "Open it now?" Y; then
      open "$HOME/Applications/Astrolog.app"
    fi
  fi
  info "To update later, run this installer again."
  info "Keys and commands: $ASTRO_DIR/README-macOS.md"
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)    OPT_DIR="${2:?--dir needs a folder}"; shift 2 ;;
      --city)   OPT_CITY="${2:?--city needs a name}"; shift 2 ;;
      --yes|-y) OPT_YES=1; shift ;;
      --no-app) OPT_APP=0; shift ;;
      --help|-h) usage ;;
      *) die "Unknown option: $1 (see --help)" ;;
    esac
  done

  printf '%sAstrolog for macOS - installer%s\n' "$B" "$N"
  check_mac
  check_tools
  check_xquartz
  get_source
  build
  setup_settings
  setup_xquartz_prefs
  setup_function_keys
  make_app
  finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
