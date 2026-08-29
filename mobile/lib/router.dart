import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'auth/active_role.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_property_screen.dart';
import 'screens/create_unit_screen.dart';
import 'screens/property_detail_screen.dart';
import 'screens/landlord_home_screen.dart';
import 'screens/landlord_shell.dart';
import 'screens/property_list_screen.dart';
import 'screens/tenants_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tenant_home_screen.dart';
import 'screens/tenant_profile_screen.dart';
import 'screens/unit_detail_screen.dart';
import 'screens/unit_utilities_screen.dart';

/// Route paths, named so a typo is a compile error rather than a blank screen.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const tenant = '/tenant';

  /// The tenant's own profile. Under /tenant, so the role guard already
  /// covers it.
  static const tenantProfile = '/tenant/profile';

  /// The landlord section as a whole. Redirects to [landlordHome]; every
  /// guard still matches on this prefix, so the tabs changed nothing about
  /// who may see what.
  static const landlord = '/landlord';

  static const landlordHome = '/landlord/home';
  static const properties = '/landlord/properties';
  static const tenants = '/landlord/tenants';
  static const propertyNew = '/landlord/properties/new';

  /// Detail and unit routes take the property id, so they are functions
  /// rather than constants — a typo in the path becomes a compile error.
  static String propertyDetail(String id) => '/landlord/properties/$id';
  static String unitNew(String id) => '/landlord/properties/$id/units/new';
  static String propertyEdit(String id) => '/landlord/properties/$id/edit';
  static String unitEdit(String propertyId, String unitId) =>
      '/landlord/properties/$propertyId/units/$unitId/edit';
  static String unitDetail(String propertyId, String unitId) =>
      '/landlord/properties/$propertyId/units/$unitId';
  static String unitUtilities(String propertyId, String unitId) =>
      '/landlord/properties/$propertyId/units/$unitId/utilities';
  static const noProfile = '/no-profile';

  /// Reachable without a session. Anything else redirects to login.
  static const signedOutAllowed = {login, register};
}

/// Holds the splash for a moment at launch.
///
/// Restoring a session is often a single read of secure storage, so without
/// this the splash appears for a couple of frames and reads as a flicker
/// rather than a screen. The wait is the point: it is the only place the app
/// introduces itself.
class SplashGate extends ChangeNotifier {
  SplashGate(Duration hold) {
    _timer = Timer(hold, () {
      _open = true;
      notifyListeners();
    });
  }

  static const duration = Duration(seconds: 3);

  bool _open = false;
  bool get isOpen => _open;

  late final Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final splashGateProvider = Provider<SplashGate>((ref) {
  final gate = SplashGate(SplashGate.duration);
  ref.onDispose(gate.dispose);
  return gate;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  final gate = ref.watch(splashGateProvider);
  final reachable = ref.watch(backendHealthProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: Listenable.merge([refresh, gate]),
    // The redirect is the only place that decides what a user may see. Screens
    // never push or pop themselves between signed-in and signed-out, so a
    // session ending anywhere lands the user on login without every screen
    // handling it.
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Nothing is decided until the splash has had its moment, including for
      // a signed-in user whose tokens restore instantly.
      if (!gate.isOpen) {
        return location == Routes.splash ? null : Routes.splash;
      }

      // /landlord is the section, not a screen. Without this it matches
      // nothing and a signed-in landlord lands on the not-found page.
      if (location == Routes.landlord) {
        return Routes.landlordHome;
      }

      // Nor while the backend is out of contact. Every screen past this point
      // is a view onto the API, so login would only fail and a restored
      // session would show an empty portfolio that is not really empty.
      if (reachable != BackendReachability.reachable) {
        return location == Routes.splash ? null : Routes.splash;
      }

      return switch (auth) {
        // Stored tokens are still being checked. Holding on the splash avoids
        // flashing login at someone who turns out to be signed in.
        AuthUnknown() => location == Routes.splash ? null : Routes.splash,

        // Sign-up is reachable without a session too, or a new user could
        // never get past login.
        AuthSignedOut() =>
          Routes.signedOutAllowed.contains(location) ? null : Routes.login,

        AuthSignedIn(:final session) => _signedInRedirect(
          ref,
          session,
          location,
        ),
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.tenant,
        builder: (context, state) => const TenantHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const TenantProfileScreen(),
          ),
        ],
      ),
      // Three sections, each with its own navigation stack. Pushing a
      // property, a unit and a bed, switching to Tenants and coming back
      // returns to the bed — which is what a tab bar is for.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => LandlordShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.landlordHome,
                builder: (context, state) => const LandlordHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.properties,
                builder: (context, state) => const PropertyListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreatePropertyScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PropertyDetailScreen(
                      propertyId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'units/new',
                        builder: (context, state) => CreateUnitScreen(
                          propertyId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => CreatePropertyScreen(
                          propertyId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        // Declared after units/new, which would otherwise match with
                        // unitId = "new".
                        path: 'units/:unitId/edit',
                        builder: (context, state) => CreateUnitScreen(
                          propertyId: state.pathParameters['id']!,
                          unitId: state.pathParameters['unitId'],
                        ),
                      ),
                      GoRoute(
                        path: 'units/:unitId/utilities',
                        builder: (context, state) => UnitUtilitiesScreen(
                          propertyId: state.pathParameters['id']!,
                          unitId: state.pathParameters['unitId']!,
                        ),
                      ),
                      GoRoute(
                        // Last of the unit routes: 'units/:unitId' would otherwise
                        // swallow the more specific ones above it.
                        path: 'units/:unitId',
                        builder: (context, state) => UnitDetailScreen(
                          propertyId: state.pathParameters['id']!,
                          unitId: state.pathParameters['unitId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenants,
                builder: (context, state) => const TenantsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.noProfile,
        builder: (context, state) => const NoProfileScreen(),
      ),
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
    LizmoProfile.landlord => Routes.landlordHome,
    LizmoProfile.tenant => Routes.tenant,
    // ADMIN is not a role this app serves; platform admins use the web console.
    LizmoProfile.admin || null => Routes.noProfile,
  };

  // Signed in but still on an entry screen: move along. Registering signs the
  // user straight in, so /register belongs here too — leaving it out stranded
  // new users on the form they had just submitted.
  if (location == Routes.splash || Routes.signedOutAllowed.contains(location)) {
    return home;
  }

  // Prefix, not equality: /landlord/properties/new is as much a landlord
  // screen as /landlord, and matching exactly left every sub-route unguarded.
  if (location.startsWith(Routes.landlord) && !session.isLandlord) return home;
  if (location.startsWith(Routes.tenant) && !session.isTenant) return home;

  return null;
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
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  child: Text(
                    'Sign out',
                    style: LizmoType.rowName.copyWith(
                      color: LizmoColors.teal900,
                    ),
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
                Text(
                  "That page doesn't exist.",
                  textAlign: TextAlign.center,
                  style: LizmoType.rowName,
                ),
                const SizedBox(height: 8),
                Text(
                  location,
                  textAlign: TextAlign.center,
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go(Routes.splash),
                  child: Text(
                    'Go back',
                    style: LizmoType.rowName.copyWith(
                      color: LizmoColors.teal900,
                    ),
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
