import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/notifications/notification_links.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

NotificationResponse _news(
  NotificationResponseTypeEnum type, {
  String? leaseId,
  String? propertyId,
  NotificationResponseRelatedEntityTypeEnum? entity,
  String? entityId,
}) =>
    NotificationResponse(
      id: 'n1',
      type: type,
      leaseId: leaseId,
      propertyId: propertyId,
      relatedEntityType: entity,
      relatedEntityId: entityId,
    );

/// Where tapping a notification goes, decided without a widget in sight.
///
/// Tapping one used to only mark it read, which left a landlord told "a tenant
/// says they have paid" with no way to reach the tenant.
void main() {
  group('a landlord', () {
    test('somebody asking opens the requests for that property', () {
      final to = destinationOf(
        _news(NotificationResponseTypeEnum.INQUIRY_MESSAGE,
            entity: NotificationResponseRelatedEntityTypeEnum.INQUIRY,
            entityId: 'i1'),
        LizmoProfile.landlord,
      );

      // The conversation itself, from either side: it is where both the
      // answer and the next thing to say live.
      expect(
        to,
        isA<OpenScreen>().having((d) => d.path, 'path', Routes.inquiry('i1')),
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

  group('maintenance', () {
    NotificationResponse aboutReport(NotificationResponseTypeEnum type) =>
        NotificationResponse(
          id: 'n1',
          type: type,
          relatedEntityType:
              NotificationResponseRelatedEntityTypeEnum.MAINTENANCE_REQUEST,
          relatedEntityId: 'm1',
        );

    /// Whichever step the news was about, the landlord opens the report.
    for (final type in [
      NotificationResponseTypeEnum.MAINTENANCE_REPORTED,
      NotificationResponseTypeEnum.MAINTENANCE_STATUS_CHANGED,
    ]) {
      test('${type.toJson()} opens the report for a landlord', () {
        expect(
          destinationOf(aboutReport(type), LizmoProfile.landlord),
          isA<OpenDetail>()
              .having((d) => d.detail, 'detail', Detail.maintenance('m1')),
        );
      });
    }

    test('a change to their report opens Maintenance for a tenant', () {
      expect(
        destinationOf(
          aboutReport(NotificationResponseTypeEnum.MAINTENANCE_STATUS_CHANGED),
          LizmoProfile.tenant,
        ),
        isA<SwitchTab>()
            .having((d) => d.tab, 'tab', Routes.tenantMaintenance),
      );
    });
  });

  /// Whatever happened to an invoice, it is paid from the billing screen.
  test('news about a Lizmo invoice opens billing for a landlord', () {
    expect(
      destinationOf(
        NotificationResponse(
          id: 'n1',
          type: NotificationResponseTypeEnum.PLATFORM_INVOICE_OVERDUE,
          relatedEntityType:
              NotificationResponseRelatedEntityTypeEnum.PLATFORM_INVOICE,
          relatedEntityId: 'i1',
        ),
        LizmoProfile.landlord,
      ),
      isA<OpenDetail>()
          .having((d) => d.detail, 'detail', Detail.lizmoBilling),
    );
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
