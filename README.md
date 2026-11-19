# SONORA — Audio Visualizer Lab

A standalone Flutter/Dart visualizer research app. It is not connected to YAZEN Player and contains no YAZEN-specific code.

## What is included

- Premium dark lab UI, visual stage, track import, playback controls, seek bar and fullscreen mode.
- Nine independent rendering identities: **Bars, Wave, Columns, Mirror, Orbit, Radial, Fluid, Particles, Geometry**.
- Real-time analysis of the audio engine's actual mixer output using SoLoud's FFT and waveform visualization stream.
- 64 perceptually grouped bands plus bass/mid/high/overall energy summaries, with attack/release smoothing.
- Sensitivity, live attack/release smoothing, scale, five palettes and optional glow.
- Separated audio engine, analysis/model, painter, style registry, configuration and screen.

## Audio pipeline

`Local file → SoLoud decoder / mixer → SoLoud visualization stream (FFT + waveform) → AudioAnalyzer → AudioFrame → CustomPainter`

The renderer never reads the file or talks to the playback engine. A dedicated `ValueNotifier<AudioFrame>` repaints the `CustomPainter` directly, so FFT packets do not rebuild the full screen. It receives only `AudioFrame`. SoLoud's FFT is computed by its native audio engine from the playback mixer output; this is not microphone capture and not a random animation.

## Project structure

```text
lib/
  main.dart
  src/
    audio/
      audio_engine.dart
      audio_analyzer.dart
      audio_frame.dart
    visualizers/
      visualizer_style.dart
      visualizer_config.dart
      visualizer_painter.dart
    screens/
      lab_app.dart
```

## Run locally

1. Install Flutter (stable) and Android Studio / Android SDK.
2. Extract the ZIP.
3. From the project folder:
   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```
4. Tap the folder icon to import a local audio file (MP3, WAV, FLAC, OGG and formats supported by SoLoud on the target platform).
5. Choose a visualizer and tune the render controls.

Android minimum SDK must be 21 or higher. `flutter_soloud` uses native libraries via Dart build hooks; use a current Flutter stable toolchain.

## Dependencies and licenses

| Dependency | Purpose | License |
|---|---|---|
| Flutter SDK | UI and rendering | BSD-3-Clause |
| flutter_soloud | Audio decoding/playback + real mixer FFT/wave stream | MIT (SoLoud core has its own license notices; retain bundled notices) |
| file_picker | Local audio file selection | MIT |
| flutter_lints | Static analysis rules | BSD-3-Clause |

Check the resolved package versions and their transitive notices after `flutter pub get` before distribution.

## Important verification status

This source package was generated in an environment without a Flutter SDK or Android device attached. Therefore **no `flutter pub get`, `flutter analyze`, APK build, device playback test, or FPS benchmark has been run here**. The implementation uses the current `flutter_soloud` 5.x visualization-stream API (`audioVisualizationEvents`, `AudioVisualizationData.fftData/waveData`, `setVisualizationEnabled`). Validate API compatibility against the exact resolved package version with `flutter pub get` and `flutter analyze` before treating the app as build-verified.

The current screen uses a small UI timer to refresh the displayed playback position; visualization packets themselves come from the engine's audio callback stream. Position seeking and native event names should be verified on the target platform during the first build. Unsupported codecs depend on platform decoder support.

## Extraction into YAZEN later

The clean extraction boundary is `lib/src/visualizers/` plus the `AudioFrame` contract:

1. Keep `AudioFrame` as the renderer-facing data model, or map YAZEN's existing PCM/FFT output into it.
2. Copy `VisualizerStyle`, `VisualizerConfig`, `VisualizerPainter` and the palette definitions.
3. In YAZEN, provide a `ValueListenable<AudioFrame>` or equivalent stream from its existing analysis service.
4. Host the painter in a `CustomPaint` and drive repaints from a `Listenable`; do not import `AudioEngine` into the visualizer package.
5. Keep playback ownership, lifecycle, audio focus, media notifications and queue handling inside YAZEN. Do not replace YAZEN's playback engine just to reuse these renderers.

The standalone lab intentionally owns its own SoLoud playback engine. That engine is an experimental harness and is not required by the visualizer rendering package.
