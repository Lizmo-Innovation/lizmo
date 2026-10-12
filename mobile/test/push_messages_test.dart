import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/inquiry/inquiry_providers.dart';
import 'package:lizmo/notifications/notification_links.dart';
import 'package:lizmo/notifications/notification_providers.dart';
import 'package:lizmo/push/push_ask_memory.dart';
import 'package:lizmo/push/push_channel.dart';
import 'package:lizmo/push/push_messages.dart';
import 'package:lizmo/push/push_offer.dart';
import 'package:lizmo/push/push_permission.dart';
import 'package:lizmo/push/push_providers.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo/widgets/account_sheet.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// A push, once it reaches the phone: what tapping it opens, what arriving
/// with the app open refreshes, and asking to be allowed to send them.
void main() {
  late _Channel channel;

  setUp(() => channel = _Channel());

  group('what a push is about', () {
    test('is read back as the notification it was raised from', () {
      final notification = notificationOf({
        'notificationId': 'n1',
        'type': 'INQUIRY_MESSAGE',
        'relatedEntityType': 'INQUIRY',
        'relatedEntityId': 'thread-1',
      })!;

      expect(notification.id, 'n1');
      expect(notification.type, NotificationResponseTypeEnum.INQUIRY_MESSAGE);
      expect(notification.relatedEntityType,
          NotificationResponseRelatedEntityTypeEnum.INQUIRY);
      expect(notification.relatedEntityId, 'thread-1');
      expect(notification.leaseId, isNull);
    });

    /// So a tap opens the same screen as the bell: the same routing decides.
    test('opens where the bell would', () {
      final notification = notificationOf({
        'notificationId': 'n1',
        'type': 'PAYMENT_DECLARED',
        'relatedEntityType': 'PAYMENT',
        'relatedEntityId': 'p1',
        'leaseId': 'lease-1',
      })!;

      final destination = destinationOf(notification, LizmoProfile.landlord);
      expect(destination, isA<OpenDetail>());
      expect((destination! as OpenDetail).detail, Detail.tenancy('lease-1'));
    });

    test("is nothing when it is not one of Lizmo's", () {
      expect(notificationOf({'campaign': 'x'}), isNull);
    });
  });

  group('opening it', () {
    test('a detail opens inside the tab that is showing', () {
      expect(
        pushStep(const OpenDetail('lease/l1'), '/landlord/rent',
                LizmoProfile.landlord)
            ?.path,
        '/landlord/rent/lease/l1',
      );
    });

    /// A conversation sits above the tabs; there is no tab to open it in.
    test('over a conversation, a detail opens from home', () {
      final step = pushStep(
          const OpenDetail('lease/l1'), '/inquiry/t1', LizmoProfile.landlord);
      expect(step, isA<PushGo>());
      expect(step!.path, '/landlord/home/lease/l1');
    });

    test('a conversation opens over the tab', () {
      final step = pushStep(OpenScreen(Routes.inquiry('t2')), '/tenant/home',
          LizmoProfile.tenant);
      expect(step, isA<PushPush>());
      expect(step!.path, '/inquiry/t2');
    });

    test("over another conversation, it takes that one's place", () {
      final step = pushStep(OpenScreen(Routes.inquiry('t2')), '/inquiry/t1',
          LizmoProfile.tenant);
      expect(step, isA<PushReplace>());
    });

    test("a tenant's tab is switched to", () {
      final step = pushStep(const SwitchTab(Routes.tenantPayments),
          '/tenant/home', LizmoProfile.tenant);
      expect(step, isA<PushGo>());
      expect(step!.path, Routes.tenantPayments);
    });

    /// Opened from the splash, the redirect to home would undo it.
    test('waits until the app has landed somewhere', () {
      expect(isSettled(Routes.splash), isFalse);
      expect(isSettled(Routes.login), isFalse);
      expect(isSettled(Routes.update), isFalse);
      expect(isSettled(Routes.landlordHome), isTrue);
      expect(isSettled('/landlord/rent/lease/l1'), isTrue);
      expect(isSettled('/inquiry/t1'), isTrue);
    });
  });

  group('while the app is open', () {
    late int bellReads;
    late int inboxReads;
    late int threadReads;

    ProviderContainer open() {
      bellReads = 0;
      inboxReads = 0;
      threadReads = 0;
      final container = ProviderContainer(overrides: [
        pushChannelProvider.overrideWithValue(channel),
        myNotificationsProvider.overrideWith((ref) async {
          bellReads++;
          return const <NotificationResponse>[];
        }),
        myInquiriesProvider.overrideWith((ref) async {
          inboxReads++;
          return const <InquirySummary>[];
        }),
        inquiryThreadProvider.overrideWith((ref, id) async {
          threadReads++;
          return InquiryThread();
        }),
      ]);
      addTearDown(container.dispose);
      container.listen(pushMessagesProvider, (_, _) {});
      container.listen(myNotificationsProvider, (_, _) {});
      container.listen(myInquiriesProvider, (_, _) {});
      container.listen(inquiryThreadProvider('t1'), (_, _) {});
      return container;
    }

    /// Invalidated providers are read again on the container's next pass,
    /// which is a few event-loop turns away.
    Future<void> settle() async {
      for (var turn = 0; turn < 5; turn++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('the bell is brought up to date', () async {
      open();
      await settle();

      channel.arriving
          .add({'notificationId': 'n1', 'type': 'RENT_DUE_REMINDER'});
      await settle();

      expect(bellReads, 2);
      expect(inboxReads, 1);
    });

    /// A reply lands in the conversation on screen without waiting for its poll.
    test('the conversation it is about is read again', () async {
      open();
      await settle();

      channel.arriving.add({
        'notificationId': 'n1',
        'type': 'INQUIRY_MESSAGE',
        'relatedEntityType': 'INQUIRY',
        'relatedEntityId': 't1',
      });
      await settle();

      expect(threadReads, 2);
      expect(inboxReads, 2);
      expect(bellReads, 2);
    });

    test('a tapped push waits to be opened', () async {
      final container = open();
      await settle();

      channel.opening.add({'notificationId': 'n1', 'type': 'RENT_OVERDUE'});
      await settle();

      expect(container.read(pendingPushOpenProvider)?['notificationId'], 'n1');
    });

    test('so does the one that started the app', () async {
      channel.launchedWith = {'notificationId': 'n9', 'type': 'RENT_OVERDUE'};
      final container = open();
      await settle();

      expect(container.read(pendingPushOpenProvider)?['notificationId'], 'n9');
    });
  });

  group('asking to send them', () {
    late InMemoryPushAskMemory memory;

    setUp(() => memory = InMemoryPushAskMemory());

    Widget host() => ProviderScope(
          overrides: [
            pushChannelProvider.overrideWithValue(channel),
            pushAskMemoryProvider.overrideWithValue(memory),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => ref.read(pushOfferProvider).offer(
                        context,
                        title: 'Get told when Maria replies?',
                        body: 'Lizmo will let you know the moment they answer.',
                      ),
                  child: const Text('Send'),
                ),
              ),
            ),
          ),
        );

    testWidgets("a phone never asked is asked, in Lizmo's words first",
        (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Get told when Maria replies?'), findsOneWidget);
      expect(channel.asked, 0);

      await tester.tap(find.byKey(const ValueKey('push-offer-yes')));
      await tester.pumpAndSettle();

      expect(channel.asked, 1);
      expect(find.text('Get told when Maria replies?'), findsNothing);
    });

    testWidgets('"Not now" is not asked about again for a while',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('push-offer-no')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Get told when Maria replies?'), findsNothing);
      expect(channel.asked, 0);
    });

    testWidgets('long enough after "Not now", it is asked again',
        (tester) async {
      await memory.declined(DateTime.now()
          .subtract(PushOffer.askAgainAfter + const Duration(days: 1)));
      await tester.pumpWidget(host());
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Get told when Maria replies?'), findsOneWidget);
    });

    for (final already in [
      PushPermission.granted,
      PushPermission.denied,
      PushPermission.blocked,
      PushPermission.unsupported,
    ]) {
      testWidgets('a phone that is ${already.name} is not asked',
          (tester) async {
        channel.permissionIs = already;
        await tester.pumpWidget(host());
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        expect(find.text('Get told when Maria replies?'), findsNothing);
      });
    }
  });

  group('the account menu', () {
    Widget menu() => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _SignedIn()),
            pushChannelProvider.overrideWithValue(channel),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => AccountSheet.show(context),
                  child: const Text('Account'),
                ),
              ),
            ),
          ),
        );

    Future<void> openMenu(WidgetTester tester) async {
      await tester.pumpWidget(menu());
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
    }

    testWidgets('says nothing when notifications are on', (tester) async {
      channel.permissionIs = PushPermission.granted;
      await openMenu(tester);

      expect(find.text('Notifications are off'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('nor when they were never asked about', (tester) async {
      await openMenu(tester);

      expect(find.text('Notifications are off'), findsNothing);
    });

    /// Android will still ask once more, which is better than settings.
    testWidgets('after one "no", Turn on asks again', (tester) async {
      channel.permissionIs = PushPermission.denied;
      channel.answer = PushPermission.granted;
      await openMenu(tester);

      expect(find.text('Notifications are off'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-off')));
      await tester.pumpAndSettle();

      expect(channel.asked, 1);
      expect(channel.settingsOpened, 0);
      expect(find.text('Notifications are off'), findsNothing);
    });

    testWidgets("after a second \"no\", Turn on opens the phone's settings",
        (tester) async {
      channel.permissionIs = PushPermission.blocked;
      await openMenu(tester);

      await tester.tap(find.byKey(const ValueKey('notifications-off')));
      await tester.pumpAndSettle();

      expect(channel.asked, 0);
      expect(channel.settingsOpened, 1);
      // Closed, so it is read afresh when they come back.
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('a "no" to the second ask goes to settings too',
        (tester) async {
      channel.permissionIs = PushPermission.denied;
      channel.answer = PushPermission.blocked;
      await openMenu(tester);

      await tester.tap(find.byKey(const ValueKey('notifications-off')));
      await tester.pumpAndSettle();

      expect(channel.asked, 1);
      expect(channel.settingsOpened, 1);
    });
  });
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(Session(
        userId: 'u1',
        name: 'Ana Reyes',
        profiles: {LizmoProfile.tenant},
        accessToken: 'token',
      ));
}

class _Channel implements PushChannel {
  PushPermission permissionIs = PushPermission.notAsked;

  /// What Android's prompt comes back with.
  PushPermission answer = PushPermission.granted;

  int asked = 0;
  int settingsOpened = 0;
  Map<String, String>? launchedWith;

  final arriving = StreamController<Map<String, String>>.broadcast();
  final opening = StreamController<Map<String, String>>.broadcast();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<PushPermission> permission() async => permissionIs;

  @override
  Future<PushPermission> askPermission() async {
    asked++;
    permissionIs = answer;
    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Stream<Map<String, String>> get arrived => arriving.stream;

  @override
  Stream<Map<String, String>> get opened => opening.stream;

  @override
  Future<Map<String, String>?> openedAtLaunch() async => launchedWith;
}
