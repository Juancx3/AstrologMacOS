# Astrolog on macOS: installation and use

This guide explains how to build this fork of Astrolog 8.00 on a Mac, run it
with graphics through XQuartz, and use the keyboard features it adds.

It was tested on macOS 26.7 (Tahoe) on Apple Silicon, with XQuartz 2.8.6.
It should also work on Intel Macs, since the build is the same.

## Contents

1. [What you get](#what-you-get)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Running Astrolog](#running-astrolog)
5. [Keyboard reference](#keyboard-reference)
6. [Useful commands](#useful-commands)
7. [Settings file (astrolog.as)](#settings-file-astrologas)
8. [Limitations](#limitations)
9. [Troubleshooting](#troubleshooting)
10. [Updating to a new Astrolog version](#updating-to-a-new-astrolog-version)

## What you get

- A native Apple Silicon program, with no Wine and no Rosetta.
- The full Astrolog calculation engine, with all its charts and command
  switches.
- An interactive graphics window, driven by the keyboard, with animation.
- Text output (chart listings, aspect lists, transit lists) in the Terminal.

What you do **not** get is the Windows interface: there are no menus and no
dialog boxes. Everything is done with keys or command switches. This fork adds
keyboard shortcuts and an in-window command box to make that easier.

## Requirements

| Software | Why | Where |
|----------|-----|-------|
| Command Line Tools for Xcode | C++ compiler and `git` | `xcode-select --install` (full Xcode is not needed) |
| XQuartz | Shows the graphics window (X11) | <https://www.xquartz.org> |

Nothing else is required: no Homebrew, no other libraries.

## Installation

### 1. Install the Command Line Tools

```bash
xcode-select --install
```

Click **Install**, not "Get Xcode". When it finishes, check that it works:

```bash
c++ --version
git --version
```

### 2. Install XQuartz

Download the `.pkg` from <https://www.xquartz.org> and install it. Then
**restart the Mac**, or at least log out and back in. XQuartz needs this to
register its background services. Without it, the graphics window will not
open.

After restarting, check that X11 works:

```bash
/opt/X11/bin/xeyes
```

A pair of eyes that follow the mouse should appear. If they don't, see
[Troubleshooting](#troubleshooting).

### 3. Download the source code

```bash
cd ~
git clone -b Macos-AppleSilicon-x11 https://github.com/Juancx3/AstrologMacOS.git Astrolog
cd Astrolog
```

### 4. Build

```bash
c++ -O2 -I/opt/X11/include -Wno-write-strings -Wno-narrowing -Wno-comment -Wno-deprecated-declarations -c *.cpp
c++ -o astrolog *.o -L/opt/X11/lib -lX11 -lm
```

This takes about a minute. Some warnings may still appear; only lines that
contain `error:` are a problem.

Check that the program is native to Apple Silicon:

```bash
file astrolog
```

It should say `Mach-O 64-bit executable arm64`.

### 5. Adjust XQuartz

Open XQuartz, then go to **XQuartz → Settings → Input** and change two
options:

- **Uncheck** "Enable key equivalents under X11". Otherwise XQuartz keeps the
  Command key shortcuts for itself and they never reach Astrolog. With this
  unchecked, Command+Q no longer quits XQuartz; use its menu instead.
- **Check** "Option keys send Alt_L and Alt_R". This is needed for the
  Option + function key macros.

### 6. Function keys

By default, F1–F12 on a Mac control brightness, volume, etc. Either hold
`fn` while pressing them, or enable **System Settings → Keyboard → Keyboard
Shortcuts → Function Keys → "Use F1, F2, etc. keys as standard function keys"**.

### 7. Optional: run Astrolog from any folder

Add these lines to `~/.zshrc`, then open a new Terminal window:

```bash
export ASTROLOG="$HOME/Astrolog"
export PATH="$HOME/Astrolog:$PATH"
```

`ASTROLOG` tells the program where to find `astrolog.as`, the ephemeris
files and the atlas. Keep the `astrolog` program inside its folder; don't
move it or use a symbolic link to it. Astrolog looks for its `ephem` and
`font` folders relative to its own location.

## Running Astrolog

From the Terminal:

```bash
cd ~/Astrolog
./astrolog            # chart for now, using the settings in astrolog.as
./astrolog -X         # same, forcing the graphics window
./astrolog _X -v      # text-only chart listing in the Terminal
./astrolog -H         # list of all command switches
```

When the graphics window is open, it must have the focus to receive key
presses. Press `?` with the window focused to list all keys; the list appears
in the Terminal. Press `Esc` to close the window and exit.

Keep the Terminal visible next to the window: text output, error messages
and the help lists appear there.

## Keyboard reference

### Added by this fork

| Keys | Action |
|------|--------|
| Enter | Opens a command box at the bottom of the window. Type switches such as `-yt mychart.as` and press Enter. |
| ↑ / ↓ (in the command box) | Go through the last 32 commands. |
| Esc (in the command box) | Close the box without doing anything. |
| Shift + Enter | Ask for the command in the Terminal instead, as the original version does. |
| Command + Shift + N | Natal chart with transits for now. Press again to return to the natal chart only. |
| Command + Shift + P | Natal chart with progressions to now. Press again to return to the natal chart only. |
| Command + L | Aspect list of the current chart, printed in the Terminal. |
| Command + Shift + A | Aspect grid. Press again to return to the wheel. |
| F1 – F12 | Macros 1–12 |
| Shift + F1 – F12 | Macros 13–24 |
| Ctrl + F1 – F12 | Macros 25–36 |
| Option + F1 – F12 | Macros 37–48 |
| Shift + Ctrl + F1 – F12 | Macros 49–60 |
| Shift + Option + F1 – F12 | Macros 61–72 |
| Ctrl + Option + F1 – F12 | Macros 73–84 |
| Shift + Ctrl + Option + F1 – F12 | Macros 85–96 |

If a command in the box has an error, such as a file that doesn't exist, the
box stays open with your text and a message, so you can correct it. Details of
the error appear in the Terminal.

### Built into Astrolog (most used)

| Keys | Action |
|------|--------|
| `?` | List all keys (in the Terminal) |
| `v` | Print the current chart's positions in the Terminal |
| `n` | Set the chart to the current moment |
| `N` | Start or stop continuous animation to the current moment |
| `p` | Pause or resume animation |
| `+` / `-` | Add or subtract one day |
| `!` `@` `#` `$` `%` `^` `&` `*` `(` | Animate by seconds, minutes, hours, days, months, years, decades, centuries or millennia |
| `r` | Reverse the direction of the animation |
| `1` – `9` | Animation speed |
| `V` | Wheel chart |
| `A` | Aspect grid |
| `c` | Toggle relationship comparison chart mode |
| `x` | Swap foreground and background colors |
| `<` / `>` | Make glyphs smaller or larger |
| Space | Redraw |
| Esc | Close the window and exit |

When a transit or progression bi-wheel is shown, the animation keys move only
the outer ring; the natal chart stays fixed.

**Careful with the right mouse button:** a right-click (or two-finger click on
a trackpad) inside the window closes it and exits Astrolog. This is original
Astrolog behavior.

## Useful commands

You can type these in the command box (Enter) or after `./astrolog` in the
Terminal. `mychart.as` stands for one of your chart files. If your settings
file points to a charts folder (for example `-Yi4 "charts"`), the file name
alone is enough.

| Command | Result |
|---------|--------|
| `-i mychart.as` | Open a chart |
| `-yt mychart.as` | Natal chart with transits for now |
| `-yp mychart.as` | Natal chart with progressions to now |
| `-rt mychart.as tty` | Transits for a date you enter in the Terminal |
| `-rp mychart.as tty` | Progressions to a date you enter in the Terminal |
| `-rt mychart.as other.as` | Transits for the date stored in another chart file |
| `-i mychart.as -Tn` | Today's transits ordered by influence (text) |
| `-i mychart.as -tn` | Exact transits this month (text) |
| `-M 41` | Run macro 41 |
| `-qa 3 15 2027 12:00 5 74:05W 4:36N -o date.as` | Save a chart for a date and place to a file |

With `tty`, Astrolog asks for the date, time and city in the Terminal. It
looks the city up in its atlas, so you can type a name like "Toronto".

## Settings file (astrolog.as)

Astrolog reads its default settings from `astrolog.as` in its folder. The one
in this fork is the standard file with the Windows-only switches commented
out, plus a few personal display preferences: Toronto as the default
location, aspect orbs, and the charts folder in `-Yi4`. Edit it to suit you:
mainly your time zone and location (`-z`, `-zl`, `-zj`) and, if you like,
`=X` to always start in graphics mode.

If you bring a settings file from the Windows version, comment out
(prefix with `;`) every line that begins with `-W`, `_W` or `=W`, such as
`-WM`, `-WN` and `=Wh`. The Mac version doesn't know these switches. It stops
at the first one it finds and shows no chart.

Your chart files from Windows work as they are.

For the time zone, use the **standard** offset and let Astrolog detect
Daylight Saving Time. For Toronto that is:

```
-z 5:00W
-z0 Autodetect
```

Don't put the summer offset in `-z` (for example `4:00W`) together with
`-z0 1`: that adds the daylight hour twice.

## Limitations

- **No menus or dialogs.** Everything that the Windows version does with menus
  is done here with keys or command switches.
- **Text output goes to the Terminal.** Listings, aspect lists, transit lists
  and error messages are printed there; the window only shows graphics.
- **No pasting into the command box.** The X11 clipboard is separate from the
  macOS clipboard, so commands must be typed.
- **Some function keys are taken by macOS.** For example, F11 shows the
  desktop, and some Ctrl + function key combinations are used for keyboard
  navigation. Keys that macOS keeps never reach Astrolog; choose other keys
  for those macros, such as Shift + F11.
- **Fixed-size fonts.** The text in the window and in the command box uses
  X11's built-in fonts, which can look small on Retina screens. Glyph size can be changed with `<` and
  `>` or with the `:Xs` and `:XS` settings.
- **No detailed bitmap world maps on screen.** The `w` key, which draws world
  maps in detailed 24-bit color, isn't available in Astrolog's X11 version.
  Charts can still be saved as image files with `-Xo` (for example
  `-XV -Xo chart.svg` for SVG).
- **The `?` help list still describes the original Enter behavior.** Enter now
  opens the command box; Shift + Enter uses the Terminal.

## Troubleshooting

**"Astrolog: Can't open display"**
XQuartz isn't running or isn't reachable. Run `echo $DISPLAY`: it should show
something like `/private/tmp/com.apple.launchd.xxxx/org.xquartz:0`. If it's
empty, restart the Mac. As a temporary fix, open XQuartz and run
`export DISPLAY=:0`.

**XQuartz opens and closes immediately, or `xeyes` says "Can't open display"**
Look at the end of `~/Library/Logs/X11/org.xquartz.log`. If it says
`/tmp/.X11-unix will not be created`, XQuartz's background service hasn't
created its folder.

1. Check **System Settings → General → Login Items & Extensions → Allow in
   the Background**, and make sure XQuartz is enabled. Then restart.
2. If the problem continues, run the XQuartz setup scripts by hand:

   ```bash
   for f in /opt/X11/etc/X11/xinit/privileged_startx.d/*; do sudo sh "$f"; done
   /opt/X11/bin/xeyes
   ```

`launchctl bootstrap` commands that answer `Bootstrap failed: 5` usually mean
the service is already loaded, which is fine.

**Command shortcuts do nothing**
Uncheck "Enable key equivalents under X11" in XQuartz → Settings → Input.
Make sure the Astrolog window, not the Terminal, has the focus.

**Function keys change the volume or brightness instead**
Hold `fn`, or enable standard function keys (see step 6 of the installation).

**macOS says the program can't be opened**
Go to System Settings → Privacy & Security and click **Open Anyway**.

**"Unknown switch '-WM'" when starting**
Your `astrolog.as` comes from Windows. Comment out its Windows-only lines
(see [Settings file](#settings-file-astrologas)).

**Accents in chart names look wrong in the Terminal**
Files saved on Windows use the Windows-1252 character set. Convert one with:
`iconv -f WINDOWS-1252 -t UTF-8 old.as > new.as`

## Updating to a new Astrolog version

When the author releases a new version, bring it into this fork and rebuild:

```bash
cd ~/Astrolog
git remote add upstream https://github.com/CruiserOne/Astrolog.git   # first time only
git fetch upstream
git rebase upstream/master
```

Then build again with the two commands in step 4. If the author changed the
same parts of `xscreen.cpp` or `general.cpp`, git will report a conflict that
has to be resolved by hand.
