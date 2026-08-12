import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'screens/platform_payments_screen.dart';

void main() => runApp(const LizmoAdminApp());

/// Lizmo's internal admin console.
///
/// Separate from the mobile app on purpose: platform admins are Lizmo staff,
/// not landlords, tenants or their caretakers, and this tooling should never
/// ship inside the app customers install.
class LizmoAdminApp extends StatelessWidget {
  const LizmoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lizmo Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: LizmoColors.teal900,
          primary: LizmoColors.teal900,
          surface: LizmoColors.canvas,
        ),
        scaffoldBackgroundColor: LizmoColors.canvas,
        useMaterial3: true,
      ),
      home: const PlatformPaymentsScreen(),
    );
  }
}
