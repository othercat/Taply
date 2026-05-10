# Taply

A lightweight macOS audio player. Drop in files or folders, play through a playlist with loop, shuffle, volume control, and seek — all from a minimal floating window.

## History

- **Original author:** Carsten Bluem (net.bluem)
- **Current maintainer:** Richard Li (othercat@gmail.com)
- **License:** See `LICENSE`

Taply was originally built with QuickTime C APIs. In 2026, it was modernized to use AVFoundation, targeting macOS 10.14+ (Intel and Apple Silicon).

## Supported Formats

- MP3
- M4A (AAC)
- AIFF / AIFC
- WAV

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

The built app will be in the `DerivedData` build products directory. To copy it:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Deployment/Taply.app ~/Downloads/
```

## Running

Double-click `Taply.app`, or launch from the command line with audio files as arguments:

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
- Dark mode support
- Localized: English, German, French, Italian, Simplified Chinese

## Architecture

```
src/
  AppController.h/m        - Main controller (playlist, playback, UI)
  AVSoundFilePlayer.h/m    - AVFoundation-based audio player wrapper
  TaplyPlaylist.h/m        - Playlist (array of file paths)
  Timer.h/m                - Background timer for elapsed time display
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
```

## Known Limitations

- MIDI playback is not yet supported (planned for Phase 5).
- The Timer class uses a detached background thread for UI updates (planned to be replaced with main-thread NSTimer).
- Memory management is manual retain/release, not ARC.

## Roadmap

See `docs/TODO.md` for the full migration plan and current progress.
