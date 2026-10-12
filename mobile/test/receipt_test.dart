import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/billing/pesos_in_words.dart';
import 'package:lizmo/billing/receipt_providers.dart';
import 'package:lizmo/screens/receipt_screen.dart';
import 'package:lizmo/widgets/receipt_card.dart';
import 'package:lizmo_api/api.dart';

/// Acknowledgement receipts, as a tenant or landlord sees and sends them.
void main() {
  group('an amount in words', () {
    test('as a receipt writes it under the figure', () {
      expect(pesosInWords(2500), 'Two thousand five hundred pesos');
      expect(pesosInWords(1), 'One peso');
      expect(pesosInWords(21), 'Twenty-one pesos');
      expect(pesosInWords(15000), 'Fifteen thousand pesos');
      expect(pesosInWords(1000000), 'One million pesos');
      expect(pesosInWords(123456),
          'One hundred twenty-three thousand four hundred fifty-six pesos');
    });

    test('with centavos', () {
      expect(pesosInWords(1250.5),
          'One thousand two hundred fifty pesos and fifty centavos');
      expect(pesosInWords(0.01), 'Zero pesos and one centavo');
    });
  });

  group('what it was for', () {
    test('rent, an advance, and a deposit each say which', () {
      expect(receiptFor(_receipt()), 'October 2026 rent');
      expect(receiptFor(_receipt(label: 'October 2026 · advance')),
          'October 2026 rent, paid in advance');
      expect(
          receiptFor(_receipt(
              label: 'Security deposit', kind: ReceiptResponseKindEnum.DEPOSIT)),
          'Security deposit, to be returned at move-out');
    });
  });

  group('the receipt', () {
    Future<void> show(WidgetTester tester, ReceiptResponse receipt) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ReceiptCard(receipt: receipt)),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('says what a paper one does', (tester) async {
      await show(tester, _receipt());

      expect(find.text('ACKNOWLEDGEMENT RECEIPT'), findsOneWidget);
      expect(find.text('No. 2026-0042'), findsOneWidget);
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('₱2,500'), findsOneWidget);
      expect(find.text('Two thousand five hundred pesos'), findsOneWidget);
      expect(find.text('October 2026 rent'), findsOneWidget);
      expect(find.text('Bed 1, 2B · Sunrise Apartments'), findsOneWidget);
      expect(find.text('GCash, to GCash · Elena Bautista'), findsOneWidget);
      expect(find.text('10 October 2026'), findsOneWidget);
      expect(find.text('October 2026 is paid in full'), findsOneWidget);
      expect(find.text('Elena Bautista'), findsOneWidget);
    });

    /// Lizmo cannot issue those, and a landlord must not look as if it had.
    testWidgets('says on its face it is not a BIR official receipt',
        (tester) async {
      await show(tester, _receipt());

      expect(find.text('Recorded in Lizmo. Not a BIR official receipt.'),
          findsOneWidget);
    });

    testWidgets('part of a month says what is still owed', (tester) async {
      await show(tester, _receipt(amount: 1000, stillOwed: 1500));

      expect(find.text('Still owed'), findsOneWidget);
      expect(find.text('₱1,500 of October 2026'), findsOneWidget);
    });

    testWidgets('cash has no account to name', (tester) async {
      await show(tester,
          _receipt(method: ReceiptResponsePaymentMethodEnum.CASH, sentTo: null));

      expect(find.text('Cash'), findsOneWidget);
    });
  });

  group('the screens', () {
    Widget app(Widget screen, List<ReceiptResponse> receipts,
            {bool landlord = false}) =>
        ProviderScope(
          overrides: [
            receiptsProvider((leaseId: 'l1', landlord: landlord))
                .overrideWith((ref) async => receipts),
          ],
          child: MaterialApp(home: screen),
        );

    /// What a "your payment was confirmed" notification knows.
    testWidgets('a receipt is found by the payment it acknowledges',
        (tester) async {
      await tester.pumpWidget(app(
        const ReceiptScreen(leaseId: 'l1', paymentId: 'p1', landlord: false),
        [_receipt()],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No. 2026-0042'), findsOneWidget);
      expect(find.byKey(const ValueKey('share-receipt')), findsOneWidget);
      expect(find.textContaining('Messenger, Viber'), findsOneWidget);
    });

    testWidgets('one not issued yet says when it will be', (tester) async {
      await tester.pumpWidget(app(
        const ReceiptScreen(leaseId: 'l1', paymentId: 'waiting', landlord: false),
        [_receipt()],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No receipt yet'), findsOneWidget);
      expect(find.text('One is issued when your landlord confirms the payment.'),
          findsOneWidget);
    });

    testWidgets('the list is by year, newest first', (tester) async {
      await tester.pumpWidget(app(
        const ReceiptsScreen(leaseId: 'l1', landlord: false),
        [
          _receipt(id: 'r2', number: '2027-0001', issued: DateTime.utc(2027, 1, 5)),
          _receipt(id: 'r1'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('2027'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('2027')).dy,
        lessThan(tester.getTopLeft(find.text('2026')).dy),
      );
      expect(find.textContaining('No. 2027-0001'), findsOneWidget);
    });

    testWidgets('with none, says when one comes', (tester) async {
      await tester.pumpWidget(
          app(const ReceiptsScreen(leaseId: 'l1', landlord: false), const []));
      await tester.pumpAndSettle();

      expect(find.text('No receipts yet'), findsOneWidget);
      expect(find.text('One appears each time your landlord confirms a payment.'),
          findsOneWidget);
    });
  });
}

ReceiptResponse _receipt({
  String id = 'r1',
  String number = '2026-0042',
  String label = 'October 2026',
  ReceiptResponseKindEnum kind = ReceiptResponseKindEnum.RENT,
  num amount = 2500,
  num stillOwed = 0,
  ReceiptResponsePaymentMethodEnum method = ReceiptResponsePaymentMethodEnum.GCASH,
  String? sentTo = 'GCash · Elena Bautista',
  DateTime? issued,
}) =>
    ReceiptResponse(
      id: id,
      paymentId: 'p1',
      leaseId: 'l1',
      number: number,
      issuedAt: issued ?? DateTime.utc(2026, 10, 12, 7, 42),
      receivedFrom: 'Ana Reyes',
      receivedBy: 'Elena Bautista',
      propertyName: 'Sunrise Apartments',
      place: 'Bed 1, 2B',
      periodLabel: label,
      kind: kind,
      amount: amount,
      paymentMethod: method,
      sentTo: sentTo,
      paidOn: DateTime.utc(2026, 10, 10),
      stillOwed: stillOwed,
    );
