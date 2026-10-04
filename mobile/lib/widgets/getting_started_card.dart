import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';
import '../inquiry/inquiry_providers.dart';
import '../property/property_providers.dart';
import '../router.dart';

/// What a new landlord still has to do, property by property.
///
/// A property is only earning once it has rooms to let, an account its tenants
/// can pay into, and a code somebody has used. Each of those lives on a
/// different screen, and a landlord who stops after the first is left with a
/// property nobody can rent and no sign of why.
///
/// Gone as soon as a property's three are done, and the section with it: this
/// is scaffolding, not a permanent part of Today.
class GettingStartedSection extends ConsumerWidget {
  const GettingStartedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider).valueOrNull;
    if (properties == null) return const SizedBox.shrink();

    if (properties.isEmpty) {
      return const _Card(
        key: ValueKey('get-started-first-property'),
        title: 'Add your first property',
        steps: [
          _Step(
            label: 'Add your property',
            detail: 'A boarding house, an apartment building, or a single unit.',
            done: false,
            go: Routes.propertyNew,
          ),
        ],
      );
    }

    // Both are already read by Today; neither adds a request of its own.
    final channels = ref.watch(myPaymentChannelsProvider).valueOrNull;
    final occupancy = ref.watch(occupancyProvider).valueOrNull;
    final asking = ref.watch(myInquiriesProvider).valueOrNull;
    // Until every answer is in, nothing: a step ticked and then unticked a
    // moment later reads as the app losing what was done.
    if (channels == null || occupancy == null || asking == null) {
      return const SizedBox.shrink();
    }

    final paid = {
      for (final channel in channels)
        if (channel.visible ?? true) ...channel.propertyIds,
    };
    final lived = {
      for (final row in occupancy.vacancies)
        if ((row.occupied ?? 0) > 0) row.propertyId,
      for (final thread in asking) thread.propertyId,
    };

    final cards = <Widget>[];
    for (final property in properties) {
      final id = property.id;
      if (id == null) continue;

      final steps = [
        _Step(
          label: 'Add units or beds',
          detail: 'Whole units, or a room bed by bed, each with its rent.',
          done: (property.unitCount ?? 0) > 0,
          go: Detail.property(id),
          inTab: true,
        ),
        _Step(
          label: 'Choose how tenants pay you here',
          detail: 'Which of your accounts this property\'s tenants send rent to.',
          done: paid.contains(id),
          go: Detail.paymentChannels,
          inTab: true,
        ),
        _Step(
          label: 'Share your property code',
          detail: 'Tenants scan it to see what is free and ask to rent.',
          // Somebody asking, or already living there, is the only sign the app
          // has that the code reached anybody.
          done: lived.contains(id),
          go: Detail.share(id),
          inTab: true,
        ),
      ];
      if (steps.every((step) => step.done)) continue;

      cards.add(_Card(
        key: ValueKey('get-started-$id'),
        title: 'Set up ${property.name ?? 'your property'}',
        steps: steps,
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
          // The same label as Today's own sections. LizmoType.eyebrow is for
          // the dark header and is all but invisible on canvas.
          child: Text(
            'GET STARTED',
            style: LizmoType.rowSub.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: LizmoColors.slate,
            ),
          ),
        ),
        ...cards,
      ],
    );
  }
}

class _Step {
  const _Step({
    required this.label,
    required this.detail,
    required this.done,
    required this.go,
    this.inTab = false,
  });

  final String label;
  final String detail;
  final bool done;

  /// Where it is done: a route, or a detail opened inside Today.
  final String go;
  final bool inTab;
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, required this.steps});

  final String title;
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    final done = steps.where((step) => step.done).length;
    // Only the next one to do is a button. Three coral buttons on one card
    // would be three things shouting, and the order they are in is the order
    // they make sense in.
    final next = steps.indexWhere((step) => !step.done);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: LizmoType.sectionHeading),
                ),
                Text('$done of ${steps.length} done', style: LizmoType.rowSub),
              ],
            ),
            const SizedBox(height: 10),
            for (final (index, step) in steps.indexed)
              _StepRow(step: step, isNext: index == next),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isNext});

  final _Step step;
  final bool isNext;

  void _open(BuildContext context) {
    if (step.inTab) {
      context.openInTab(step.go);
    } else {
      context.push(step.go);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = step.done ? LizmoColors.slate : LizmoColors.ink;

    return InkWell(
      key: ValueKey('get-started-step-${step.label}'),
      onTap: step.done ? null : () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              step.done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: step.done ? LizmoColors.teal900 : LizmoColors.slate,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: LizmoType.rowName.copyWith(
                      color: ink,
                      decoration: step.done ? TextDecoration.lineThrough : null,
                      decorationColor: LizmoColors.slate,
                    ),
                  ),
                  if (!step.done) ...[
                    const SizedBox(height: 2),
                    Text(step.detail, style: LizmoType.rowSub),
                  ],
                ],
              ),
            ),
            if (isNext) ...[
              const SizedBox(width: 10),
              Material(
                color: LizmoColors.coral,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _open(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text('Do it',
                        style: LizmoType.buttonLabel.copyWith(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
