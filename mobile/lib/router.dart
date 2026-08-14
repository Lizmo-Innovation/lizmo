import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'auth/active_role.dart';
import 'screens/login_screen.dart';
import 'screens/rent_roll_screen.dart';
import 'screens/tenant_home_screen.dart';

/// Route paths, named so a typo is a compile error rather than a blank screen.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const tenant = '/tenant';
  static const landlord = '/landlord';
  static const noProfile = '/no-profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    // The redirect is the only place that decides what a user may see. Screens
    // never push or pop themselves between signed-in and signed-out, so a
    // session ending anywhere lands the user on login without every screen
    // handling it.
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      return switch (auth) {
        // Stored tokens are still being checked. Holding on the splash avoids
        // flashing login at someone who turns out to be signed in.
        AuthUnknown() => location == Routes.splash ? null : Routes.splash,

        AuthSignedOut() => location == Routes.login ? null : Routes.login,

        AuthSignedIn(:final session) => _signedInRedirect(ref, session, location),
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.tenant, builder: (context, state) => const TenantHomeScreen()),
      GoRoute(path: Routes.landlord, builder: (context, state) => const RentRollScreen()),
      GoRoute(path: Routes.noProfile, builder: (context, state) => const NoProfileScreen()),
    ],
    errorBuilder: (_, state) => NotFoundScreen(location: state.uri.toString()),
  );
});

/// Where a signed-in user belongs.
///
/// Guards against reaching the wrong role's screen by URL: a tenant typing
/// /landlord is redirected home rather than shown the rent roll, which lists
/// every tenant in the property.
String? _signedInRedirect(Ref ref, Session session, String location) {
  final home = switch (ref.read(activeRoleProvider)) {
    LizmoProfile.landlord => Routes.landlord,
    LizmoProfile.tenant => Routes.tenant,
    // ADMIN is not a role this app serves; platform admins use the web console.
    LizmoProfile.admin || null => Routes.noProfile,
  };

  // Signed in but sitting on splash or login: move along.
  if (location == Routes.splash || location == Routes.login) return home;

  if (location == Routes.landlord && !session.isLandlord) return home;
  if (location == Routes.tenant && !session.isTenant) return home;

  return null;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}

/// Only reachable if the account holds no tenant or landlord profile.
/// Registration always creates a tenant profile, so this guards against bad
/// data rather than an expected state.
class NoProfileScreen extends ConsumerWidget {
  const NoProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This account has no tenant or landlord profile yet.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowName,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact your landlord, or sign in with a different account.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: Text(
                    'Sign out',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown for an unknown path — reachable by a stale deep link or a typo.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("That page doesn't exist.",
                    textAlign: TextAlign.center, style: LizmoType.rowName),
                const SizedBox(height: 8),
                Text(location,
                    textAlign: TextAlign.center, style: LizmoType.rowSub),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go(Routes.splash),
                  child: Text('Go back',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
