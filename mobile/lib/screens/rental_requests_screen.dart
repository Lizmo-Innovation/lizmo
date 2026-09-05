import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../widgets/accept_terms_sheet.dart';

/// Who has asked to live here, and the landlord answering.
///
/// Oldest first, as the API returns them: a queue of people waiting is answered
/// in the order they joined it.
class RentalRequestsScreen extends ConsumerWidget {
  const RentalRequestsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingRequestsProvider(propertyId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Requests',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: switch (requests) {
          AsyncData(:final value) when value.isEmpty => const LizmoMessageState(
            tone: LizmoMessageTone.neutral,
            icon: Icons.inbox_outlined,
            title: 'Nobody waiting',
            detail: 'When somebody scans your code and asks for a room, they '
                'will appear here.',
          ),
          AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: value.length,
            itemBuilder: (context, index) => _RequestCard(
              request: value[index],
              propertyId: propertyId,
            ),
          ),
          AsyncError(:final error) => _Failed(failure: ApiFailure.from(error)),
          _ => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
              ),
            ),
          ),
        },
      ),
    );
  }
}

/// One person asking, with what the landlord is allowed to know about them.
class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request, required this.propertyId});

  final RentalRequestForLandlord request;
  final String propertyId;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _working = false;

  Future<void> _answer({required bool accepting, AcceptRequest? terms}) async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(requestsToAnswerApiProvider);
    final id = widget.request.id!;

    try {
      if (accepting) {
        await api.acceptRentalRequest(id, acceptRequest: terms);
      } else {
        await api.declineRentalRequest(id);
      }

      // The queue and everything the acceptance moved: the unit's occupancy,
      // the property's figures, and who is living there.
      ref.invalidate(pendingRequestsProvider(widget.propertyId));
      ref.invalidate(propertyLeasesProvider(widget.propertyId));
      ref.invalidate(unitsProvider(widget.propertyId));
      ref.invalidate(propertiesProvider);

      messenger.showSnackBar(SnackBar(
        content: Text(accepting
            ? 'Accepted. ${widget.request.tenantName ?? 'They'} now has a lease.'
            : 'Declined.'),
      ));
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        // Whatever went wrong, the queue on screen is now suspect — most
        // likely somebody else took the bed while this was open.
        ref.invalidate(pendingRequestsProvider(widget.propertyId));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Settles the terms, then accepts on them.
  ///
  /// Was a yes/no dialog that said "at the asking rent" — words rather than a
  /// number — and then created a lease with a rent and a start date the
  /// landlord had never seen. Both are now chosen before anything is written.
  Future<void> _confirmAccept() async {
    final request = widget.request;

    final terms = await AcceptTermsSheet.show(
      context,
      tenantName: request.tenantName ?? 'this tenant',
      slot: _slot(request),
      askingRent: request.askingRent,
    );

    if (terms == null) return;
    await _answer(accepting: true, terms: terms);
  }

  static String _slot(RentalRequestForLandlord request) {
    return request.bedLabel == null
        ? 'unit ${request.unitNumber}'
        : '${request.bedLabel} in ${request.unitNumber}';
  }

  /// Deliberately vague: the exact figure is the asking rent, which this screen
  /// does not carry. Naming a number it has not been told would be worse than
  /// not naming one.
  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(request.tenantName ?? 'A tenant', style: LizmoType.rowName),
          const SizedBox(height: 2),
          Text('for ${_slot(request)}', style: LizmoType.rowSub),

          const SizedBox(height: 12),
          _Facts(request: request),

          const SizedBox(height: 8),
          if (_working)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _answer(accepting: false),
                  child: Text(
                    'Decline',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _confirmAccept,
                  child: Text(
                    'Accept',
                    style:
                        LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// What the landlord is told about a stranger.
///
/// The ID type is here; the number and the photographs are not, and will not be
/// until the lease exists. Anyone can put up a property with a code and collect
/// what a request carries.
class _Facts extends StatelessWidget {
  const _Facts({required this.request});

  final RentalRequestForLandlord request;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      // Their own number, because arranging a viewing is the next thing that
      // happens. The emergency contact is not here: that is a third person who
      // never used Lizmo, and who to ring if something happens to somebody who
      // does not live here yet is no use to a landlord deciding.
      ('Contact number', request.tenantPhone),
      // The age, not the birthday. A landlord thinks "27"; an ISO date is a
      // sum to do in your head, and the server has already done it.
      ('Age', _age(request)),
      ('Occupation', request.occupation),
      ('From', request.permanentAddress),
      ('ID', request.idType?.toString().replaceAll('_', ' ')),
    ].where((row) => (row.$2 ?? '').isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LizmoColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(row.$1, style: LizmoType.rowSub),
                  ),
                  Expanded(
                    child: Text(
                      row.$2!,
                      style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Worked out by the server, which has a clock a test can move and does not
  /// depend on the phone's own being right.
  static String? _age(RentalRequestForLandlord request) {
    final age = request.age;
    if (age == null) return null;
    return '$age years old';
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return LizmoMessageState(
      tone: LizmoMessageTone.problem,
      icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
      title: failure.isNetwork ? "Can't reach Lizmo" : "Can't open requests",
      detail: failure.message,
      actionLabel: 'Go back',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
