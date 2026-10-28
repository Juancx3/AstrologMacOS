# Astrolog 8.00 for macOS (Apple Silicon, X11)

This is a fork of Astrolog 8.00 by Walter D. Pullen, adapted to build and run
natively on Apple Silicon Macs, with graphics through XQuartz (X11).

## Install

Open the Terminal (Applications → Utilities → Terminal), paste this line and
press Return:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Juancx3/AstrologMacOS/Macos-AppleSilicon-x11/macos/install.sh)
```

The installer checks for the two things Astrolog needs (Apple's Command Line
Tools and XQuartz) and helps you install them, then builds Astrolog, asks for
your default city and creates an `Astrolog.app` you can open from Spotlight
or the Dock. Run the same command again to update; it never overwrites your
settings or your charts.

If the installer had to install XQuartz, restart the Mac before opening
Astrolog.

**→ Keyboard reference, useful commands and troubleshooting:
[README-macOS.md](README-macOS.md).**

## What this fork adds

Compared with the official Unix/X11 version of Astrolog 8.00:

- **Function key macros.** F1–F12, alone or with Shift, Ctrl or Option, run
  macros 1–96, using the same key assignments as the Windows version.
- **Keyboard shortcuts with the Command key** for common chart types: transits,
  progressions, aspect list and aspect grid.
- **In-window command line.** Pressing Enter opens a command box inside the
  chart window, with command history, instead of prompting in the terminal.
- **Daylight Saving Time fix.** With `-z0 Autodetect`, charts for the current
  moment were cast one hour off on Unix and macOS whenever the location was
  on Standard Time. This fork corrects that.
- **More robust macros.** Macros that load a chart with `-i` now keep the
  loaded chart, macros that change colors now take effect, and an error inside
  a macro no longer closes the program.
- **Long folder paths no longer crash the program.** Outside Windows, a
  folder path longer than about 45 characters overflowed a buffer at startup.
- **A one-command installer** that builds the program, creates the settings
  file for your city and an app to open it from the Dock.

All changes to the program are in three source files:

| File          | Change |
|---------------|--------|
| `xscreen.cpp` | Keyboard additions, command box and macro fixes. All code is inside `#ifdef X11`, so the Windows version is not affected. |
| `general.cpp` | Daylight Saving Time autodetect fix, in the Unix code path only. |
| `astrolog.h`  | Bounded `snprintf` for `sprintf2` on macOS and Unix, as on Windows. |

The Mac-specific files are in the `macos` folder:

| File | Purpose |
|------|---------|
| `install.sh` | The installer and updater |
| `Makefile` | Builds Astrolog with XQuartz (used by the installer) |
| `astrolog-default.as` | Settings template for the Mac, copied to `astrolog.as` on first install |
| `make-app.sh`, `Astrolog.icns` | Create `Astrolog.app` and its icon |

## About Astrolog

Astrolog is a free, open-source astrology program written by Walter D. Pullen,
available since 1991. The official home page, documentation and downloads are
at <https://www.astrolog.org/astrolog.htm>.

This fork is based on the official copy of Astrolog 8.00 (released May 31,
2026) at <https://github.com/CruiserOne/Astrolog>, which in turn was copied
from <http://www.astrolog.org/ftp/ast80src.zip>. The changes in version 8.00
are described at <http://www.astrolog.org/ftp/updat800.htm>.

## License and credits

Astrolog is Copyright (C) 1991-2026 by Walter D. Pullen and is distributed
under the GNU General Public License, version 2 or later. See
[license.htm](license.htm) for the full license and for the credits of the
components Astrolog includes, such as the Swiss Ephemeris.

## About the editor of this MacOS Version

I’m a geeky engineer working in cybersecurity, but I also have a hobby: astrology. 
(Yes, I know, I’m a bit eccentric!)

I was always been interested in astrology, but the available software was either 
prohibitively expensive or absurdly cumbersome to use.

Since I couldn’t afford to buy an astrology program, I stumbled upon Astrolog by chance. 
Even though I’ve since been able to purchase other professional software, Astrolog remains my favorite.

The thing is, I’ve been using Astrolog for ˜26 years (!!!) always on Windows. I now use a Mac, 
and for the last four years, I’ve been running Astrolog on macOS via Wine. 
However, Apple has decided to phase out the translation layer (Rosetta) that allows 
Intel-based programs to run on macOS. Apple have announced that, starting with MacOS v28, 
Intel-based software will no longer be supported.

This forced me to look for alternatives. I checked out other programs for macOS, but none of them suit me 
or offer the same ease of use. So, I decided to create a fork of Astrolog.

I’m building this primarily for myself, but I felt it was appropriate to share it with Walter 
(whom I greatly admire for his fantastic work). 
As of now, the complete Astrolog engine runs natively on macOS; what I’ve added are keyboard shortcuts 
for the features I use most (transits, progressions and macros) and an in-window command line. 
If the community feels that other MacOS compatible shortcuts should be added to this version 
(and provided Walter gives his approval) I’d be happy to look into it.

The macOS changes in this fork were made in October 2026 by
[Juancx3](https://github.com/Juancx3) and are distributed under the same
license. They are unofficial and not endorsed by the original author; please
report problems with this fork here, not to the author of Astrolog.
