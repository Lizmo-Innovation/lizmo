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

final tenantDocumentsApiProvider = Provider<TenantDocumentsApi>((ref) {
  return TenantDocumentsApi(ref.watch(apiClientProvider));
});

/// The signed-in tenant's own photographs.
///
/// Each carries a presigned URL good for minutes, so this is deliberately
/// autoDispose and never cached beyond the screen: a URL kept past its life
/// shows a broken image, and one kept in a longer-lived provider would be
/// handed to a widget that outlived it.
final myTenantDocumentsProvider =
    FutureProvider.autoDispose<List<TenantDocumentResponse>>((ref) async {
  try {
    return await ref.watch(tenantDocumentsApiProvider).listMyTenantDocuments() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

final findingAPlaceApiProvider = Provider<FindingAPlaceApi>((ref) {
  return FindingAPlaceApi(ref.watch(apiClientProvider));
});

final askingForARoomApiProvider = Provider<AskingForARoomApi>((ref) {
  return AskingForARoomApi(ref.watch(apiClientProvider));
});

/// A property found by the code on its gate, with what is free inside it.
///
/// Keyed by the code rather than an id, because the code is all a tenant has:
/// they are standing in front of a building they have no relationship to.
///
/// autoDispose so that reopening a place asks again — a bed listed as free two
/// minutes ago may not be, and this screen is the one somebody acts on.
final propertyByCodeProvider = FutureProvider.autoDispose
    .family<PropertyByCodeResponse, String>((ref, code) async {
  try {
    final property =
        await ref.watch(findingAPlaceApiProvider).findPropertyByCode(code);
    if (property == null) {
      throw const ApiFailure(
        code: 'NOT_FOUND',
        message: 'No property uses that code.',
      );
    }
    return property;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// What this tenant has asked for, newest first.
final myRentalRequestsProvider =
    FutureProvider.autoDispose<List<RentalRequestResponse>>((ref) async {
  try {
    return await ref.watch(askingForARoomApiProvider).listMyRentalRequests() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
