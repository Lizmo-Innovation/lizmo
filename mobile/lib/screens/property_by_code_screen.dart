import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../tenant/tenant_providers.dart';

/// What a tenant sees after entering the code: the place, and what is free.
///
/// Grouped by floor, because "is there anything on the second floor?" is the
/// question people actually ask in a boarding house.
class PropertyByCodeScreen extends ConsumerWidget {
  const PropertyByCodeScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyByCodeProvider(code));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          property.valueOrNull?.name ?? 'Finding…',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: switch (property) {
          AsyncData(:final value) => _Place(place: value),
          AsyncError(:final error) => _NotFound(failure: ApiFailure.from(error)),
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

class _Place extends StatelessWidget {
  const _Place({required this.place});

  final PropertyByCodeResponse place;

  @override
  Widget build(BuildContext context) {
    final floors = place.floors;
    final free = (place.vacantWholeUnits ?? 0) + (place.vacantBeds ?? 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(place.address ?? '', style: LizmoType.rowSub),
        const SizedBox(height: 4),
        Text(
          _kind(place),
          style: LizmoType.rowSub.copyWith(
            color: LizmoColors.slate,
            letterSpacing: 0.6,
          ),
        ),
        if ((place.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(place.description!, style: LizmoType.rowSub),
        ],

        const SizedBox(height: 20),
        Text(
          // The headline a tenant came for. Nothing free is a real answer and
          // says so plainly rather than showing an empty list.
          free == 0
              ? 'Nothing free here at the moment'
              : '$free ${free == 1 ? 'space' : 'spaces'} free',
          style: LizmoType.sectionHeading,
        ),
        const SizedBox(height: 12),

        for (final floor in floors) _Floor(floor: floor),
      ],
    );
  }

  static String _kind(PropertyByCodeResponse place) {
    final type = (place.type?.toString() ?? '')
        .toLowerCase()
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    final usage =
        place.usage == PropertyByCodeResponseUsageEnum.COMMERCIAL
            ? 'Commercial'
            : 'Residential';
    return type.isEmpty ? usage : '$usage · $type';
  }
}

class _Floor extends StatelessWidget {
  const _Floor({required this.floor});

  final VacancyFloor floor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            // Null means the landlord never said, which is normal in a
            // single-storey house — not a floor called nothing.
            floor.floor == null ? 'Ground level' : 'Floor ${floor.floor}',
            style: LizmoType.rowSub.copyWith(
              color: LizmoColors.slate,
              letterSpacing: 1,
            ),
          ),
        ),
        for (final unit in floor.wholeUnits)
          _Vacancy(
            title: 'Unit ${unit.unitNumber}',
            subtitle: unit.sizeSqm == null ? null : '${unit.sizeSqm} sqm',
            rent: unit.rent,
            utilities: unit.monthlyUtilities,
            utilitiesIncluded: unit.utilitiesIncluded ?? false,
            unitId: unit.unitId!,
            bedId: null,
          ),
        for (final bed in floor.bedspaces)
          _Vacancy(
            title: bed.bedLabel ?? 'Bed',
            subtitle: 'in ${bed.unitNumber}',
            rent: bed.rent,
            utilities: bed.monthlyUtilities,
            utilitiesIncluded: bed.utilitiesIncluded ?? false,
            unitId: bed.unitId!,
            bedId: bed.bedId,
          ),
      ],
    );
  }
}

/// One bed or unit that is free, and the button that asks for it.
class _Vacancy extends ConsumerStatefulWidget {
  const _Vacancy({
    required this.title,
    required this.subtitle,
    required this.rent,
    required this.utilities,
    required this.utilitiesIncluded,
    required this.unitId,
    required this.bedId,
  });

  final String title;
  final String? subtitle;
  final num? rent;
  final num? utilities;
  final bool utilitiesIncluded;
  final String unitId;
  final String? bedId;

  @override
  ConsumerState<_Vacancy> createState() => _VacancyState();
}

class _VacancyState extends ConsumerState<_Vacancy> {
  bool _asking = false;
  bool _asked = false;

  Future<void> _ask() async {
    setState(() => _asking = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(askingForARoomApiProvider).sendRentalRequest(
            RentalRequestCreate(unitId: widget.unitId, bedId: widget.bedId),
          );
      ref.invalidate(myRentalRequestsProvider);
      if (mounted) setState(() => _asked = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Sent. The landlord will reply.')),
      );
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (!mounted) return;

      if (failure.code == 'TENANT_PROFILE_INCOMPLETE') {
        // The server's message is written for a landlord reading about
        // somebody else — "this tenant cannot sign a lease yet". Said to the
        // tenant about themselves it has to be second person, and it has to
        // offer the way to fix it rather than only stating the problem.
        _offerToFinishTheProfile();
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  void _offerToFinishTheProfile() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LizmoColors.canvas,
        title: Text('Finish your profile first', style: LizmoType.rowName),
        content: Text(
          'Landlords need to know who they are letting to. Add your emergency '
          'contact, your ID details, and a photo of your ID and a 1x1 — then '
          'you can ask for this one.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Not now', style: LizmoType.rowSub),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(Routes.tenantProfile);
            },
            child: Text(
              'Open my profile',
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: LizmoType.rowName),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.subtitle!, style: LizmoType.rowSub),
                ],
                const SizedBox(height: 4),
                Text(_price(), style: LizmoType.rowSub),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_asked)
            Text(
              'Asked',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
            )
          else if (_asking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
              ),
            )
          else
            TextButton(
              onPressed: _ask,
              child: Text(
                'Ask for this',
                style: LizmoType.rowName.copyWith(color: LizmoColors.coral),
              ),
            ),
        ],
      ),
    );
  }

  /// What the tenant would actually hand over each month, which is what they
  /// are really comparing — not the rent line on its own.
  String _price() {
    final rent = widget.rent;
    if (rent == null) return 'Price not set';

    final base = '₱$rent a month';
    final utilities = widget.utilities;
    if (utilities == null) return base;
    return widget.utilitiesIncluded
        ? '$base, utilities included'
        : '$base, plus ₱$utilities utilities';
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return LizmoMessageState(
      tone: LizmoMessageTone.problem,
      icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.search_off,
      title: failure.isNetwork ? "Can't reach Lizmo" : 'No place with that code',
      detail: failure.isNetwork
          ? failure.message
          : 'Check the code and try again. Letters and numbers only — no O or '
                'I, those are zero and one.',
      actionLabel: 'Try another code',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
