# Metronome

A simple, native macOS metronome. Set a tempo and time signature, press start, and hear a steady click — accented on the downbeat — until you press stop.

## Features

- Tempo from 30–300 BPM, adjustable by typing, dragging a slider, or the arrow keys.
- Time signatures from 1–32 beats per measure, with a choice of note value (whole, half, quarter, eighth).
- Accented downbeat so you can always hear where the measure starts.
- Tempo and time signature are remembered between launches.
- Space bar starts and stops the metronome.
- Rock-solid timing: clicks are driven by the audio hardware clock, not a timer, so they never drift or jitter.

## Requirements

| Item | Version |
|---|---|
| macOS (deployment target) | 14.0 (Sonoma) |
| Xcode | 16 or later |
| Swift | 6.0 |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | 2.40 or later |

## Building

The Xcode project is generated from `project.yml` and is not checked in.

```sh
brew install xcodegen
xcodegen generate
open Metronome.xcodeproj
```

Or from the command line:

```sh
xcodegen generate
xcodebuild -project Metronome.xcodeproj -scheme Metronome build
xcodebuild -project Metronome.xcodeproj -scheme Metronome test
```

Re-run `xcodegen generate` whenever files are added, removed, or `project.yml` changes.

## Sandboxing and distribution

- App Sandbox is on. Audio output needs no extra entitlement.
- Hardened Runtime is on, so the app can be notarized.

## Future enhancements

- Tap tempo.
- Subdivisions (eighths, triplets, sixteenths).
- A choice of click sounds and volume control.
- A menu bar extra for controlling the metronome without the main window.
