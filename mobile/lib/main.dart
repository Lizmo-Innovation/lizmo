import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'push/push_channel.dart';
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
    return MaterialApp.router(
      title: 'Lizmo',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
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
        useMaterial3: true,
      ),
    );
  }
}
