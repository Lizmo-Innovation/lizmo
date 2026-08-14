import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';


final activeRoleProvider =
    NotifierProvider<ActiveRoleController, LizmoProfile?>(ActiveRoleController.new);

/// Which hat the user is currently wearing.
///
/// Separate from [Session.profiles], which says what they *may* be. A caretaker
/// who also rents a bedspace holds both and needs to move between them, so the
/// active role is state rather than a property of the account.
class ActiveRoleController extends Notifier<LizmoProfile?> {
  @override
  LizmoProfile? build() {
    // Watching auth resets the role on sign-out, so the next user never
    // inherits the previous one's view.
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return null;

    return defaultFor(auth.session.profiles);
  }

  /// Landlord wins when both are held: it is the role with management actions,
  /// and a landlord who also rents is the commoner case than the reverse.
  ///
  /// TODO: remember the last choice per user instead of defaulting every launch.
  static LizmoProfile? defaultFor(Set<LizmoProfile> profiles) {
    if (profiles.contains(LizmoProfile.landlord)) return LizmoProfile.landlord;
    if (profiles.contains(LizmoProfile.tenant)) return LizmoProfile.tenant;
    return null;
  }

  void switchTo(LizmoProfile role) {
    state = role;
  }
}
