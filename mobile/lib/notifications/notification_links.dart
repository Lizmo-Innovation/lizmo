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

/// A screen that lives above the tabs rather than inside one.
///
/// A conversation is the case: the same screen serves both sides, so it
/// cannot belong to a landlord tab or a tenant one.
final class OpenScreen extends NotificationDestination {
  const OpenScreen(this.path);

  /// A full path from [Routes].
  final String path;
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
    LizmoProfile.tenant => _forTenant(type, notification),
    _ => null,
  };
}

NotificationDestination? _forLandlord(
  String? type,
  NotificationResponse notification,
) {
  // Anything about a Lizmo invoice opens the billing screen, where it is paid.
  if (notification.relatedEntityType?.toJson() == 'PLATFORM_INVOICE') {
    return const OpenDetail(Detail.lizmoBilling);
  }

  // A report opens itself, whichever step of it the news was about.
  if (notification.relatedEntityType?.toJson() == 'MAINTENANCE_REQUEST') {
    final report = notification.relatedEntityId;
    return report == null ? null : OpenDetail(Detail.maintenance(report));
  }

  // Anything about a conversation opens that conversation, from either side:
  // it is where both the answer and the next thing to say live.
  if (notification.relatedEntityType?.toJson() == 'INQUIRY') {
    final thread = notification.relatedEntityId;
    return thread == null ? null : OpenScreen(Routes.inquiry(thread));
  }

  // Anything else about a tenancy opens the tenant, which is where its rent
  // and its payments -- and the Confirm button -- are.
  final lease = notification.leaseId;
  return lease == null ? null : OpenDetail(Detail.tenancy(lease));
}

NotificationDestination? _forTenant(
  String? type,
  NotificationResponse notification,
) {
  // Anything about a conversation opens it -- a landlord's reply, a message
  // from the landlord they rent from, or "worth asking them" about a payment.
  // Routed by type alone, a tenant tapping "Your landlord sent a message"
  // went nowhere.
  if (notification.relatedEntityType?.toJson() == 'INQUIRY') {
    final thread = notification.relatedEntityId;
    if (thread != null) return OpenScreen(Routes.inquiry(thread));
  }
  return _forTenantByType(type);
}

NotificationDestination? _forTenantByType(String? type) => switch (type) {
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
      'PAYMENT_REJECTED' ||
      // Without a conversation to point at, the payment it is about.
      'PAYMENT_STILL_UNCONFIRMED' =>
        const SwitchTab(Routes.tenantPayments),
      'MAINTENANCE_STATUS_CHANGED' => const SwitchTab(Routes.tenantMaintenance),
      // Where the lease is, with its end date and a way to ask about staying.
      'LEASE_EXPIRING' => const SwitchTab(Routes.tenantPlace),
      _ => null,
    };
