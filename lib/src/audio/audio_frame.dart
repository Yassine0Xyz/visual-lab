import 'dart:typed_data';

/// Immutable snapshot passed from the audio engine to every renderer.
/// `bands` are perceptually grouped FFT magnitudes (0..1); `wave` is PCM.
class AudioFrame {
  const AudioFrame({
    required this.bands,
    required this.wave,
    required this.bass,
    required this.mid,
    required this.high,
    required this.energy,
    required this.timestamp,
  });

  final Float32List bands;
  final Float32List wave;
  final double bass;
  final double mid;
  final double high;
  final double energy;
  final Duration timestamp;

  static AudioFrame silence() => AudioFrame(
        bands: Float32List(64),
        wave: Float32List(256),
        bass: 0,
        mid: 0,
        high: 0,
        energy: 0,
        timestamp: Duration.zero,
      );
}
