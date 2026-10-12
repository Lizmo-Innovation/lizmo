import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo/billing/receipt_providers.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/receipt_screen.dart';
import 'package:lizmo/screens/tenant_detail_screen.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Receipts from the landlord's end: told the tenant has one the moment a
/// payment is confirmed, and able to find every one they issued.
void main() {
  late _FakeRent rent;
  late List<PaymentResponse> payments;

  setUp(() {
    rent = _FakeRent();
    payments = [];
  });

  /// The tenancy inside a tab, with the receipt screens mounted under it the
  /// way the app mounts them.
  Widget app() {
    final router = GoRouter(
      initialLocation: '/landlord/tenants/lease/l1',
      routes: [
        GoRoute(
          path: '/landlord/tenants',
          builder: (_, _) => const SizedBox(),
          routes: [
            GoRoute(
              path: 'lease/:leaseId',
              builder: (_, state) =>
                  TenantDetailScreen(leaseId: state.pathParameters['leaseId']!),
            ),
            GoRoute(
              path: 'receipts/:leaseId',
              builder: (_, state) => ReceiptsScreen(
                  leaseId: state.pathParameters['leaseId']!, landlord: true),
              routes: [
                GoRoute(
                  path: ':receiptId',
                  builder: (_, state) => ReceiptScreen(
                    leaseId: state.pathParameters['leaseId']!,
                    receiptId: state.pathParameters['receiptId']!,
                    landlord: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _Landlord()),
        todayProvider.overrideWithValue(DateTime(2026, 10, 12)),
        rentApiProvider.overrideWithValue(rent),
        myTenantsProvider.overrideWith((ref) async => [
              LeaseResponse(
                id: 'l1',
                tenantName: 'Ana Reyes',
                unitNumber: '2B',
                bedLabel: 'Bed 1',
                startDate: DateTime.utc(2026, 4, 1),
                status: LeaseResponseStatusEnum.ACTIVE,
              ),
            ]),
        leaseBillingProvider('l1')
            .overrideWith((ref) async => const <BillingPeriodResponse>[]),
        leasePaymentsProvider('l1').overrideWith((ref) async => payments),
        leaseTenantProvider('l1').overrideWith((ref) async =>
            TenantForLandlord(leaseId: 'l1', tenantId: 't1', name: 'Ana Reyes')),
        leaseTenantDocumentsProvider('l1')
            .overrideWith((ref) async => const <TenantDocumentResponse>[]),
        leaseDocumentsProvider('l1')
            .overrideWith((ref) async => const <LeaseDocumentResponse>[]),
        receiptsProvider((leaseId: 'l1', landlord: true))
            .overrideWith((ref) async => [_receipt('r7', '2026-0007')]),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  PaymentResponse paid(String id, {String? receipt}) => PaymentResponse(
        id: id,
        billingPeriodId: 'b1',
        amountPaid: 2500,
        status: receipt == null
            ? PaymentResponseStatusEnum.PENDING_VERIFICATION
            : PaymentResponseStatusEnum.CONFIRMED,
        paymentMethod: PaymentResponsePaymentMethodEnum.GCASH,
        proofUrlExpiresInSeconds: 0,
        receiptId: receipt,
        receiptNumber: receipt == null ? null : '2026-0007',
      );

  testWidgets('the tenancy counts the receipts issued, and opens them',
      (tester) async {
    payments = [paid('p1', receipt: 'r7'), paid('p2', receipt: 'r8')];
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('2 receipts'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lease-receipts')));
    await tester.pumpAndSettle();

    expect(find.byType(ReceiptsScreen), findsOneWidget);
    expect(find.textContaining('No. 2026-0007'), findsOneWidget);
  });

  testWidgets('none issued, no link', (tester) async {
    payments = [paid('p1')];
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lease-receipts')), findsNothing);
  });

  /// "Did you get my receipt?" answered before it is asked.
  testWidgets('confirming says the tenant has the receipt, and shows it',
      (tester) async {
    payments = [paid('p1')];
    rent.confirmed = paid('p1', receipt: 'r7');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text("Confirmed. Receipt 2026-0007 is in Ana's app."),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('view-receipt')));
    await tester.pumpAndSettle();

    expect(find.byType(ReceiptScreen), findsOneWidget);
    expect(find.text('No. 2026-0007'), findsOneWidget);
    expect(find.text('Your tenant has this receipt in their app too.'),
        findsOneWidget);
  });
}

ReceiptResponse _receipt(String id, String number) => ReceiptResponse(
      id: id,
      paymentId: 'p1',
      leaseId: 'l1',
      number: number,
      issuedAt: DateTime.utc(2026, 10, 12),
      receivedFrom: 'Ana Reyes',
      receivedBy: 'Elena Bautista',
      propertyName: 'Sunrise Apartments',
      place: 'Bed 1, 2B',
      periodLabel: 'October 2026',
      kind: ReceiptResponseKindEnum.RENT,
      amount: 2500,
      paymentMethod: ReceiptResponsePaymentMethodEnum.GCASH,
      paidOn: DateTime.utc(2026, 10, 10),
      stillOwed: 0,
    );

class _Landlord extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(Session(
        userId: 'u1',
        name: 'Elena Bautista',
        profiles: {LizmoProfile.landlord},
        accessToken: 'token',
      ));
}

class _FakeRent extends RentApi {
  PaymentResponse? confirmed;

  @override
  Future<PaymentResponse?> confirmPayment(
    String leaseId,
    String paymentId, {
    Future<void>? abortTrigger,
  }) async =>
      confirmed;
}
