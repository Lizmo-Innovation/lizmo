import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/notifications/notification_links.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

NotificationResponse _news(
  NotificationResponseTypeEnum type, {
  String? leaseId,
  String? propertyId,
}) =>
    NotificationResponse(
      id: 'n1',
      type: type,
      leaseId: leaseId,
      propertyId: propertyId,
    );

/// Where tapping a notification goes, decided without a widget in sight.
///
/// Tapping one used to only mark it read, which left a landlord told "a tenant
/// says they have paid" with no way to reach the tenant.
void main() {
  group('a landlord', () {
    test('somebody asking opens the requests for that property', () {
      final to = destinationOf(
        _news(NotificationResponseTypeEnum.REQUEST_RECEIVED, propertyId: 'p1'),
        LizmoProfile.landlord,
      );

      expect(
        to,
        isA<OpenDetail>()
            .having((d) => d.detail, 'detail', Detail.requests('p1')),
      );
    });

    test('a tenant saying they paid opens the tenant', () {
      final to = destinationOf(
        _news(NotificationResponseTypeEnum.PAYMENT_CONFIRMED, leaseId: 'l1'),
        LizmoProfile.landlord,
      );

      expect(
        to,
        isA<OpenDetail>()
            .having((d) => d.detail, 'detail', Detail.tenancy('l1')),
      );
    });

    /// Old rows, or a request since deleted. No chevron beats a dead end.
    test('a request whose property is unknown leads nowhere', () {
      expect(
        destinationOf(
          _news(NotificationResponseTypeEnum.REQUEST_RECEIVED),
          LizmoProfile.landlord,
        ),
        isNull,
      );
    });

    test('news about no tenancy leads nowhere', () {
      expect(
        destinationOf(
          _news(NotificationResponseTypeEnum.NEW_NOTICE_POSTED),
          LizmoProfile.landlord,
        ),
        isNull,
      );
    });
  });

  group('a tenant', () {
    for (final type in [
      NotificationResponseTypeEnum.REQUEST_ACCEPTED,
      NotificationResponseTypeEnum.REQUEST_DECLINED,
      NotificationResponseTypeEnum.REQUEST_SUPERSEDED,
      NotificationResponseTypeEnum.LEASE_ENDED,
    ]) {
      test('${type.toJson()} opens My place', () {
        expect(
          destinationOf(_news(type), LizmoProfile.tenant),
          isA<SwitchTab>().having((d) => d.tab, 'tab', Routes.tenantPlace),
        );
      });
    }

    for (final type in [
      NotificationResponseTypeEnum.RENT_DUE_REMINDER,
      NotificationResponseTypeEnum.RENT_OVERDUE,
      NotificationResponseTypeEnum.PAYMENT_CONFIRMED,
      NotificationResponseTypeEnum.PAYMENT_REJECTED,
    ]) {
      test('${type.toJson()} opens Payments', () {
        expect(
          destinationOf(_news(type, leaseId: 'l1'), LizmoProfile.tenant),
          isA<SwitchTab>().having((d) => d.tab, 'tab', Routes.tenantPayments),
        );
      });
    }

    test('news with nowhere to go leads nowhere', () {
      expect(
        destinationOf(
          _news(NotificationResponseTypeEnum.NEW_NOTICE_POSTED),
          LizmoProfile.tenant,
        ),
        isNull,
      );
    });
  });

  test('an account on neither side is sent nowhere', () {
    expect(
      destinationOf(
        _news(NotificationResponseTypeEnum.PAYMENT_CONFIRMED, leaseId: 'l1'),
        LizmoProfile.admin,
      ),
      isNull,
    );
  });
}
