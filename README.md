# Taply

A lightweight macOS audio player. Drop in files or folders, play through a playlist with loop, shuffle, volume control, and seek — all from a minimal floating window.

## History

- **Original author:** Carsten Bluem (net.bluem)
- **Current maintainer:** Richard Li (othercat@gmail.com)
- **License:** See `LICENSE`

Taply was originally built with QuickTime C APIs. In 2026, it was modernized to use AVFoundation and AVMIDIPlayer, targeting macOS 10.14+ (Intel and Apple Silicon).

## Supported Formats

**Audio:**
- MP3
- M4A (AAC)
- AIFF / AIFC
- WAV

**MIDI (preview only):**
- MID / MIDI
- RMI
- KAR

## Building

Requirements:
- macOS 10.14 or later
- Xcode 16.4 (or compatible)

```bash
cd src
/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild \
  -project Taply.xcodeproj \
  -target Taply \
  -configuration Deployment \
  -sdk macosx \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build
```

The built app will be in the build products directory. To copy it:

```bash
cp -R src/build/Deployment/Taply.app ~/Downloads/
```

## Running

Double-click `Taply.app`, or launch from the command line with files as arguments:

```bash
open Taply.app --args /path/to/song.mp3 /path/to/another.m4a
```

## Features

- Drag and drop files or folders onto the window
- Open panel on launch if no files specified
- Play / Pause / Next / Previous
- Loop (repeat current track)
- Volume slider with keyboard shortcuts
- Seek via position bar
- Shuffle preference
- Playlist with contextual menu
- MIDI playback with optional custom sound bank
- Dark mode support
- Localized: English, German, French, Italian, Simplified Chinese

## MIDI Sound Bank

By default, Taply uses the system DLS synthesizer. To use a custom sound bank (.sf2, .sf3, .dls):

```bash
defaults write net.bluem.taply MIDISoundBankPath /path/to/soundbank.sf2
```

To revert to the system default:

```bash
defaults delete net.bluem.taply MIDISoundBankPath
```

Note: MIDI playback is a **preview backend** using Apple's AVMIDIPlayer. It does not support Yamaha XG SysEx parameters. For full XG parity, use Windows with foobar2000 + foo_midi + S-YXG50 VSTi.

## Architecture

```
src/
  AppController.h/m        - Main controller (playlist, playback, UI)
  AVSoundFilePlayer.h/m    - AVFoundation audio player wrapper
  MIDISoundFilePlayer.h/m  - AVMIDIPlayer MIDI player wrapper
  TaplyPlaylist.h/m        - Playlist (array of file paths)
  Timer.h/m                - Legacy timer (no longer used)
  TaplyWindow.h/m          - Custom NSWindow subclass
  TaplyPositionBar.h/m     - Custom seek bar
  TaplyGradientBox.h/m     - Gradient background view
  functions.h/m            - Utility functions (time formatting)
  Info.plist                - Bundle metadata and document types
  Taply.xcodeproj/         - Xcode project
  English.lproj/           - English localization
  de.lproj/                - German localization
  fr.lproj/                - French localization
  it.lproj/                - Italian localization
  zh-Hans.lproj/           - Simplified Chinese localization
docs/
  TODO.md                  - Migration plan and progress
  TESTING.md               - Manual smoke test checklist
  MIDI_XG_RESEARCH.md      - MIDI/XG reference chain documentation
  MIDI_XG_TESTING.md       - MIDI testing procedures
```

## Known Limitations

- MIDI playback uses AVMIDIPlayer (preview only, not XG parity)
- Timer.h/m is legacy code no longer compiled but still in the project
- Memory management is manual retain/release, not ARC

## Roadmap

See `docs/TODO.md` for the full migration plan and current progress.
