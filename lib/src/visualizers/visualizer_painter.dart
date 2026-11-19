import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../audio/audio_frame.dart';
import 'visualizer_config.dart';
import 'visualizer_style.dart';

class VisualizerPainter extends CustomPainter {
  VisualizerPainter({
    required this.frames,
    required this.style,
    required this.config,
  }) : super(repaint: frames);

  final ValueListenable<AudioFrame> frames;
  final VisualizerStyle style;
  final VisualizerConfig config;

  AudioFrame get frame => frames.value;
  double get phase {
    // Motion follows the actual playback clock and is energy-modulated.
    final seconds = frame.timestamp.inMicroseconds / Duration.microsecondsPerSecond;
    return seconds * (0.10 + frame.energy * 1.9);
  }

  List<Color> get colors => palettes[config.palette % palettes.length];
  Color colorAt(double t) => Color.lerp(colors[0], colors[1], t.clamp(0.0, 1.0))!;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;
    final bands = frame.bands;
    final gain = config.sensitivity * config.scale;
    final glow = config.glow;

    final bg = Paint()
      ..shader = RadialGradient(
        colors: [colors[1].withOpacity(.12), Colors.transparent, Colors.transparent],
        stops: const [0, .62, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    switch (style) {
      case VisualizerStyle.bars:
        _bars(canvas, size, bands, gain, glow);
        break;
      case VisualizerStyle.wave:
        _wave(canvas, size, frame.wave, gain, glow);
        break;
      case VisualizerStyle.columns:
        _columns(canvas, size, bands, gain, glow);
        break;
      case VisualizerStyle.mirror:
        _mirror(canvas, size, bands, gain, glow);
        break;
      case VisualizerStyle.orbit:
        _orbit(canvas, center, math.min(w, h) * .24, bands, gain, glow);
        break;
      case VisualizerStyle.radial:
        _radial(canvas, center, math.min(w, h) * .19, bands, gain, glow);
        break;
      case VisualizerStyle.fluid:
        _fluid(canvas, size, frame, gain, glow);
        break;
      case VisualizerStyle.particles:
        _particles(canvas, size, bands, gain);
        break;
      case VisualizerStyle.geometry:
        _geometry(canvas, center, math.min(w, h) * .20, bands, gain, glow);
        break;
    }
  }

  void _bars(Canvas c, Size s, List<double> b, double gain, bool glow) {
    const n = 52;
    final gap = s.width * .006;
    final barW = (s.width - gap * (n - 1)) / n;
    final base = s.height * .78;
    for (var i = 0; i < n; i++) {
      final v = b[(i * b.length / n).floor()] * gain;
      final height = (s.height * .58 * v).clamp(2.0, s.height * .68);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (barW + gap), base - height, barW, height),
        Radius.circular(barW),
      );
      final p = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [colors[0], colors[1], colors[2]],
        ).createShader(rect.outerRect);
      if (glow) {
        c.drawRRect(rect, Paint()..color = colors[1].withOpacity(.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }
      c.drawRRect(rect, p);
    }
  }

  void _wave(Canvas c, Size s, List<double> wave, double gain, bool glow) {
    if (wave.isEmpty) return;
    final path = Path();
    final mid = s.height * .5;
    for (var i = 0; i < wave.length; i++) {
      final x = i / (wave.length - 1) * s.width;
      final y = mid - wave[i] * s.height * .38 * gain;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: colors).createShader(Offset.zero & s);
    if (glow) c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 12..color = colors[1].withOpacity(.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    c.drawPath(path, p);
    final lower = Path()..addPath(path, Offset.zero)..lineTo(s.width, mid)..lineTo(0, mid)..close();
    c.drawPath(lower, Paint()..shader = LinearGradient(colors: [colors[1].withOpacity(.18), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Offset.zero & s));
  }

  void _columns(Canvas c, Size s, List<double> b, double gain, bool glow) {
    const n = 24;
    final colW = s.width / (n * 1.55);
    for (var i = 0; i < n; i++) {
      final v = b[(i * b.length / n).floor()] * gain;
      final height = (s.height * .52 * v).clamp(3.0, s.height * .58);
      final x = (i + .5) * s.width / n - colW / 2;
      final rect = Rect.fromLTWH(x, s.height * .78 - height, colW, height);
      final p = Paint()..shader = LinearGradient(colors: [colors[2], colors[0]], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect);
      if (glow) c.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(5)), Paint()..color = colors[0].withOpacity(.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), p);
      c.drawCircle(Offset(x + colW / 2, rect.top), colW * .34, Paint()..color = Colors.white.withOpacity(.8));
    }
  }

  void _mirror(Canvas c, Size s, List<double> b, double gain, bool glow) {
    const n = 48;
    final gap = 2.2;
    final barW = (s.width - gap * n) / n;
    final mid = s.height * .5;
    for (var i = 0; i < n; i++) {
      final v = b[(i * b.length / n).floor()] * gain;
      final hh = (s.height * .31 * v).clamp(2.0, s.height * .34);
      final x = i * (barW + gap);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, mid - hh, barW, hh * 2), Radius.circular(barW));
      if (glow) c.drawRRect(r, Paint()..color = colors[1].withOpacity(.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      c.drawRRect(r, Paint()..color = colorAt(i / n));
    }
    c.drawLine(Offset(0, mid), Offset(s.width, mid), Paint()..color = Colors.white.withOpacity(.12)..strokeWidth = 1);
  }

  void _orbit(Canvas c, Offset center, double radius, List<double> b, double gain, bool glow) {
    c.drawCircle(center, radius * .66, Paint()..color = colors[1].withOpacity(.08)..style = PaintingStyle.fill);
    c.drawCircle(center, radius * .66, Paint()..color = colors[1].withOpacity(.5)..style = PaintingStyle.stroke..strokeWidth = 1);
    for (var i = 0; i < 64; i++) {
      final a = i / 64 * math.pi * 2 - math.pi / 2;
      final v = b[i] * gain;
      final r1 = radius * .78;
      final r2 = r1 + 8 + v * radius * 1.15;
      final p = Paint()..color = colorAt(i / 64)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      if (glow) c.drawLine(center + Offset(math.cos(a) * r1, math.sin(a) * r1), center + Offset(math.cos(a) * r2, math.sin(a) * r2), Paint()..color = colors[1].withOpacity(.3)..strokeWidth = 8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawLine(center + Offset(math.cos(a) * r1, math.sin(a) * r1), center + Offset(math.cos(a) * r2, math.sin(a) * r2), p);
    }
  }

  void _radial(Canvas c, Offset center, double radius, List<double> b, double gain, bool glow) {
    final path = Path();
    for (var i = 0; i < b.length; i++) {
      final a = i / b.length * math.pi * 2;
      final r = radius + b[i] * gain * radius * 1.7;
      final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    if (glow) c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 12..color = colors[1].withOpacity(.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..shader = SweepGradient(colors: [...colors, colors.first]).createShader(Rect.fromCircle(center: center, radius: radius * 2)));
    c.drawCircle(center, radius * .48, Paint()..color = colors[1].withOpacity(.08));
  }

  void _fluid(Canvas c, Size s, AudioFrame f, double gain, bool glow) {
    for (var layer = 0; layer < 4; layer++) {
      final path = Path();
      final base = s.height * (.43 + layer * .095);
      for (var i = 0; i <= 80; i++) {
        final x = i / 80 * s.width;
        final band = f.bands[(i * 63 / 80).round()];
        final y = base + math.sin(i * .11 + phase * 4 + layer) * 7 + (band * gain * 25 * (layer.isEven ? 1 : -1));
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.2 - layer * .45..strokeCap = StrokeCap.round..color = colors[layer % 3].withOpacity(.88 - layer * .13);
      if (glow) c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 13..color = p.color.withOpacity(.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      c.drawPath(path, p);
    }
  }

  void _particles(Canvas c, Size s, List<double> b, double gain) {
    for (var i = 0; i < 130; i++) {
      final band = b[i % b.length];
      final seed = i * 127.1;
      final x = ((math.sin(seed) * .5 + .5) * s.width);
      final yBase = ((math.cos(seed * .73) * .5 + .5) * s.height);
      final drift = math.sin(phase * 2 + seed) * (3 + band * 16 * gain);
      final radius = 1 + band * 3.5 * gain;
      c.drawCircle(Offset(x + drift, yBase + math.cos(phase + seed) * 5), radius, Paint()..color = colorAt(band).withOpacity(.28 + band * .65));
    }
  }

  void _geometry(Canvas c, Offset center, double radius, List<double> b, double gain, bool glow) {
    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      const n = 9;
      for (var i = 0; i <= n; i++) {
        final a = i / n * math.pi * 2 + layer * .17;
        final v = b[(i * 7 + layer * 13) % b.length];
        final r = radius * (1 + layer * .28) + v * gain * radius * .95;
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8 + layer * .4..color = colors[layer].withOpacity(.85 - layer * .16);
      if (glow) c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 10..color = paint.color.withOpacity(.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter old) =>
      old.frames != frames || old.style != style || old.config != config;
}
