import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

final tenantProfileApiProvider = Provider<TenantProfileApi>((ref) {
  return TenantProfileApi(ref.watch(apiClientProvider));
});

/// The signed-in tenant's own profile.
///
/// No id: the endpoint is addressed as "me" and serves the caller theirs. That
/// is the point — this is the most personal data the app holds, so there is no
/// id a screen could pass, right or wrong.
///
/// Registration always creates a profile, so a null response is a fault rather
/// than a new tenant.
final myTenantProfileProvider =
    FutureProvider.autoDispose<TenantProfileResponse>((ref) async {
  try {
    final profile = await ref.watch(tenantProfileApiProvider).getMyTenantProfile();
    if (profile == null) {
      throw const ApiFailure(
        code: 'NOT_FOUND',
        message: 'This account has no tenant profile.',
      );
    }
    return profile;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
