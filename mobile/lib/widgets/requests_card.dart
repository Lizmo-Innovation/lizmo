import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// Everybody waiting for this landlord to answer, across every property.
///
/// The queue lived inside each property, behind a strip that only showed once
/// the property was open -- so a landlord with three buildings had to open all
/// three to find out whether anybody was asking.
///
/// Shown only when somebody is. A card that permanently reads "nobody waiting"
/// is one a landlord learns to stop seeing.
class RequestsCard extends ConsumerWidget {
  const RequestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestsToAnswerProvider);

    return requests.when(
      loading: () => const SizedBox.shrink(),
      // Said rather than hidden. Hidden, a failure reads as nobody waiting,
      // which is the one thing this card must never say falsely.
      error: (error, _) => _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requests', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
      ),
      data: (waiting) =>
          waiting.isEmpty ? const SizedBox.shrink() : _Queue(waiting: waiting),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('requests-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: child,
      ),
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue({required this.waiting});

  final List<RentalRequestForLandlord> waiting;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Requests', style: LizmoType.sectionHeading),
              ),
              Text(
                waiting.length == 1
                    ? '1 waiting for your answer'
                    : '${waiting.length} waiting for your answer',
                style: LizmoType.rowSub.copyWith(
                  color: LizmoColors.amberText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Oldest first, as the API returns them: whoever has waited
          // longest is answered first.
          for (final request in waiting) _RequestRow(request: request),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final RentalRequestForLandlord request;

  @override
  Widget build(BuildContext context) {
    final slot = request.bedLabel == null
        ? 'Unit ${request.unitNumber}'
        : '${request.bedLabel}, ${request.unitNumber}';
    final where = request.propertyName == null
        ? slot
        : '$slot · ${request.propertyName}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('request-${request.id}'),
        // To that property's queue, where Accept and Decline already are and
        // the terms get settled. Opens inside Today, so Back comes straight
        // back here to the next person.
        onTap: () => context.openInTab(Detail.requests(request.propertyId!)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LizmoColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.tenantName ?? 'Somebody',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      where,
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                _waited(request.createdAt),
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: LizmoColors.slate),
            ],
          ),
        ),
      ),
    );
  }

  /// How long they have been waiting, which is what makes one of these urgent.
  static String _waited(DateTime? asked) {
    if (asked == null) return '';
    final days = DateTime.now().difference(asked.toLocal()).inDays;
    if (days < 1) return 'Today';
    return days == 1 ? '1 day' : '$days days';
  }
}
