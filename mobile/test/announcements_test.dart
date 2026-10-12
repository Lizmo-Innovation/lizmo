import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/notice/notice_providers.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/announcements_screen.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo/widgets/post_notice_sheet.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Announcements from the landlord's end: writing one, knowing who it goes
/// to before sending, and seeing who has opened it.
void main() {
  late _FakeAnnouncements api;

  setUp(() => api = _FakeAnnouncements());

  LeaseResponse living(String tenant, String unit) => LeaseResponse(
        id: 'l-$tenant',
        tenantId: tenant,
        unitId: unit,
        status: LeaseResponseStatusEnum.ACTIVE,
      );

  List<Override> overrides({
    List<LeaseResponse> leases = const [],
    List<NoticeResponse> notices = const [],
  }) =>
      [
        authControllerProvider.overrideWith(() => _Landlord()),
        todayProvider.overrideWithValue(DateTime(2026, 10, 12)),
        announcementsApiProvider.overrideWithValue(api),
        propertyLeasesProvider('p1').overrideWith((ref) async => leases),
        unitsProvider('p1').overrideWith((ref) async => [
              UnitResponse(id: 'u2b', unitNumber: '2B'),
              UnitResponse(id: 'u3a', unitNumber: '3A'),
            ]),
        propertiesProvider.overrideWith((ref) async =>
            [PropertyResponse(id: 'p1', name: 'Sunrise Apartments')]),
        propertyNoticesProvider('p1').overrideWith((ref) async => notices),
      ];

  group('writing one', () {
    Future<void> openSheet(WidgetTester tester, List<LeaseResponse> leases) async {
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(leases: leases),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => PostNoticeSheet.show(context,
                    propertyId: 'p1', propertyName: 'Sunrise Apartments'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> write(WidgetTester tester) async {
      await tester.enterText(
          find.byKey(const ValueKey('notice-title')), 'Water off on Saturday');
      await tester.enterText(
          find.byKey(const ValueKey('notice-message')), 'From 9am to noon.');
      await tester.pumpAndSettle();
    }

    String button(WidgetTester tester) => tester
        .widget<PrimaryActionButton>(find.byKey(const ValueKey('send-notice')))
        .label;

    /// Before sending, not after: it goes to everybody in the building.
    testWidgets('the button says how many it goes to', (tester) async {
      await openSheet(tester, [living('ana', 'u2b'), living('bea', 'u3a')]);
      expect(button(tester), 'Write a title and a message');

      await write(tester);
      expect(button(tester), 'Send to 2 tenants');
      expect(find.text('Everyone at Sunrise Apartments (2 tenants)'), findsOneWidget);
    });

    testWidgets('one unit is only the people in it', (tester) async {
      await openSheet(tester, [living('ana', 'u2b'), living('bea', 'u3a')]);
      await write(tester);

      await tester.tap(find.byKey(const ValueKey('notice-who')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B only (1 tenant)').last);
      await tester.pumpAndSettle();

      expect(button(tester), 'Send to 1 tenant');
    });

    testWidgets('nobody living there, nothing to send', (tester) async {
      await openSheet(tester, const []);
      await write(tester);

      expect(button(tester), 'Nobody lives here yet');
    });

    testWidgets('a last day of their own has to be given', (tester) async {
      await openSheet(tester, [living('ana', 'u2b')]);
      await write(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('term-own')));
      await tester.tap(find.byKey(const ValueKey('term-own')));
      await tester.pumpAndSettle();

      expect(find.text('Until a date'), findsOneWidget);
      expect(button(tester), 'Choose the last day');
    });

    testWidgets('sending posts what was written, to whom', (tester) async {
      await openSheet(tester, [living('ana', 'u2b')]);
      await write(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('send-notice')));
      await tester.tap(find.byKey(const ValueKey('send-notice')));
      await tester.pumpAndSettle();

      final sent = api.posted.single;
      expect(sent.title, 'Water off on Saturday');
      expect(sent.message, 'From 9am to noon.');
      expect(sent.unitId, isNull);
      expect(sent.until, isNull);
      expect(find.byType(PostNoticeSheet), findsNothing);
    });
  });

  group('what is up', () {
    NoticeResponse notice({
      String id = 'n1',
      String? unit,
      bool live = true,
      int seen = 1,
      int audience = 2,
      DateTime? until,
    }) =>
        NoticeResponse(
          id: id,
          propertyId: 'p1',
          title: 'Water off on Saturday',
          message: 'From 9am to noon.',
          unitNumber: unit,
          postedAt: DateTime.utc(2026, 10, 10, 2),
          until: until,
          live: live,
          seenBy: seen,
          audience: audience,
        );

    Widget screen(List<NoticeResponse> notices) => ProviderScope(
          overrides: overrides(notices: notices),
          child: const MaterialApp(home: AnnouncementsScreen(propertyId: 'p1')),
        );

    testWidgets('says who has opened each', (tester) async {
      await tester.pumpWidget(screen([notice()]));
      await tester.pumpAndSettle();

      expect(find.text('Water off on Saturday'), findsOneWidget);
      expect(find.text('Seen by 1 of 2'), findsOneWidget);
      expect(find.text('Posted 10 October 2026'), findsOneWidget);
    });

    testWidgets('one for a unit says so, and one over says it is over',
        (tester) async {
      await tester.pumpWidget(screen([
        notice(id: 'n1', unit: '2B'),
        notice(id: 'n2', live: false, until: DateTime.utc(2026, 10, 11)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Unit 2B only'), findsOneWidget);
      expect(find.text('Over'), findsOneWidget);
      expect(find.text('Posted 10 October 2026, ended 11 October 2026'),
          findsOneWidget);
    });

    testWidgets('taking one down asks first', (tester) async {
      await tester.pumpWidget(screen([notice()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('take-down-n1')));
      await tester.pumpAndSettle();
      expect(find.text('Take this down?'), findsOneWidget);
      expect(find.textContaining('They are not told.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm-take-down')));
      await tester.pumpAndSettle();

      expect(api.takenDown, ['n1']);
    });

    testWidgets('with none, says what it is for', (tester) async {
      await tester.pumpWidget(screen(const []));
      await tester.pumpAndSettle();

      expect(find.text('Nothing posted'), findsOneWidget);
      expect(find.byKey(const ValueKey('post-notice')), findsOneWidget);
    });
  });
}

class _Landlord extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(Session(
        userId: 'u1',
        name: 'Elena Bautista',
        profiles: {LizmoProfile.landlord},
        accessToken: 'token',
      ));
}

class _FakeAnnouncements extends AnnouncementsApi {
  final posted = <PostNotice>[];
  final takenDown = <String>[];

  @override
  Future<NoticeResponse?> postNotice(
    String propertyId,
    PostNotice postNotice, {
    Future<void>? abortTrigger,
  }) async {
    posted.add(postNotice);
    return null;
  }

  @override
  Future<void> takeDownNotice(String id, {Future<void>? abortTrigger}) async {
    takenDown.add(id);
  }
}
