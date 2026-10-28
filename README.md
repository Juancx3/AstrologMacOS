# Astrolog 8.00 for macOS (Apple Silicon, X11)

This is a fork of Astrolog 8.00 by Walter D. Pullen, adapted to build and run
natively on Apple Silicon Macs, with graphics through XQuartz (X11).

**→ To install and use it on a Mac, see [README-macOS.md](README-macOS.md).**

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
- A sample `astrolog.as` settings file with the Windows-only switches disabled.

All changes to the program are in two source files:

| File          | Change |
|---------------|--------|
| `xscreen.cpp` | Keyboard additions, command box and macro fixes. All code is inside `#ifdef X11`, so the Windows version is not affected. |
| `general.cpp` | Daylight Saving Time autodetect fix, in the Unix code path only. |

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

The macOS changes in this fork were made in October 2026 by
[Juancx3](https://github.com/Juancx3) and are distributed under the same
license. They are unofficial and not endorsed by the original author; please
report problems with this fork here, not to the author of Astrolog.
