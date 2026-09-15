import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lizmo_api/api.dart';

/// What actually goes over the wire when somebody says they have paid.
///
/// The widget tests use fake APIs, so they never saw the generated client turn
/// a payment into one part holding `RecordPaymentRequest[...]` -- debug text,
/// with no content type -- which the server refused and every tenant saw as
/// "Something went wrong". These run the real generated client against a
/// stubbed HTTP layer and read the body it builds.
void main() {
  /// Sends one request through the real client and returns its body.
  Future<String> sent(Future<void> Function(ApiClient client) call) async {
    late String body;
    final client = ApiClient(basePath: 'https://api.test')
      ..client = MockClient((http.Request request) async {
        expect(request.headers['content-type'], startsWith('multipart/form-data'));
        body = utf8.decode(request.bodyBytes);
        return http.Response(
          '{"id":"p1"}',
          201,
          headers: {'content-type': 'application/json'},
        );
      });
    await call(client);
    return body;
  }

  /// A plain text field: its name, a blank line, and its value.
  Matcher field(String name, String value) =>
      contains('name="$name"\r\n\r\n$value\r\n');

  test('"I have paid" sends each field as plain text, never one JSON part',
      () async {
    final body = await sent((client) => RentApi(client).declarePayment(
          'l1',
          'b1',
          '2500',
          paymentMethod: 'GCASH',
          remarks: 'Ref 4012',
          channelId: 'c1',
        ));

    expect(body, field('billingPeriodId', 'b1'));
    expect(body, field('amountPaid', '2500'));
    expect(body, field('paymentMethod', 'GCASH'));
    expect(body, field('remarks', 'Ref 4012'));
    expect(body, field('channelId', 'c1'));
    expect(body, isNot(contains('name="payment"')));
    expect(body, isNot(contains('RecordPaymentRequest[')));
  });

  test('paying Lizmo sends each field as plain text too', () async {
    final body = await sent((client) => LizmoBillingApi(client).payPlatformStatement(
          's1',
          '850',
          paymentMethod: 'MAYA',
        ));

    expect(body, field('amountPaid', '850'));
    expect(body, field('paymentMethod', 'MAYA'));
    expect(body, isNot(contains('name="payment"')));
    expect(body, isNot(contains('PlatformPaymentRequest[')));
  });

  /// Fields left out stay out, so "no date" is today on the server rather
  /// than an empty string it has to refuse.
  test('fields not given are not sent', () async {
    final body = await sent((client) =>
        RentApi(client).declarePayment('l1', 'b1', '2500'));

    expect(body, isNot(contains('name="paymentDate"')));
    expect(body, isNot(contains('name="channelId"')));
    expect(body, isNot(contains('name="remarks"')));
  });
}
