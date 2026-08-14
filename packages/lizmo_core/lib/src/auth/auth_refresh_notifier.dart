import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_state.dart';

/// Bridges Riverpod's auth state to go_router's `refreshListenable`.
///
/// go_router only re-evaluates its redirect when told to. Without this, a
/// session ending mid-use — a rejected refresh, or signing out — would leave
/// the user sitting on a screen they are no longer entitled to see until they
/// happened to navigate.
///
/// Notifies on *transitions* rather than every emission, so an unchanged state
/// does not trigger redundant redirect passes.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    _last = ref.read(authControllerProvider);

    _subscription = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (_isSameKind(_last, next)) return;
        _last = next;
        notifyListeners();
      },
      fireImmediately: false,
    );
  }

  late AuthState _last;
  late final ProviderSubscription<AuthState> _subscription;

  /// Only the *kind* of state matters for routing. A refreshed session is still
  /// AuthSignedIn and should not bounce the user to a different route.
  static bool _isSameKind(AuthState a, AuthState b) =>
      (a is AuthUnknown && b is AuthUnknown) ||
      (a is AuthSignedOut && b is AuthSignedOut) ||
      (a is AuthSignedIn && b is AuthSignedIn);

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
