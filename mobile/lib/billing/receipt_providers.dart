import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

final receiptsApiProvider = Provider<ReceiptsApi>((ref) {
  return ReceiptsApi(ref.watch(apiClientProvider));
});

/// Whose receipts, from which end: the same receipts, read through the
/// endpoint each side is allowed.
typedef ReceiptsOf = ({String leaseId, bool landlord});

/// Every receipt on one tenancy, newest first.
final receiptsProvider = FutureProvider.autoDispose
    .family<List<ReceiptResponse>, ReceiptsOf>((ref, of) async {
  final api = ref.watch(receiptsApiProvider);
  try {
    final receipts = of.landlord
        ? await api.listLeaseReceipts(of.leaseId)
        : await api.listMyReceipts(of.leaseId);
    return receipts ?? const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
