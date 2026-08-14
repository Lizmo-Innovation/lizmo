import 'package:lizmo_api/api.dart';

/// Which profiles a signed-in user holds.
///
/// Non-exclusive by design: someone can be both, e.g. a caretaker who rents a
/// bedspace from another landlord. The app shell uses this to decide whether to
/// offer role switching at all.
enum LizmoProfile {
  tenant,
  landlord,

  /// Internal Lizmo staff, who verify platform payments. Never held by a
  /// customer, and unrelated to a landlord's own staff.
  admin;

  static LizmoProfile? parse(String raw) => switch (raw.toUpperCase()) {
        'TENANT' => LizmoProfile.tenant,
        'LANDLORD' => LizmoProfile.landlord,
        'ADMIN' => LizmoProfile.admin,
        _ => null, // Forward compatible: a profile this build predates.
      };
}

/// The signed-in user, as far as the client is concerned.
class Session {
  const Session({
    required this.userId,
    required this.name,
    required this.profiles,
    required this.accessToken,
  });

  final String userId;
  final String name;
  final Set<LizmoProfile> profiles;
  final String accessToken;

  bool get isLandlord => profiles.contains(LizmoProfile.landlord);
  bool get isTenant => profiles.contains(LizmoProfile.tenant);

  /// Whether the admin console should let this session in.
  ///
  /// A convenience for the UI, not a security control: the backend checks
  /// platform_admins on every /admin route. This only avoids showing someone a
  /// console where every request would be refused.
  bool get isPlatformAdmin => profiles.contains(LizmoProfile.admin);

  /// Whether the shell should offer a role switcher.
  bool get hasMultipleProfiles => profiles.length > 1;

  static Session fromResponse(AuthResponse response) => Session(
        userId: response.userId ?? '',
        name: response.name ?? '',
        profiles: response.profiles
            .map(LizmoProfile.parse)
            .whereType<LizmoProfile>()
            .toSet(),
        accessToken: response.accessToken ?? '',
      );
}

/// Auth is a small state machine, and the UI needs to tell these apart:
/// [AuthUnknown] shows a splash, [AuthSignedOut] shows login, and only
/// [AuthSignedIn] may show app content.
sealed class AuthState {
  const AuthState();
}

/// Startup, before stored tokens have been checked.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final Session session;
}
