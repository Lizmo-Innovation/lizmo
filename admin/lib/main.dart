import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'router.dart';

void main() {
  // Real paths, not #fragments.
  //
  // Flutter web defaults to the hash strategy, which means the router only
  // ever sees what follows a "#". An invitation link like /invite/<token>
  // then arrives as an empty location, and the console redirects the landlord
  // to a staff sign-in they cannot use -- which is exactly what it did.
  //
  // nginx already answers every path with index.html (see
  // infra/nginx/flutter-web.conf), so a refresh or a pasted URL works.
  usePathUrlStrategy();

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
class LizmoAdminApp extends ConsumerWidget {
  const LizmoAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lizmo Admin',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: LizmoColors.teal900,
          primary: LizmoColors.teal900,
          surface: LizmoColors.canvas,
        ),
        scaffoldBackgroundColor: LizmoColors.canvas,
        useMaterial3: true,
      ),
    );
  }
}
