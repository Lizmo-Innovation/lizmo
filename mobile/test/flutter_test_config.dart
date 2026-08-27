import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts before any test runs.
///
/// Flutter picks this file up automatically for every test in this directory.
///
/// Declaring fonts in pubspec is not enough under `flutter test`: the test
/// binding starts with no real fonts registered and renders every glyph as a
/// box. Without this, goldens verify layout and colour but say nothing about
/// typography — which was the whole reason for bundling the fonts.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  _useAPhoneSizedSurface(binding);
  return testMain();
}

/// Renders tests at phone size rather than the 800x600 default.
///
/// That default is wider than it is tall — a shape no phone has — and it made
/// forms fail for a reason the app does not have: a button sitting below 600px
/// that no amount of scrolling could reveal, because the viewport itself was
/// the wrong shape. Testing a phone app on a phone-shaped surface means a test
/// that passes here says something about the device.
void _useAPhoneSizedSurface(TestWidgetsFlutterBinding binding) {
  binding.platformDispatcher.views.first
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3.0;
}

Future<void> _loadBundledFonts() async {
  // Family names are package-qualified. A TextStyle carrying `package:
  // 'lizmo_ui'` resolves its family to "packages/lizmo_ui/<family>", so
  // registering the bare name silently fails to match and every glyph renders
  // as a box.
  const families = <String, List<String>>{
    'packages/lizmo_ui/Space Grotesk': [
      'packages/lizmo_ui/fonts/SpaceGrotesk-Variable.ttf',
    ],
    'packages/lizmo_ui/Manrope': [
      'packages/lizmo_ui/fonts/Manrope-Variable.ttf',
    ],
    'packages/lizmo_ui/IBM Plex Mono': [
      'packages/lizmo_ui/fonts/IBMPlexMono-Regular.ttf',
      'packages/lizmo_ui/fonts/IBMPlexMono-SemiBold.ttf',
    ],
  };

  for (final MapEntry(key: family, value: assets) in families.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  // Material icons too, or every icon in a golden renders as an empty box and
  // the image cannot show whether the right one was used.
  try {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  } catch (_) {
    // Icons are cosmetic in tests; a missing font must not fail the suite.
  }
}
