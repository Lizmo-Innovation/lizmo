import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

import '../router.dart';

/// Where tapping a notification takes somebody.
///
/// A notification is news about something, and news that cannot be followed
/// is news people learn to clear without reading. Until this existed, tapping
/// one only marked it read -- a landlord told a tenant had paid then had to
/// go and find the tenant themselves.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// Something to look at, opened inside the tab that is showing, so Back
/// returns to the notifications.
final class OpenDetail extends NotificationDestination {
  const OpenDetail(this.detail);

  /// A [Detail] path.
  final String detail;
}

/// One of the tenant's tabs. A tab rather than a detail, because a tenant's
/// rent and their place are each a tab of their own already.
final class SwitchTab extends NotificationDestination {
  const SwitchTab(this.tab);

  /// A tab root from [Routes].
  final String tab;
}

/// Decided by who is looking as well as by what it is about: the same kind of
/// payment notification sends a tenant to their rent and a landlord to the
/// tenant.
///
/// Null when there is nowhere sensible to go, which the feed shows by giving
/// the row no chevron.
NotificationDestination? destinationOf(
  NotificationResponse notification,
  LizmoProfile? persona,
) {
  final type = notification.type?.toJson();

  return switch (persona) {
    LizmoProfile.landlord => _forLandlord(type, notification),
    LizmoProfile.tenant => _forTenant(type),
    _ => null,
  };
}

NotificationDestination? _forLandlord(
  String? type,
  NotificationResponse notification,
) {
  // A request is answered on its property, among any others for it.
  if (type == 'REQUEST_RECEIVED') {
    final property = notification.propertyId;
    return property == null ? null : OpenDetail(Detail.requests(property));
  }

  // Anything else about a tenancy opens the tenant, which is where its rent
  // and its payments -- and the Confirm button -- are.
  final lease = notification.leaseId;
  return lease == null ? null : OpenDetail(Detail.tenancy(lease));
}

NotificationDestination? _forTenant(String? type) => switch (type) {
      // A decline or a lost bed goes to My place too: with no tenancy, that
      // tab is where somebody looks for the next one.
      'REQUEST_ACCEPTED' ||
      'REQUEST_DECLINED' ||
      'REQUEST_SUPERSEDED' ||
      'LEASE_ENDED' =>
        const SwitchTab(Routes.tenantPlace),
      'RENT_DUE_REMINDER' ||
      'RENT_OVERDUE' ||
      'PAYMENT_CONFIRMED' ||
      'PAYMENT_REJECTED' =>
        const SwitchTab(Routes.tenantPayments),
      _ => null,
    };
