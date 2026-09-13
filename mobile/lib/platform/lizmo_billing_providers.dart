import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// What a landlord owes Lizmo, and paying it.
final lizmoBillingApiProvider = Provider<LizmoBillingApi>((ref) {
  return LizmoBillingApi(ref.watch(apiClientProvider));
});

/// Every statement of this landlord's, newest month first.
///
/// One a month for the whole account, with a line per property. A line only
/// carries an invoice number once the statement is paid.
final myLizmoStatementsProvider =
    FutureProvider.autoDispose<List<PlatformStatementResponse>>((ref) async {
  try {
    return await ref.watch(lizmoBillingApiProvider).listMyPlatformStatements() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Where to send the money, as a Lizmo admin wrote it. Null until one has.
final lizmoPaymentInstructionsProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  try {
    final answer =
        await ref.watch(lizmoBillingApiProvider).getPlatformPaymentInstructions();
    final text = answer?.instructions?.trim();
    return text == null || text.isEmpty ? null : text;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Whether a statement is waiting on the landlord.
///
/// Something still owed, and nothing already sent that Lizmo has yet to check.
/// A landlord who has paid and is waiting for confirmation has done their part,
/// and being asked again would read as the payment having been lost.
bool lizmoStatementNeedsPaying(PlatformStatementResponse statement) =>
    (statement.outstanding ?? 0) > 0 && !lizmoStatementAwaitingLizmo(statement);

/// Whether a payment against this statement is waiting for Lizmo to check it.
bool lizmoStatementAwaitingLizmo(PlatformStatementResponse statement) =>
    statement.payments
        .any((payment) => payment.status?.toJson() == 'PENDING_VERIFICATION');
