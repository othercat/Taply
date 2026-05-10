# Taply Testing

## Build Verification

```bash
cd src
/Applications/Xcode_16.4.app/Contents/Developer/usr/bin/xcodebuild \
  -project Taply.xcodeproj \
  -target Taply \
  -configuration Development \
  -sdk macosx \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  build
```

Expected: BUILD SUCCEEDED with no errors.

## Universal Binary Verification

```bash
lipo -info path/to/Taply.app/Contents/MacOS/Taply
```

Expected: `Architectures in the fat file: Taply are: x86_64 arm64`

## Manual Smoke Test

### Setup

Prepare test audio files outside the repo:

```bash
mkdir -p /tmp/taply-test
# Copy or create test files:
# /tmp/taply-test/audio-one.mp3
# /tmp/taply-test/audio-two.m4a
# /tmp/taply-test/audio-three.wav
# /tmp/taply-test/audio-four.aiff
```

### Test Checklist

- [ ] Launch app without file arguments -> open panel appears
- [ ] Select multiple files in open panel -> first file starts playing
- [ ] Click pause -> playback pauses, elapsed time stops
- [ ] Click resume -> playback continues from where it paused
- [ ] Drag position bar to middle -> playback jumps to new position, time display updates
- [ ] Adjust volume slider -> volume changes
- [ ] Click next -> next track plays
- [ ] Click previous -> previous track plays
- [ ] Enable loop -> current track replays when finished
- [ ] Drag a folder onto window -> playable files are added to playlist
- [ ] Enable shuffle preference -> new files are added in random order
- [ ] Close window -> playback stops, app exits cleanly
- [ ] Right-click (context menu) -> shows playlist, prefs, clear, quit
- [ ] Select a track from context menu -> that track plays
- [ ] File icon shows the audio file's icon

### Command-Line Launch Test

```bash
open Taply.app --args /tmp/taply-test/audio-one.mp3
```

Expected: Taply opens and plays the file. If file cannot be decoded, shows an error alert instead of crashing.

### Dark Mode Test

- [ ] Switch macOS appearance to Dark Mode
- [ ] Verify text fields have correct background color
- [ ] Verify position bar is visible and functional
- [ ] Switch back to Light Mode and verify

### Localization Test

- [ ] System language set to English -> UI strings in English
- [ ] System language set to Simplified Chinese -> UI strings in Chinese
- [ ] System language set to German -> UI strings in German
- [ ] System language set to French -> UI strings in French
- [ ] System language set to Italian -> UI strings in Italian
- [ ] Click ? button -> correct localized Read me.html opens

## Known Limitations

- MIDI playback not yet supported
- Timer class (Timer.h/m) is no longer used but still in the project files
- Memory management is manual retain/release, not ARC
