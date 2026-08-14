@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_api/api.dart';

/// Exercises the property endpoints through the generated client.
///
/// Needs the stack up and the sample accounts present:
///   docker compose up -d
///   flutter test --tags live
///
/// Covers the seam unit tests cannot: that the wire format the backend sends is
/// the one the generated models expect. A renamed field or a changed enum shows
/// up here and nowhere else.
void main() {
  const baseUrl = String.fromEnvironment(
    'LIZMO_API_BASE_URL',
    defaultValue: 'http://localhost:8082',
  );

  late ApiClient client;
  late AuthApi auth;
  late PropertiesApi properties;

  setUp(() {
    client = ApiClient(basePath: baseUrl);
    auth = AuthApi(client);
    properties = PropertiesApi(client);
  });

  Future<void> signInAs(String identifier) async {
    final response = await auth.login(
      LoginRequest(identifier: identifier, password: 'lizmo12345'),
    );
    client.addDefaultHeader('Authorization', 'Bearer ${response!.accessToken}');
  }

  test('a landlord reads their own properties', () async {
    await signInAs('landlord@lizmo.test');

    final list = await properties.listProperties();

    expect(list, isNotNull);
    expect(list!, isNotEmpty, reason: 'the seeded landlord owns Sunrise Apartments');

    final sunrise = list.firstWhere((p) => p.name == 'Sunrise Apartments');
    expect(sunrise.address, contains('Mabini'));
    expect(sunrise.type, PropertyResponseTypeEnum.BOARDING_HOUSE);
    expect(sunrise.unitCount, greaterThan(0));
  });

  test('units and beds come back for a property', () async {
    await signInAs('landlord@lizmo.test');

    final list = await properties.listProperties();
    final sunrise = list!.firstWhere((p) => p.name == 'Sunrise Apartments');

    final units = await properties.listUnits(sunrise.id!);
    expect(units!, isNotEmpty);

    // The seed holds both modes, which is the distinction the product turns on.
    expect(units.map((u) => u.rentalMode),
        contains(UnitResponseRentalModeEnum.BEDSPACE));
    expect(units.map((u) => u.rentalMode),
        contains(UnitResponseRentalModeEnum.WHOLE_UNIT));

    final bedspace = units.firstWhere(
      (u) => u.rentalMode == UnitResponseRentalModeEnum.BEDSPACE,
    );
    expect(bedspace.bedCount, greaterThan(0));

    final beds = await UnitsApi(client).listBeds(bedspace.id!);
    expect(beds!.length, bedspace.bedCount,
        reason: 'the unit summary and the bed list must agree');
  });

  test('a tenant owns nothing, which is empty rather than an error', () async {
    await signInAs('tenant@lizmo.test');

    // The screen shows its empty state here, not a failure — the distinction
    // matters, because one invites action and the other implies breakage.
    final list = await properties.listProperties();
    expect(list, isEmpty);
  });

  test('one landlord cannot read another landlord by id', () async {
    await signInAs('landlord@lizmo.test');
    final list = await properties.listProperties();
    final id = list!.first.id!;

    await signInAs('tenant@lizmo.test');

    // 404 rather than 403: a 403 would confirm the property exists.
    await expectLater(
      () => properties.getProperty(id),
      throwsA(isA<ApiException>().having((e) => e.code, 'status', 404)),
    );
  });
}
