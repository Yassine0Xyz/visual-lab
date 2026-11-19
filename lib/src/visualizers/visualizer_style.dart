enum VisualizerStyle {
  bars('Bars', 'Precision spectrum'),
  wave('Wave', 'Oscilloscope ribbon'),
  columns('Columns', 'Architectural spectrum'),
  mirror('Mirror', 'Symmetric energy'),
  orbit('Orbit', 'Circular frequency field'),
  radial('Radial', 'Radial spectrum'),
  fluid('Fluid', 'Layered audio currents'),
  particles('Particles', 'Energy-driven particles'),
  geometry('Geometry', 'Reactive polygon field');

  const VisualizerStyle(this.title, this.subtitle);
  final String title;
  final String subtitle;
}
