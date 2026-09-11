import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'auth/active_role.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_property_screen.dart';
import 'screens/create_unit_screen.dart';
import 'screens/property_detail_screen.dart';
import 'screens/property_share_screen.dart';
import 'screens/rental_requests_screen.dart';
import 'screens/rent_roll_screen.dart';
import 'screens/landlord_home_screen.dart';
import 'screens/landlord_shell.dart';
import 'screens/property_list_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/tenant_detail_screen.dart';
import 'screens/tenants_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/find_property_screen.dart';
import 'screens/property_by_code_screen.dart';
import 'screens/scan_code_screen.dart';
import 'screens/tenant_home_screen.dart';
import 'screens/tenant_profile_screen.dart';
import 'screens/unit_detail_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/lizmo_billing_screen.dart';
import 'screens/maintenance_inbox_screen.dart';
import 'screens/maintenance_report_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/my_place_screen.dart';
import 'screens/tenant_payments_screen.dart';
import 'screens/tenant_shell.dart';
import 'screens/unit_utilities_screen.dart';

/// Route paths, named so a typo is a compile error rather than a blank screen.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  /// The tenant section as a whole. Every guard matches on this prefix, so
  /// the tabs changed nothing about who may see what.
  static const tenant = '/tenant';

  /// What is waiting on the tenant. The section's own root.
  static const tenantHome = '/tenant/home';

  /// Where they live, or how to find somewhere.
  static const tenantPlace = '/tenant/place';

  static const tenantPayments = '/tenant/payments';
  static const tenantMaintenance = '/tenant/maintenance';

  /// The tenant's own profile.
  ///
  /// A form, so it covers the tabs rather than opening inside one. It lived
  /// under Home, so opening it from the account sheet on any other tab threw
  /// the tenant across to Home to fill it in.
  static const tenantProfile = '/tenant/profile';

  /// Closing the account.
  ///
  /// Outside both sections, because both sides have an account to close.
  /// Under /tenant, the tenant guard sent a landlord-only account straight
  /// back to its dashboard.
  static const deleteAccount = '/delete-account';

  /// Where a tenant starts looking for somewhere to live. Under My place,
  /// because that is the tab the question belongs to.
  static const tenantFind = '/tenant/place/find';

  /// The camera. Its own route rather than a mode of the find screen, so
  /// backing out of it lands where the tenant started.
  static const tenantScan = '/tenant/place/scan';

  /// A property reached by the code on its gate. The code is in the path
  /// rather than a query, because it identifies the thing being looked at.
  static String propertyByCode(String code) => '/tenant/place/find/$code';

  /// Kept for the old names, which several screens still use.
  static const findProperty = tenantFind;
  static const scanCode = tenantScan;

  /// The landlord section as a whole. Redirects to [landlordHome]; every
  /// guard still matches on this prefix, so the tabs changed nothing about
  /// who may see what.
  static const landlord = '/landlord';

  static const landlordHome = '/landlord/home';

  /// Rent month by month, across every property.
  static const rent = '/landlord/rent';

  static const properties = '/landlord/properties';
  static const tenants = '/landlord/tenants';

  /// Everything tenants have reported, across every property.
  static const maintenanceInbox = '/landlord/maintenance';

  // Forms. Each covers the tabs until it is saved or abandoned: a half-filled
  // form left behind in another tab is one nobody comes back to. Things to
  // look at are not here -- they open inside the current tab. See [Detail].

  static const propertyNew = '/landlord/properties/new';
  static String propertyEdit(String id) => '/landlord/property/$id/edit';
  static String unitNew(String propertyId) =>
      '/landlord/property/$propertyId/units/new';
  static String unitEdit(String propertyId, String unitId) =>
      '/landlord/property/$propertyId/unit/$unitId/edit';
  static String unitUtilities(String propertyId, String unitId) =>
      '/landlord/property/$propertyId/unit/$unitId/utilities';

  static const forgotPassword = '/forgot-password';

  static const noProfile = '/no-profile';

  /// Reachable without a session. Anything else redirects to login.
  static const signedOutAllowed = {login, register, forgotPassword};

  /// The root of every tab, on both sides.
  static const tabRoots = [
    landlordHome,
    rent,
    properties,
    tenants,
    maintenanceInbox,
    tenantHome,
    tenantPlace,
    tenantPayments,
    tenantMaintenance,
  ];

  /// The tab [location] sits inside.
  static String tabRootOf(String location) {
    for (final root in tabRoots) {
      if (location == root || location.startsWith('$root/')) return root;
    }
    return location.startsWith(tenant) ? tenantHome : landlordHome;
  }
}

/// Things to look at, as paths relative to whichever tab is showing.
///
/// The same screen is reachable from several tabs -- a tenant from Today, from
/// Tenants, and from a notification -- and it opens inside the tab you were
/// in, with that tab still lit and Back returning to where you started. Each
/// used to live in one tab only, so reaching it from anywhere else threw you
/// into that tab, and Back took you to a list you had never looked at.
///
/// Open one with [OpenInTab.openInTab] rather than a hand-built path.
abstract final class Detail {
  static const notifications = 'notifications';
  static String tenancy(String leaseId) => 'lease/$leaseId';
  static String property(String id) => 'property/$id';
  static String requests(String propertyId) => 'property/$propertyId/requests';
  static String share(String propertyId) => 'property/$propertyId/share';
  static String unit(String propertyId, String unitId) =>
      'property/$propertyId/unit/$unitId';
  static String maintenance(String reportId) => 'maintenance/$reportId';

  /// What the landlord owes Lizmo. Reached from Today and the account menu.
  static const lizmoBilling = 'lizmo-billing';
}

extension OpenInTab on BuildContext {
  /// Opens [detail] inside the tab that is showing.
  ///
  /// The tab is read from the router rather than from this widget's route, so
  /// a card deep inside a screen needs no idea where its screen was mounted.
  Future<T?> openInTab<T extends Object?>(String detail) {
    final here = GoRouter.of(this).routerDelegate.currentConfiguration.uri.path;
    return push<T>('${Routes.tabRootOf(here)}/$detail');
  }
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
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Forms and tasks. Top-level rather than inside a tab, so each is pushed
      // over whichever tab is showing and covers it, tab bar and all, until it
      // is finished or abandoned.
      GoRoute(
        path: Routes.tenantProfile,
        builder: (context, state) => const TenantProfileScreen(),
      ),
      GoRoute(
        path: Routes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: Routes.propertyNew,
        builder: (context, state) => const CreatePropertyScreen(),
      ),
      GoRoute(
        path: '/landlord/property/:propertyId/edit',
        builder: (context, state) => CreatePropertyScreen(
          propertyId: state.pathParameters['propertyId'],
        ),
      ),
      GoRoute(
        path: '/landlord/property/:propertyId/units/new',
        builder: (context, state) => CreateUnitScreen(
          propertyId: state.pathParameters['propertyId']!,
        ),
      ),
      GoRoute(
        path: '/landlord/property/:propertyId/unit/:unitId/edit',
        builder: (context, state) => CreateUnitScreen(
          propertyId: state.pathParameters['propertyId']!,
          unitId: state.pathParameters['unitId'],
        ),
      ),
      GoRoute(
        path: '/landlord/property/:propertyId/unit/:unitId/utilities',
        builder: (context, state) => UnitUtilitiesScreen(
          propertyId: state.pathParameters['propertyId']!,
          unitId: state.pathParameters['unitId']!,
        ),
      ),

      // Four sections, each with its own navigation stack. What needs me, my
      // money, my room, my problems — organised around what a tenant thinks
      // about rather than around what the app can currently do. In the same
      // order as the tabs: a branch's position is its tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TenantShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenantHome,
                builder: (context, state) => const TenantHomeScreen(),
                routes: _tenantDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenantPayments,
                builder: (context, state) => const TenantPaymentsScreen(),
                routes: _tenantDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenantPlace,
                builder: (context, state) => const MyPlaceScreen(),
                routes: [
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) => const ScanCodeScreen(),
                  ),
                  GoRoute(
                    path: 'find',
                    builder: (context, state) => const FindPropertyScreen(),
                    routes: [
                      GoRoute(
                        path: ':code',
                        builder: (context, state) => PropertyByCodeScreen(
                          code: state.pathParameters['code']!,
                        ),
                      ),
                    ],
                  ),
                  ..._tenantDetails(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenantMaintenance,
                builder: (context, state) => const MaintenanceScreen(),
                routes: _tenantDetails(),
              ),
            ],
          ),
        ],
      ),
      // Five sections, each with its own navigation stack. Pushing a
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
                routes: _landlordDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.rent,
                builder: (context, state) => const RentRollScreen(),
                routes: _landlordDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.properties,
                builder: (context, state) => const PropertyListScreen(),
                routes: _landlordDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tenants,
                builder: (context, state) => const TenantsScreen(),
                routes: _landlordDetails(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.maintenanceInbox,
                builder: (context, state) => const MaintenanceInboxScreen(),
                routes: _landlordDetails(),
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

/// What a tenant can look at from any of their tabs, mounted under each.
List<RouteBase> _tenantDetails() => [
      GoRoute(
        path: Detail.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ];

/// What a landlord can look at from any of their tabs, mounted under each.
///
/// So the same tenant or property opens inside whichever tab it was reached
/// from. The paths mirror [Detail], which is how screens ask for them.
List<RouteBase> _landlordDetails() => [
      GoRoute(
        path: Detail.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Detail.lizmoBilling,
        builder: (context, state) => const LizmoBillingScreen(),
      ),
      GoRoute(
        path: 'maintenance/:reportId',
        builder: (context, state) => MaintenanceReportScreen(
          reportId: state.pathParameters['reportId']!,
        ),
      ),
      GoRoute(
        path: 'lease/:leaseId',
        builder: (context, state) => TenantDetailScreen(
          leaseId: state.pathParameters['leaseId']!,
        ),
      ),
      GoRoute(
        path: 'property/:propertyId',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['propertyId']!,
        ),
        routes: [
          GoRoute(
            path: 'requests',
            builder: (context, state) => RentalRequestsScreen(
              propertyId: state.pathParameters['propertyId']!,
            ),
          ),
          GoRoute(
            path: 'share',
            builder: (context, state) => PropertyShareScreen(
              propertyId: state.pathParameters['propertyId']!,
            ),
          ),
          GoRoute(
            path: 'unit/:unitId',
            builder: (context, state) => UnitDetailScreen(
              propertyId: state.pathParameters['propertyId']!,
              unitId: state.pathParameters['unitId']!,
            ),
          ),
        ],
      ),
    ];

/// Where a signed-in user belongs.
///
/// Guards against reaching the wrong role's screen by URL: a tenant typing
/// /landlord is redirected home rather than shown the rent roll, which lists
/// every tenant in the property.
String? _signedInRedirect(Ref ref, Session session, String location) {
  final home = switch (ref.read(activeRoleProvider)) {
    LizmoProfile.landlord => Routes.landlordHome,
    LizmoProfile.tenant => Routes.tenantHome,
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
