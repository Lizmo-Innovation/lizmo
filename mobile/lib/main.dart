import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'router.dart';

void main() => runApp(const ProviderScope(child: LizmoApp()));

class LizmoApp extends ConsumerWidget {
  const LizmoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
