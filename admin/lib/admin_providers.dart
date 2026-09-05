import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Everything the console reads, in one place.
///
/// Overridden wholesale in tests, so no screen reaches the network to prove it
/// renders a list.
final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.watch(apiClientProvider));
});

/// The landlords list — the console's home screen.
final landlordsProvider = FutureProvider<List<LandlordSummary>>((ref) async {
  return await ref.watch(adminApiProvider).listLandlords() ?? const [];
});

/// One landlord and their properties.
///
/// Keyed by id rather than held as a single "selected landlord", so moving
/// between two of them cannot show the first one's properties under the
/// second one's name while the request is in flight.
final landlordProvider =
    FutureProvider.family<LandlordDetail?, String>((ref, id) async {
  return ref.watch(adminApiProvider).getLandlord(id);
});

/// Invitations sent and not yet taken up, expired ones included.
final invitationsProvider = FutureProvider<List<PendingInvitation>>((ref) async {
  return await ref.watch(adminApiProvider).listInvitations() ?? const [];
});

/// What one invitation link is for.
///
/// Public: the person following it has no account yet, or has one and is not
/// signed in on the device the email opened.
final invitationDetailsProvider =
    FutureProvider.family<InvitationDetailsResponse?, String>((ref, token) async {
  return ref.watch(signingUpApiProvider).getInvitation(token);
});
