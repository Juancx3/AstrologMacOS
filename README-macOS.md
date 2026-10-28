# Astrolog on macOS: installation and use

This guide explains how to install this fork of Astrolog 8.00 on a Mac, run
it with graphics through XQuartz, and use the keyboard features it adds.

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
10. [Uninstalling](#uninstalling)
11. [For maintainers](#for-maintainers)

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

- A Mac with Apple Silicon (tested on macOS 26.7 Tahoe). Intel Macs should
  also work.
- **XQuartz**, which shows Astrolog's graphics window. You don't need to
  install it beforehand: the installer checks for it and helps you install it.

There are two ways to install Astrolog:

- **The ready-made app** (recommended). Nothing to compile. This is what
  most people want.
- **Building from the source code**, for those who want to read or change the
  code. This also needs Apple's Command Line Tools (the C++ compiler and
  `git`), which take several gigabytes of disk space.

## Installation

Open the Terminal (Applications → Utilities → Terminal), paste this line and
press Return:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Juancx3/AstrologMacOS/Macos-AppleSilicon-x11/macos/install.sh)
```

The installer explains each step and asks before changing any setting. It:

1. Checks for XQuartz. If it's missing, it installs it with Homebrew when you
   have Homebrew, or opens the XQuartz download page. In that case, install
   it, **restart the Mac**, and run the installer again.
2. Downloads `Astrolog.app` from the latest release, checks that the download
   is complete and unaltered (SHA-256 checksum), and installs it in the
   Applications folder of your user (`~/Applications`).
3. Creates your settings folder, `~/Astrolog`, with your settings file,
   `astrolog.as`, and a `charts` folder for your chart files. It asks for your
   default city, finds it in Astrolog's atlas and sets the time zone and
   location for you. Type the name in English; for common names add the
   country or state code, such as `Madrid, ES` or `Paris, FR`.
4. Sets two XQuartz keyboard options this fork needs: Command shortcuts go to
   Astrolog instead of XQuartz, and the Option key works with the function
   keys. With this, Command+Q no longer quits XQuartz; use its menu instead.
5. Offers to open the Keyboard settings, so F1–F12 work as standard function
   keys. Otherwise, hold `fn` while pressing them.

If you just installed XQuartz, **restart the Mac** before opening Astrolog.

### Updating

Run the same command again. It installs the latest version of the app and
never overwrites your `astrolog.as` or your charts.

### Installer options

| Option | Effect |
|--------|--------|
| `--dir FOLDER` | Keep your settings and charts in another folder instead of `~/Astrolog` |
| `--city "Madrid, ES"` | Set the default city without asking |
| `--yes` | Don't ask questions; accept the default answers |
| `--from-source` | Build from the source code instead (see below) |

Add options at the end of the command, after a space.

### Downloading the app by hand

You can also download `Astrolog-macOS.zip` from the
[Releases](https://github.com/Juancx3/AstrologMacOS/releases) page, unzip it
and move `Astrolog.app` to your Applications folder. The first time you open
it, the app asks for your city and sets things up.

The app isn't signed with an Apple developer certificate, so macOS blocks a
copy downloaded with a web browser. To allow it, run this once in the
Terminal (the installer above doesn't need it):

```bash
xattr -dr com.apple.quarantine ~/Applications/Astrolog.app
```

Or open it, then go to **System Settings → Privacy & Security** and click
**Open Anyway**.

### Building from the source code

For those who want to read or change the code. Add `--from-source` to the
installation command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Juancx3/AstrologMacOS/Macos-AppleSilicon-x11/macos/install.sh) --from-source
```

Or clone the repository and run the installer from it:

```bash
git clone -b Macos-AppleSilicon-x11 https://github.com/Juancx3/AstrologMacOS.git ~/Astrolog
bash ~/Astrolog/macos/install.sh
```

Besides the steps above, the installer then checks for the Command Line Tools
(if they're missing, a macOS window offers to install them: click
**Install**, not "Get Xcode"), downloads the source code into `~/Astrolog`,
builds it in about a minute, and creates an `Astrolog.app` that runs your
build. Your `astrolog.as` and `charts` are in the same folder as the code.

To update, run `bash ~/Astrolog/macos/install.sh` again: it downloads the
latest code and rebuilds. After changing the code, rebuild with:

```bash
cd ~/Astrolog
make -f macos/Makefile -j8
```

The app picks up the new build without any other step.

## Running Astrolog

Open Astrolog from Spotlight (Command+Space, type *Astrolog*) or Launchpad.
To keep it in the Dock, right-click its Dock icon while it's open and choose
**Options → Keep in Dock**.

The app opens a Terminal window and runs Astrolog there, with your settings.
Keep that window visible next to the chart window: text output, error
messages and the help lists appear there.

When the graphics window is open, it must have the focus to receive key
presses. Press `?` with the window focused to list all keys; the list appears
in the Terminal. Press `Esc` to close the window and exit.

To have Terminal close its window when you exit Astrolog, go to
**Terminal → Settings → Profiles → Shell** and set "When the shell exits" to
**Close if the shell exited cleanly**.

The graphics window shows the XQuartz icon in the Dock; that comes from
XQuartz and can't be changed.

### Running from the Terminal

To start Astrolog with command switches, add this line to `~/.zshrc` and open
a new Terminal window:

```bash
alias astrolog="$HOME/Applications/Astrolog.app/Contents/Resources/astrolog.command"
```

Then, for example:

| Command | Result |
|---------|--------|
| `astrolog` | Chart for now, using the settings in `astrolog.as` |
| `astrolog -i mychart.as` | Open a chart from your `charts` folder |
| `astrolog _X -v` | Text-only chart listing in the Terminal |
| `astrolog -H` | List of all command switches |

If you built from the source code, you can also run `./astrolog` in
`~/Astrolog`.

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

You can type these in the command box (Enter) or after `astrolog` in the
Terminal (see [Running from the Terminal](#running-from-the-terminal)).
`mychart.as` stands for one of your chart files; files in your `charts`
folder can be named without a path.

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

Astrolog reads its default settings from `astrolog.as` in your settings
folder: `~/Astrolog`, unless you chose another one with `--dir`. This file is
yours, and updates never overwrite it. The installer creates it from
`astrolog-default.as`, the standard settings with a few changes for the Mac:
it starts with the chart for now in the graphics window, uses larger glyphs
for Retina screens, and looks for chart files in the `charts` folder.

Edit it to suit you. The location lines are `-z` (time zone), `-zl`
(longitude and latitude) and `-zj` (place name). To start over, delete
`astrolog.as` and open Astrolog: it asks for your city again.

If you bring a settings file from the Windows version, comment out
(prefix with `;`) every line that begins with `-W`, `_W` or `=W`, such as
`-WM`, `-WN` and `=Wh`. The Mac version doesn't know these switches. It stops
at the first one it finds and shows no chart. The installer offers to do this
for you if it finds such lines.

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

**XQuartz opens and closes immediately**
To test X11 alone, run `/opt/X11/bin/xeyes`: a pair of eyes that follow the
mouse should appear.
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

**Command shortcuts or Option + function keys do nothing**
Make sure the Astrolog window, not the Terminal, has the focus. Then check
XQuartz → Settings → Input: "Enable key equivalents under X11" must be
**unchecked** and "Option keys send Alt_L and Alt_R" **checked**. The
installer sets both; if you answered no, run it again or change them there.

**Function keys change the volume or brightness instead**
Hold `fn`, or enable **System Settings → Keyboard → Keyboard Shortcuts →
Function Keys → "Use F1, F2, etc. keys as standard function keys"**.

**The installer says it couldn't download Astrolog, or that the checksum
doesn't match**
Check your internet connection and run the installer again. If it keeps
happening, please open an issue in this repository.

**Building from source: the installer says the build failed**
It shows the first errors and the path of the full log
(`~/Astrolog/build/build.log`). Please open an issue in this repository and
attach that log.

**macOS says Astrolog can't be opened, or can't be verified**
This happens with a copy downloaded with a web browser. See
[Downloading the app by hand](#downloading-the-app-by-hand), or install with
the installer command instead.

**"Unknown switch '-WM'" when starting**
Your `astrolog.as` comes from Windows. Comment out its Windows-only lines
(see [Settings file](#settings-file-astrologas)).

**Accents in chart names look wrong in the Terminal**
Files saved on Windows use the Windows-1252 character set. Convert one with:
`iconv -f WINDOWS-1252 -t UTF-8 old.as > new.as`

## Uninstalling

Delete the app and the settings folder. Copy your `astrolog.as` and the
`charts` folder somewhere else first if you want to keep them.

```bash
rm -rf ~/Applications/Astrolog.app ~/Astrolog
defaults delete io.github.juancx3.astrolog
```

The last line only matters if you chose another settings folder with
`--dir`; delete that folder too. XQuartz can stay; other programs may use it.

## For maintainers

### Publishing a release

Create the release on GitHub, for example:

```bash
gh release create v8.00-mac4 --target Macos-AppleSilicon-x11 --title "Astrolog 8.00 for macOS - mac4" --notes-file notes.md --latest
```

Publishing it starts the **Build macOS app** workflow
(`.github/workflows/release.yml`). It builds Astrolog on a Mac, packages the
app with `macos/make-app.sh --standalone`, tests a chart that needs the
ephemeris files, and attaches `Astrolog-macOS.zip` and its `.sha256`
checksum to the release, in a few minutes. The installer always downloads
the release marked as latest. To test a change without publishing, run the
workflow by hand from the Actions tab, with no tag: the app is kept as an
artifact of the run.

### Merging a new Astrolog version

When the author releases a new version, bring it into this fork:

```bash
cd ~/Astrolog
git remote add upstream https://github.com/CruiserOne/Astrolog.git
git fetch upstream
git rebase upstream/master
bash macos/install.sh
```

The `git remote add` line is needed only the first time. If the author
changed the same parts of `xscreen.cpp`, `general.cpp`, `calc.cpp` or
`astrolog.h`, git will report a conflict that has to be resolved by hand.
`macos/Makefile` builds without the installer (`make -f macos/Makefile -j8`,
or `UNIVERSAL=1` for Apple Silicon and Intel).
