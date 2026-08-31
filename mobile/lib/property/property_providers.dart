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
