import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'admin_shell.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Tokens stay in memory. On web, flutter_secure_storage keeps its
        // encryption key in localStorage beside the data, so any XSS on this
        // origin could lift a persisted refresh token — and this is the console
        // where a stolen session can confirm payments to Lizmo.
        //
        // The trade is deliberate: closing the tab ends the session. Revisit if
        // the backend ever issues an httpOnly refresh cookie.
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      ],
      child: const LizmoAdminApp(),
    ),
  );
}

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
      home: const AdminShell(),
    );
  }
}
