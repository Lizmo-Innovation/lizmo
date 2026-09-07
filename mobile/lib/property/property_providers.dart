import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

final propertiesApiProvider = Provider<PropertiesApi>((ref) {
  return PropertiesApi(ref.watch(apiClientProvider));
});

final unitsApiProvider = Provider<UnitsApi>((ref) {
  return UnitsApi(ref.watch(apiClientProvider));
});

/// The signed-in landlord's properties.
///
/// Errors are normalised to [ApiFailure] here rather than in the widget, so
/// every screen shows the backend's message and can branch on its code —
/// including telling "no connection" apart from "your account is locked".
///
/// autoDispose so the list is refetched on return rather than showing a stale
/// count after a unit is added elsewhere.
final propertiesProvider =
    FutureProvider.autoDispose<List<PropertyResponse>>((ref) async {
  try {
    return await ref.watch(propertiesApiProvider).listProperties() ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// One property, fetched by id.
///
/// Used by the edit form, which may be reached by deep link with nothing
/// loaded — so it fetches rather than digging through [propertiesProvider],
/// which might be empty or stale.
final propertyProvider =
    FutureProvider.autoDispose.family<PropertyResponse, String>((ref, id) async {
  try {
    final property = await ref.watch(propertiesApiProvider).getProperty(id);
    if (property == null) {
      throw const ApiFailure(code: 'NOT_FOUND', message: 'No such property.');
    }
    return property;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Units within one property.
final unitsProvider =
    FutureProvider.autoDispose.family<List<UnitResponse>, String>((ref, propertyId) async {
  try {
    return await ref.watch(propertiesApiProvider).listUnits(propertyId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// One unit, fetched by id.
///
/// The edit form needs the current values, and may be reached by deep link with
/// no list loaded.
final unitProvider =
    FutureProvider.autoDispose.family<UnitResponse, String>((ref, id) async {
  try {
    final unit = await ref.watch(unitsApiProvider).getUnit(id);
    if (unit == null) {
      throw const ApiFailure(code: 'NOT_FOUND', message: 'No such unit.');
    }
    return unit;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Beds within one unit. Only meaningful for BEDSPACE units — the API refuses
/// beds on a whole unit, so callers should not ask.
final bedsProvider =
    FutureProvider.autoDispose.family<List<BedResponse>, String>((ref, unitId) async {
  try {
    return await ref.watch(unitsApiProvider).listBeds(unitId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// A unit's utility settings: how they are billed, and every kind's amount —
/// including kinds the landlord has never set up.
final utilitiesProvider =
    FutureProvider.autoDispose.family<UtilitiesResponse, String>((ref, unitId) async {
  try {
    final response = await ref.watch(unitsApiProvider).listUtilities(unitId);
    if (response == null) {
      throw const ApiFailure(code: 'NOT_FOUND', message: 'No such unit.');
    }
    return response;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

final requestsToAnswerApiProvider = Provider<RequestsToAnswerApi>((ref) {
  return RequestsToAnswerApi(ref.watch(apiClientProvider));
});

final leasesApiProvider = Provider<LeasesApi>((ref) {
  return LeasesApi(ref.watch(apiClientProvider));
});

/// Who has asked about one property and is still waiting.
///
/// autoDispose: a landlord coming back to this screen wants the queue as it is
/// now, not as it was when they last opened it — somebody may have withdrawn.
final pendingRequestsProvider = FutureProvider.autoDispose
    .family<List<RentalRequestForLandlord>, String>((ref, propertyId) async {
  try {
    return await ref
            .watch(requestsToAnswerApiProvider)
            .listRentalRequestsForProperty(propertyId, pendingOnly: true) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Who is currently living in one property.
final propertyLeasesProvider = FutureProvider.autoDispose
    .family<List<LeaseResponse>, String>((ref, propertyId) async {
  try {
    return await ref.watch(leasesApiProvider).listLeasesForProperty(propertyId) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Everyone renting from this landlord, across every property they own.
///
/// One request rather than one per property: the Tenants tab is the first
/// thing many landlords open, and a request count that grows with the
/// portfolio is a screen that gets slower the more successful they are.
final myTenantsProvider =
    FutureProvider.autoDispose<List<LeaseResponse>>((ref) async {
  try {
    return await ref.watch(leasesApiProvider).listMyTenants() ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The person living under one lease, in full.
///
/// Keyed by lease, never by tenant — the API answers "who is living in my
/// room", so there is no id a screen could hold that opens a person.
///
/// autoDispose, and deliberately not cached: this is the most sensitive record
/// the app shows a landlord, and it should leave memory when the screen does.
final leaseTenantProvider = FutureProvider.autoDispose
    .family<TenantForLandlord, String>((ref, leaseId) async {
  try {
    final tenant = await ref.watch(leasesApiProvider).getTenantForLease(leaseId);
    if (tenant == null) {
      throw const ApiFailure(
        code: 'NOT_FOUND',
        message: 'That tenancy has ended.',
      );
    }
    return tenant;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The ID photographs of whoever holds this lease.
///
/// Each URL is presigned and good for minutes, which is the reason this is
/// autoDispose: one kept past its life shows a broken image.
final leaseTenantDocumentsProvider = FutureProvider.autoDispose
    .family<List<TenantDocumentResponse>, String>((ref, leaseId) async {
  try {
    return await ref
            .watch(leasesApiProvider)
            .listTenantDocumentsForLease(leaseId) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The paperwork filed against one lease, as the landlord sees it.
///
/// Every URL is presigned and short-lived, which is why this is autoDispose:
/// one kept past its life shows a broken link.
final leaseDocumentsProvider = FutureProvider.autoDispose
    .family<List<LeaseDocumentResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(leasesApiProvider).listLeaseDocuments(leaseId) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The same paperwork as the tenant sees it: only what was shared.
final myLeaseDocumentsProvider = FutureProvider.autoDispose
    .family<List<LeaseDocumentResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(leasesApiProvider).listMyLeaseDocuments(leaseId) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// One lease from the landlord's own list, by id.
///
/// Derived from [myTenantsProvider] rather than fetched: the list is already
/// the answer to "which tenancies are mine", and a second endpoint returning
/// one of them would be a second place for the same permission rule to live.
///
/// Null while the list is loading, or when the tenancy has ended — the list
/// carries active leases only, which is the same window the tenant detail
/// screen itself is readable in.
final landlordLeaseProvider = Provider.autoDispose
    .family<LeaseResponse?, String>((ref, leaseId) {
  final tenants = ref.watch(myTenantsProvider).valueOrNull;
  if (tenants == null) return null;
  for (final lease in tenants) {
    if (lease.id == leaseId) return lease;
  }
  return null;
});

final rentApiProvider = Provider<RentApi>((ref) {
  return RentApi(ref.watch(apiClientProvider));
});

/// The months of rent on one tenancy, as the landlord sees them.
///
/// Reading this is what brings the schedule up to date: months are written
/// when somebody looks rather than by a scheduled job, so an invalidate here
/// is also a catch-up.
final leaseBillingProvider = FutureProvider.autoDispose
    .family<List<BillingPeriodResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(rentApiProvider).listLeaseBilling(leaseId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The same months, as the tenant living under them sees them.
final myBillingProvider = FutureProvider.autoDispose
    .family<List<BillingPeriodResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(rentApiProvider).listMyBilling(leaseId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Payments recorded against one tenancy, as the landlord sees them.
final leasePaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(rentApiProvider).listLeasePayments(leaseId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The same payments as the tenant sees them, including anything still waiting
/// and anything the landlord refused.
final myPaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentResponse>, String>((ref, leaseId) async {
  try {
    return await ref.watch(rentApiProvider).listMyPayments(leaseId) ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
