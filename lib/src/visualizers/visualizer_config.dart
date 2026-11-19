import 'package:flutter/material.dart';

class VisualizerConfig {
  const VisualizerConfig({
    this.sensitivity = 1.35,
    this.smoothing = 0.72,
    this.scale = 0.82,
    this.glow = true,
    this.palette = 0,
  });

  final double sensitivity;
  final double smoothing;
  final double scale;
  final bool glow;
  final int palette;

  VisualizerConfig copyWith({
    double? sensitivity,
    double? smoothing,
    double? scale,
    bool? glow,
    int? palette,
  }) =>
      VisualizerConfig(
        sensitivity: sensitivity ?? this.sensitivity,
        smoothing: smoothing ?? this.smoothing,
        scale: scale ?? this.scale,
        glow: glow ?? this.glow,
        palette: palette ?? this.palette,
      );
}

const palettes = <List<Color>>[
  [Color(0xFF61F4DE), Color(0xFF5B8CFF), Color(0xFFB56BFF)],
  [Color(0xFFFFC36B), Color(0xFFFF6B8A), Color(0xFFB56BFF)],
  [Color(0xFFB7F36B), Color(0xFF39D5B0), Color(0xFF4C8DFF)],
  [Color(0xFFFFF0A6), Color(0xFFFF9B71), Color(0xFFEA5B9B)],
  [Color(0xFFE5E7EB), Color(0xFF9CA3AF), Color(0xFF64748B)],
];
