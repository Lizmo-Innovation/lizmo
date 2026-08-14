/// Everything both Lizmo clients need to talk to the API as a signed-in user.
///
/// Shared rather than copied: the token refresh path in particular is
/// security-sensitive and subtle (single-flight, body replay, auth-endpoint
/// exclusion), and two copies of it would drift.
///
/// What belongs here: session handling, the API client and the error contract.
/// What does not: anything role-specific. The mobile app's tenant/landlord
/// switching and the admin console's platform-admin gate live in their own
/// apps, because they are different products.
library;

export 'src/api/api_config.dart';
export 'src/api/api_failure.dart';
export 'src/api/authenticated_client.dart';
export 'src/auth/auth_controller.dart';
export 'src/auth/auth_refresh_notifier.dart';
export 'src/auth/auth_state.dart';
export 'src/auth/token_store.dart';
