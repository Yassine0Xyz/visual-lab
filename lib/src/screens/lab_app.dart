import 'dart:async';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../audio/audio_engine.dart';
import '../visualizers/visualizer_config.dart';
import '../visualizers/visualizer_painter.dart';
import '../visualizers/visualizer_style.dart';

const ink = Color(0xFF080B13);
const panel = Color(0xFF121827);
const muted = Color(0xFF8E9AAF);

class SonoraLabApp extends StatelessWidget {
  const SonoraLabApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SONORA — Visualizer Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF67E8D5), brightness: Brightness.dark),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const LabHome(),
      );
}

class LabHome extends StatefulWidget {
  const LabHome({super.key});
  @override
  State<LabHome> createState() => _LabHomeState();
}

class _LabHomeState extends State<LabHome> {
  final engine = AudioEngine();
  VisualizerStyle style = VisualizerStyle.orbit;
  VisualizerConfig config = const VisualizerConfig();
  Timer? clock;

  @override
  void initState() {
    super.initState();
    engine.addListener(_refresh);
    engine.initialize().catchError((e) {});
    clock = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (!mounted || engine.state != PlaybackState.playing) return;
      // Stream timestamps are driven by the native sound handle, not fabricated.
      try {
        final h = engine.currentHandle;
        if (h != null) {
          engine.updatePosition(SoLoud.instance.getPosition(h));
        }
      } catch (_) {}
    });
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    clock?.cancel();
    engine.removeListener(_refresh);
    engine.dispose();
    super.dispose();
  }

  Future<void> _importAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
    final path = result?.files.single.path;
    if (path != null) await engine.loadFile(path);
  }

  String _time(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = engine.state == PlaybackState.playing;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              sliver: SliverList.list(children: [
                Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [Color(0xFF64F0D8), Color(0xFF6C7BFF)])),
                    child: const Icon(Icons.graphic_eq_rounded, color: ink, size: 25)),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SONORA', style: TextStyle(fontSize: 16, letterSpacing: 3.2, fontWeight: FontWeight.w900)),
                    Text('AUDIO VISUALIZER LAB', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 2.1)),
                  ]),
                  const Spacer(),
                  _LiveBadge(active: isPlaying),
                ]),
                const SizedBox(height: 28),
                const Text('See sound.', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.3)),
                const SizedBox(height: 5),
                const Text('A playground for audio in motion.', style: TextStyle(color: muted, fontSize: 14)),
                const SizedBox(height: 22),
                _visualStage(),
                const SizedBox(height: 19),
                _trackCard(),
                const SizedBox(height: 26),
                Row(children: [
                  const Text('VISUAL LIBRARY', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: muted)),
                  const Spacer(),
                  Text('${VisualizerStyle.values.length} ENGINES', style: const TextStyle(fontSize: 10, color: muted, letterSpacing: 1.4)),
                ]),
                const SizedBox(height: 12),
                _styleGrid(),
                const SizedBox(height: 24),
                _settingsCard(),
                const SizedBox(height: 16),
                const Center(child: Text('SONORA LAB  •  REAL-TIME MIXER ANALYSIS', style: TextStyle(fontSize: 9, color: Color(0xFF566174), letterSpacing: 1.4))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visualStage() => Container(
    height: 270,
    decoration: BoxDecoration(
      color: const Color(0xFF0C1220),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(.08)),
      boxShadow: [BoxShadow(color: palettes[config.palette][1].withOpacity(.10), blurRadius: 36, spreadRadius: -8)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(
        painter: VisualizerPainter(
          frames: engine.frameListenable,
          style: style,
          config: config,
        ),
      )),
      Positioned(left: 17, top: 16, child: _glassTag(style.title.toUpperCase())),
      Positioned(right: 12, top: 10, child: IconButton(
        tooltip: 'Fullscreen visualizer',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullscreenVisualizer(engine: engine, style: style, config: config))),
        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70))),
      Positioned(left: 17, bottom: 16, child: Row(children: [
        _dot(engine.frame.bass, palettes[config.palette][0]),
        const SizedBox(width: 5),
        _dot(engine.frame.mid, palettes[config.palette][1]),
        const SizedBox(width: 5),
        _dot(engine.frame.high, palettes[config.palette][2]),
        const SizedBox(width: 8),
        const Text('LOW   MID   HIGH', style: TextStyle(fontSize: 8, color: Colors.white54, letterSpacing: 1.2)),
      ])),
      Positioned(right: 17, bottom: 16, child: Text('${(engine.frame.energy * 100).round()}% ENERGY', style: const TextStyle(fontSize: 9, color: Colors.white60, letterSpacing: 1.2))),
    ]),
  );

  Widget _trackCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.06))),
    child: Column(children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(colors: [palettes[config.palette][0].withOpacity(.8), palettes[config.palette][2].withOpacity(.8)])),
          child: const Icon(Icons.music_note_rounded, color: ink)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(engine.trackName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 3),
          Text(engine.state == PlaybackState.loading ? 'Preparing audio…' : engine.state.name.toUpperCase(), style: const TextStyle(fontSize: 9, color: muted, letterSpacing: 1.2)),
        ])),
        IconButton(onPressed: _importAudio, icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF70E8D4)), tooltip: 'Import audio'),
      ]),
      const SizedBox(height: 12),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          overlayShape: SliderComponentShape.noOverlay,
          activeTrackColor: palettes[config.palette][0],
          inactiveTrackColor: Colors.white12,
          thumbColor: Colors.white,
        ),
        child: Slider(
          min: 0,
          max: math.max(1.0, engine.duration.inMilliseconds.toDouble()),
          value: engine.position.inMilliseconds.clamp(0, math.max(1, engine.duration.inMilliseconds)).toDouble(),
          onChanged: engine.duration == Duration.zero ? null : (v) => engine.seek(Duration(milliseconds: v.round())),
        ),
      ),
      Row(children: [
        Text(_time(engine.position), style: const TextStyle(fontSize: 10, color: muted, fontFeatures: [])),
        const Spacer(),
        Text(_time(engine.duration), style: const TextStyle(fontSize: 10, color: muted)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: engine.sourceLoaded ? engine.stop : null, icon: const Icon(Icons.stop_rounded), iconSize: 25),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: engine.sourceLoaded ? (engine.state == PlaybackState.playing ? engine.pause : engine.play) : _importAudio,
          child: Container(width: 54, height: 54, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [palettes[config.palette][0], palettes[config.palette][1]]),
            boxShadow: [BoxShadow(color: palettes[config.palette][0].withOpacity(.25), blurRadius: 18)]),
            child: Icon(isPlayingState(engine.state) ? Icons.pause_rounded : Icons.play_arrow_rounded, color: ink, size: 30)),
        ),
        const SizedBox(width: 16),
        IconButton(onPressed: _importAudio, icon: const Icon(Icons.folder_open_rounded), iconSize: 23),
      ]),
      if (engine.errorMessage != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(engine.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 10))),
    ]),
  );

  Widget _styleGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: VisualizerStyle.values.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.12),
    itemBuilder: (_, i) {
      final item = VisualizerStyle.values[i];
      final selected = item == style;
      final icons = [Icons.equalizer_rounded, Icons.waves_rounded, Icons.view_column_rounded, Icons.swap_vert_rounded, Icons.blur_circular_rounded, Icons.radar_rounded, Icons.water_rounded, Icons.grain_rounded, Icons.hexagon_outlined];
      return InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => setState(() => style = item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? palettes[config.palette][0].withOpacity(.12) : panel,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: selected ? palettes[config.palette][0].withOpacity(.65) : Colors.white.withOpacity(.05)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icons[i], color: selected ? palettes[config.palette][0] : const Color(0xFF9BA8BC), size: 22),
            const Spacer(),
            Text(item.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFFD2D8E2))),
            const SizedBox(height: 2),
            Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: muted)),
          ]),
        ),
      );
    },
  );

  Widget _settingsCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.tune_rounded, size: 17, color: Color(0xFF6DE8D5)), SizedBox(width: 8), Text('RENDER CONTROLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7))]),
      const SizedBox(height: 17),
      _sliderRow('Sensitivity', config.sensitivity, .4, 2.8, (v) => setState(() => config = config.copyWith(sensitivity: v))),
      _sliderRow('Visual scale', config.scale, .45, 1.2, (v) => setState(() => config = config.copyWith(scale: v))),
      _sliderRow('Smoothing', config.smoothing, .05, .95, (v) {
        engine.setSmoothing(v);
        setState(() => config = config.copyWith(smoothing: v));
      }),
      const SizedBox(height: 9),
      Row(children: [
        const Text('COLOR SYSTEM', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 1.3)),
        const Spacer(),
        ...List.generate(palettes.length, (i) => GestureDetector(
          onTap: () => setState(() => config = config.copyWith(palette: i)),
          child: Container(
            margin: const EdgeInsets.only(left: 9), width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: palettes[i]),
              border: Border.all(color: config.palette == i ? Colors.white : Colors.transparent, width: 2)),
          ),
        )),
      ]),
      const SizedBox(height: 12),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero, dense: true,
        title: const Text('Soft glow', style: TextStyle(fontSize: 12)),
        value: config.glow, activeColor: const Color(0xFF67E8D5),
        onChanged: (v) => setState(() => config = config.copyWith(glow: v))),
    ]),
  );

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) => Row(children: [
    SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFB7C1D0)))),
    Expanded(child: SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), overlayShape: SliderComponentShape.noOverlay, activeTrackColor: const Color(0xFF67E8D5), thumbColor: Colors.white),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged))),
    SizedBox(width: 34, child: Text(value.toStringAsFixed(1), textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, color: muted))),
  ]);

  Widget _glassTag(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(.35), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(.1))), child: Text(text, style: const TextStyle(fontSize: 8, letterSpacing: 1.5, color: Colors.white70, fontWeight: FontWeight.w700)));
  Widget _dot(double v, Color c) => Container(width: 5 + v * 6, height: 5 + v * 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withOpacity(.4), blurRadius: 7)]));
}

bool isPlayingState(PlaybackState state) => state == PlaybackState.playing;

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: active ? const Color(0xFF14342F) : const Color(0xFF1A2231), borderRadius: BorderRadius.circular(30)),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? const Color(0xFF6CE8D4) : muted, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(active ? 'LIVE' : 'STANDBY', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: active ? const Color(0xFF6CE8D4) : muted, fontWeight: FontWeight.w800)),
    ]),
  );
}

class FullscreenVisualizer extends StatefulWidget {
  const FullscreenVisualizer({super.key, required this.engine, required this.style, required this.config});
  final AudioEngine engine;
  final VisualizerStyle style;
  final VisualizerConfig config;
  @override
  State<FullscreenVisualizer> createState() => _FullscreenVisualizerState();
}

class _FullscreenVisualizerState extends State<FullscreenVisualizer> {
  @override
  @override
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    body: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(
          painter: VisualizerPainter(
            frames: widget.engine.frameListenable,
            style: widget.style,
            config: widget.config,
          ),
        )),
        const Positioned(top: 45, left: 22, child: Text('SONORA  /  IMMERSIVE MODE', style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2))),
        const Positioned(bottom: 34, left: 0, right: 0, child: Center(child: Text('TAP ANYWHERE TO EXIT', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 2)))),
      ]),
    ),
  );
}
