#!/bin/bash
#
# setup.sh - Per-user settings for Astrolog on macOS.
#
# Used by install.sh, and by Astrolog.app the first time it opens, so you
# normally don't run it yourself. It:
#
#   - creates the settings folder (by default ~/Astrolog) with a charts folder,
#   - creates astrolog.as from the Mac template and sets your default city,
#     looked up in Astrolog's atlas; or, if you already have astrolog.as,
#     keeps it and offers to comment out Windows-only switches,
#   - sets the two XQuartz keyboard options this version needs,
#   - offers to open the Keyboard settings for the function keys.
#
# Usage: setup.sh --data FOLDER --files FOLDER [--city "NAME"] [--yes]
#   --data FOLDER   Settings folder, where astrolog.as and charts live
#   --files FOLDER  Folder with atlas.as and astrolog-default.as
#   --city "NAME"   Default city, e.g. "Madrid, ES" (skips the question)
#   --yes           Don't ask questions; accept the default answers

set -euo pipefail

DATA_DIR=""
FILES_DIR=""
OPT_CITY=""
OPT_YES=0

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
  local file="$1" lon lat reg name zone zon place lonf latf
  IFS=$'\t' read -r lon lat reg name zone <<< "$2"
  zon="$(std_offset "$zone")"
  place="$name, $(printf '%s' "$reg" | tr '[:lower:]' '[:upper:]')"
  lonf="$(deg_fmt "$lon" W E)"
  latf="$(deg_fmt "$lat" N S)"
  awk -v zon="$zon" -v loc="$lonf $latf" -v place="$place" '
    function pad(s, w) { while (length(s) < w) s = s " "; return s }
    /^-z / { c = substr($0, index($0, ";")); print pad("-z " zon, 24) c; next }
    /^-zl / { c = substr($0, index($0, ";")); print pad("-zl " loc, 24) c; next }
    /^-zv / { c = substr($0, index($0, ";")); print pad("-zv 0ft", 24) c; next }
    /^-zj / { c = substr($0, index($0, ";")); print "-zj \"Current moment now\" \"" place "\" " c; next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  printf '%s (%s %s, time zone %s, standard offset %s)' "$place" "$latf" "$lonf" "$zone" "$zon"
}

choose_city() {
  local file="$1" atlas="$2" tz default="" q match lon lat reg name zone
  tz="$(system_tz)"
  if [ -n "$tz" ]; then
    default="${tz##*/}"; default="${default//_/ }"
  fi
  if [ -n "$OPT_CITY" ]; then default="$OPT_CITY"; fi

  if [ -z "$TTY" ] || [ "$OPT_YES" = 1 ]; then
    match=""
    [ -n "$default" ] && match="$(atlas_find "$atlas" "$default" "$tz")"
    if [ -n "$match" ]; then
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

setup_settings() {
  step "Settings (astrolog.as)"
  local file="$DATA_DIR/astrolog.as" template
  mkdir -p "$DATA_DIR/charts"
  if [ -f "$file" ]; then
    ok "Keeping your astrolog.as in $DATA_DIR"
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
  template="$FILES_DIR/astrolog-default.as"
  [ -f "$template" ] || template="$FILES_DIR/macos/astrolog-default.as"
  [ -f "$template" ] || die "Can't find astrolog-default.as in $FILES_DIR."
  cp "$template" "$file"
  ok "Created $file"
  choose_city "$file" "$FILES_DIR/atlas.as"
  info "Put your chart files (.as) in $DATA_DIR/charts"
}

setup_xquartz_prefs() {
  step "XQuartz keyboard settings"
  if [ "$(defaults read org.xquartz.X11 enable_key_equivalents 2>/dev/null || true)" = 0 ] \
     && [ "$(defaults read org.xquartz.X11 option_sends_alt 2>/dev/null || true)" = 1 ]; then
    ok "Already set"
    return
  fi
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

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --data)   DATA_DIR="${2:?--data needs a folder}"; shift 2 ;;
      --files)  FILES_DIR="${2:?--files needs a folder}"; shift 2 ;;
      --city)   OPT_CITY="${2:?--city needs a name}"; shift 2 ;;
      --yes|-y) OPT_YES=1; shift ;;
      *) die "Unknown option: $1" ;;
    esac
  done
  [ -n "$DATA_DIR" ] && [ -n "$FILES_DIR" ] || die "Usage: setup.sh --data FOLDER --files FOLDER [--city NAME] [--yes]"
  [ -f "$FILES_DIR/atlas.as" ] || die "Can't find atlas.as in $FILES_DIR."

  setup_settings
  setup_xquartz_prefs
  setup_function_keys
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
