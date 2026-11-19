import 'dart:math' as math;
import 'dart:typed_data';
import 'audio_frame.dart';

/// Converts the engine FFT into 64 logarithmically-spaced perceptual bands.
/// Attack/release smoothing is performed here, outside the render loop.
class AudioAnalyzer {
  static const int bandCount = 64;
  final Float32List _smoothed = Float32List(bandCount);
  double smoothing = 0.72;

  AudioFrame analyze({
    required Float32List fft,
    required Float32List wave,
    required Duration position,
  }) {
    if (fft.isEmpty) return AudioFrame.silence();

    final maxBin = fft.length - 1;
    final bands = Float32List(bandCount);

    for (var i = 0; i < bandCount; i++) {
      final start = math.pow(maxBin.toDouble(), i / bandCount)
          .round()
          .clamp(0, maxBin)
          .toInt();
      final end = math.pow(maxBin.toDouble(), (i + 1) / bandCount)
          .round()
          .clamp(start + 1, fft.length)
          .toInt();

      var peak = 0.0;
      for (var j = start; j < end; j++) {
        peak = math.max(peak, fft[j].abs());
      }

      // Square-root compression lifts detail in quiet passages.
      final target = (math.sqrt(peak) * 1.8).clamp(0.0, 1.0);
      final attack = 0.85 - smoothing.clamp(0.05, 0.95) * 0.65;
      final release = 0.42 - smoothing.clamp(0.05, 0.95) * 0.38;
      final coefficient = target > _smoothed[i] ? attack : release;
      _smoothed[i] += (target - _smoothed[i]) * coefficient;
      bands[i] = _smoothed[i];
    }

    double average(int start, int end) {
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        sum += bands[i];
      }
      return sum / (end - start);
    }

    var energy = 0.0;
    for (final value in bands) {
      energy += value;
    }
    energy /= bandCount;

    return AudioFrame(
      bands: bands,
      wave: wave,
      bass: average(0, 10),
      mid: average(10, 38),
      high: average(38, 64),
      energy: energy,
      timestamp: position,
    );
  }
}
