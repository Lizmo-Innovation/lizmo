import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'push_permission.dart';
import 'push_providers.dart';

/// Asking to send notifications, at the moment they are worth having.
///
/// Never at first launch: a stranger asked before they have done anything
/// says no, and Android lets an app ask only twice. Asked instead right after
/// somebody has done a thing whose answer comes later -- a message sent, a
/// payment declared, a first enquiry to reply to -- and asked in those
/// terms, so the system prompt that follows is the answer to a question
/// they already said yes to.
class PushOffer {
  PushOffer(this._ref);

  final Ref _ref;
  bool _showing = false;

  /// "Not now" holds this long before it is asked again.
  static const askAgainAfter = Duration(days: 14);

  /// Offers once, if the phone has never been asked; otherwise does nothing.
  Future<void> offer(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    if (_showing) return;
    _showing = true;
    try {
      final channel = _ref.read(pushChannelProvider);
      if (await channel.permission() != PushPermission.notAsked) return;

      final memory = _ref.read(pushAskMemoryProvider);
      final last = await memory.lastDeclined();
      final now = DateTime.now();
      if (last != null && now.difference(last) < askAgainAfter) return;
      if (!context.mounted) return;

      final yes = await PushOfferSheet.show(context, title: title, body: body);
      if (yes) {
        await channel.askPermission();
        _ref.invalidate(pushPermissionProvider);
      } else {
        await memory.declined(now);
      }
    } catch (_) {
      // Asking is a courtesy. Whatever went wrong, what they were doing
      // already succeeded.
    } finally {
      _showing = false;
    }
  }
}

final pushOfferProvider = Provider<PushOffer>((ref) => PushOffer(ref));

/// The question itself, in Lizmo's words before Android's.
class PushOfferSheet extends StatelessWidget {
  const PushOfferSheet({super.key, required this.title, required this.body});

  final String title;
  final String body;

  /// True for "Turn on notifications"; false for "Not now" or a swipe away.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PushOfferSheet(title: title, body: body),
    );
    return yes ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DEDC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: LizmoColors.tealTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: LizmoColors.teal900,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: LizmoType.sectionHeading.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            Text(body, style: LizmoType.rowSub),
            const SizedBox(height: 18),
            PrimaryActionButton(
              key: const ValueKey('push-offer-yes'),
              label: 'Turn on notifications',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                key: const ValueKey('push-offer-no'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Not now',
                  style: LizmoType.rowName.copyWith(color: LizmoColors.slate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
