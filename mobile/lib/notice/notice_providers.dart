import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

final announcementsApiProvider = Provider<AnnouncementsApi>((ref) {
  return AnnouncementsApi(ref.watch(apiClientProvider));
});

/// What a landlord has up on one building, newest first.
final propertyNoticesProvider = FutureProvider.autoDispose
    .family<List<NoticeResponse>, String>((ref, propertyId) async {
  try {
    return await ref.watch(announcementsApiProvider).listPropertyNotices(propertyId) ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// What is up where a tenant lives now, newest first.
final myNoticesProvider =
    FutureProvider.autoDispose<List<MyNoticeResponse>>((ref) async {
  try {
    return await ref.watch(announcementsApiProvider).listMyNotices() ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
