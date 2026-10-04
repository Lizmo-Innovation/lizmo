import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Conversations about a place, from whichever end you are reading them.
///
/// One endpoint serves both sides, so these providers do too: a landlord's
/// inbox and a tenant's are the same list, and who is signed in decides what
/// comes back.
final inquiriesApiProvider = Provider<AskingAboutAPlaceApi>((ref) {
  return AskingAboutAPlaceApi(ref.watch(apiClientProvider));
});

/// Every thread this account is a part of, most recently spoken in first.
///
/// autoDispose: coming back to the list should show what has been said since,
/// not what was there when it was last opened.
final myInquiriesProvider =
    FutureProvider.autoDispose<List<InquirySummary>>((ref) async {
  try {
    return await ref.watch(inquiriesApiProvider).listMyInquiries() ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// One thread, with everything said in it.
///
/// Reading it marks it seen, which is the server's doing rather than a second
/// call: opening a conversation is what "seen" means.
final inquiryThreadProvider = FutureProvider.autoDispose
    .family<InquiryThread, String>((ref, id) async {
  try {
    final thread = await ref.watch(inquiriesApiProvider).readInquiry(id);
    if (thread == null) {
      throw const ApiFailure(
        code: 'NOT_FOUND',
        message: 'That conversation is no longer there.',
      );
    }
    return thread;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// How many threads have something this account has not read.
///
/// Derived from the list rather than asked for separately: the list is already
/// loaded wherever this is shown, and a second endpoint would be a second
/// thing to keep in step.
final unreadInquiriesProvider = Provider.autoDispose<int>((ref) {
  final threads = ref.watch(myInquiriesProvider).valueOrNull ?? const [];
  return threads.where((thread) => thread.unread ?? false).length;
});
