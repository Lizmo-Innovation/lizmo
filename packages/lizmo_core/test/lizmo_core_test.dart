import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_core/lizmo_core.dart';

void main() {
  group('LizmoProfile', () {
    test('parses the profiles the backend sends', () {
      expect(LizmoProfile.parse('TENANT'), LizmoProfile.tenant);
      expect(LizmoProfile.parse('LANDLORD'), LizmoProfile.landlord);
      expect(LizmoProfile.parse('ADMIN'), LizmoProfile.admin);
      expect(LizmoProfile.parse('tenant'), LizmoProfile.tenant);
    });

    test('ignores profiles this build has never heard of', () {
      // Forward compatibility: the backend may add one, and an installed app
      // must keep working rather than crashing on an unknown value.
      expect(LizmoProfile.parse('WAREHOUSE_MANAGER'), isNull);
      expect(LizmoProfile.parse(''), isNull);
    });
  });

  group('Session', () {
    Session sessionWith(Set<LizmoProfile> profiles) => Session(
          userId: 'u1',
          name: 'Ana Reyes',
          profiles: profiles,
          accessToken: 'token',
        );

    test('reports which profiles are held', () {
      final both = sessionWith({LizmoProfile.tenant, LizmoProfile.landlord});
      expect(both.isTenant, isTrue);
      expect(both.isLandlord, isTrue);
      expect(both.hasMultipleProfiles, isTrue);
      expect(both.isPlatformAdmin, isFalse);
    });

    test('admin is independent of tenant and landlord', () {
      // A Lizmo employee who also rents somewhere holds both, and neither
      // implies the other.
      final adminTenant = sessionWith({LizmoProfile.tenant, LizmoProfile.admin});
      expect(adminTenant.isPlatformAdmin, isTrue);
      expect(adminTenant.isLandlord, isFalse);

      final landlordOnly = sessionWith({LizmoProfile.landlord});
      expect(landlordOnly.isPlatformAdmin, isFalse);
    });
  });

  group('InMemoryTokenStore', () {
    test('round-trips and clears', () async {
      final store = InMemoryTokenStore();
      expect(await store.readAccessToken(), isNull);

      await store.save(accessToken: 'a', refreshToken: 'r');
      expect(await store.readAccessToken(), 'a');
      expect(await store.readRefreshToken(), 'r');

      await store.clear();
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });
  });

  group('ApiFailure', () {
    test('unrecognised errors fall back rather than throwing', () {
      final failure = ApiFailure.from(Exception('something odd'));
      expect(failure.code, isNotEmpty);
      expect(failure.message, isNotEmpty);
    });
  });
}
