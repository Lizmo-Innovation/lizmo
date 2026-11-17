import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'push/push_channel.dart';
import 'push/push_messages.dart';
import 'push/push_providers.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    overrides: [pushChannelProvider.overrideWithValue(await _pushChannel())],
    child: const LizmoApp(),
  ));
}

/// Firebase, if it starts; otherwise the app opens without push rather than
/// not at all. Bounded, because this is between the tap and the first frame.
Future<PushChannel> _pushChannel() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    return const FirebasePushChannel();
  } catch (_) {
    return const NoPushChannel();
  }
}

class LizmoApp extends ConsumerWidget {
  const LizmoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushRegistrationProvider);
    ref.watch(pushMessagesProvider);
    ref.watch(pushOpenerProvider);
    return MaterialApp.router(
      title: 'Lizmo',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _ScreenSizedText(child: child!),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: LizmoColors.teal900,
          primary: LizmoColors.teal900,
          surface: LizmoColors.canvas,
        ),
        scaffoldBackgroundColor: LizmoColors.canvas,
        // Segment labels fell back to the system font, which is the one place
        // in the app where text was not Manrope. Set here rather than on each
        // control, so the next one is right without anybody remembering.
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              LizmoType.rowName.copyWith(fontSize: 13),
            ),
          ),
        ),
        // A sheet across a whole tablet is a form a metre wide; centred and
        // capped, it reads as the same sheet as on a phone.
        bottomSheetTheme: const BottomSheetThemeData(
          constraints: BoxConstraints(maxWidth: 560),
        ),
        useMaterial3: true,
      ),
    );
  }
}

/// Type a little larger on a tablet, on top of the reader's own setting.
///
/// Gentle and capped: the square root of how much wider the screen is than a
/// 390 phone, never past 1.15, so a tablet reads comfortably without its
/// headings outgrowing the page. On a phone it is exactly 1 and changes
/// nothing.
class _ScreenSizedText extends StatelessWidget {
  const _ScreenSizedText({required this.child});

  final Widget child;

  static const _phone = 390.0;
  static const _most = 1.15;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;
    final by = shortest <= _phone ? 1.0 : math.min(_most, math.sqrt(shortest / _phone));
    if (by == 1.0) return child;
    return MediaQuery(
      data: media.copyWith(textScaler: _Times(media.textScaler, by)),
      child: child,
    );
  }
}

class _Times extends TextScaler {
  const _Times(this.base, this.by);

  final TextScaler base;
  final double by;

  @override
  double scale(double fontSize) => base.scale(fontSize) * by;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * by;

  @override
  bool operator ==(Object other) =>
      other is _Times && other.base == base && other.by == by;

  @override
  int get hashCode => Object.hash(base, by);
}
