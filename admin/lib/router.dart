import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'screens/accept_invitation_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/invitations_screen.dart';
import 'screens/landlord_detail_screen.dart';
import 'screens/landlords_screen.dart';
import 'screens/platform_payments_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const noAccess = '/no-access';

  /// Where an invited landlord sets their password.
  ///
  /// Public, and outside every gate: the person following this link is not
  /// staff, usually has no account at all, and must never be shown the console
  /// login — which is what happened before this route existed.
  static const invite = '/invite';

  /// Where an admin lands. Landlords rather than the payment queue: payments
  /// are a task, landlords are the subject.
  static const landlords = '/landlords';
  static const payments = '/payments';
  static const invitations = '/invitations';

  /// Everything an admin may be on. Anything else sends them home, which is
  /// how a typed URL, a stale bookmark and a signed-in visitor on /login all
  /// end up somewhere sensible.
  static const console = {landlords, payments, invitations};

  /// Whether a location belongs to the console.
  ///
  /// A prefix test rather than set membership, because one landlord's page is
  /// `/landlords/<id>` — matching exactly would bounce an admin home the moment
  /// they opened one.
  static bool insideConsole(String location) =>
      console.contains(location) || location.startsWith('$landlords/');
}

/// Matched as a prefix, since the token is part of the path.
const invitePrefix = Routes.invite;

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Before anything else: an invited landlord is not a visitor to the
      // console, and none of the rules below are about them.
      if (location.startsWith('$invitePrefix/')) return null;

      return switch (auth) {
        AuthUnknown() => location == Routes.splash ? null : Routes.splash,

        AuthSignedOut() => location == Routes.login ? null : Routes.login,

        // Signing in is not sufficient here. Only internal Lizmo staff reach
        // the console; a landlord with valid credentials is sent to /no-access.
        // This runs on every navigation, so a URL typed straight into the
        // address bar is checked the same as a tap.
        AuthSignedIn(:final session) => session.isPlatformAdmin
            ? (Routes.insideConsole(location) ? null : Routes.landlords)
            : (location == Routes.noAccess ? null : Routes.noAccess),
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const AdminLoginScreen()),
      GoRoute(
        path: '${Routes.invite}/:token',
        pageBuilder: (context, state) => NoTransitionPage(
          child: AcceptInvitationScreen(token: state.pathParameters['token']!),
        ),
      ),
      // No transition between console screens.
      //
      // go_router animates a route change by default, which is right on a
      // phone where a push means "you have gone somewhere". Here the rail is
      // always on screen and only the panel beside it changes: a fade makes
      // moving between sections feel like waiting, and doing it twenty times
      // an afternoon is the whole job.
      GoRoute(
        path: Routes.landlords,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LandlordsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: LandlordDetailScreen(landlordId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.payments,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PlatformPaymentsScreen()),
      ),
      GoRoute(
        path: Routes.invitations,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: InvitationsScreen()),
      ),
      GoRoute(path: Routes.noAccess, builder: (context, state) => const NoAccessScreen()),
    ],
    errorBuilder: (_, state) => NotFoundScreen(location: state.uri.toString()),
  );
});

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

/// Shown when a valid account is not a platform admin.
///
/// Says plainly that the account lacks access rather than implying the
/// credentials were wrong — the person is signed in, just not staff.
class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This account is not a Lizmo admin.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowName.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'The console is for Lizmo staff. Landlord and tenant accounts '
                  'use the Lizmo app instead.',
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

/// Reachable on web by editing the address bar, so it needs to exist.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("That page doesn't exist.", style: LizmoType.rowName),
            const SizedBox(height: 8),
            Text(location, style: LizmoType.rowSub),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go(Routes.splash),
              child: Text('Go back',
                  style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
            ),
          ],
        ),
      ),
    );
  }
}
