import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora_visualizer_lab/src/audio/audio_analyzer.dart';

void main() {
  test('analyzer produces 64 finite normalized bands', () {
    final analyzer = AudioAnalyzer();
    final fft = Float32List(512);
    for (var i = 0; i < fft.length; i++) {
      fft[i] = (i % 19) / 19;
    }
    final frame = analyzer.analyze(
      fft: fft,
      wave: Float32List(256),
      position: Duration.zero,
    );
    expect(frame.bands.length, 64);
    expect(frame.bands.every((v) => v.isFinite && v >= 0 && v <= 1), isTrue);
    expect(frame.energy, inInclusiveRange(0, 1));
  });
}
