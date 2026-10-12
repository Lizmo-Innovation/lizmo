import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/place_details.dart';
import '../property/property_providers.dart';

/// What a tenant wants to know before asking, set once by the landlord.
///
/// Choices rather than typing, so it takes a minute, and every one can be
/// left unsaid: tapping a chosen answer again takes it back, because "not
/// said" is a real answer and not the same as "no".
class PlaceDetailsScreen extends ConsumerWidget {
  const PlaceDetailsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(placeDetailsProvider(propertyId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Place details',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.error_outline,
          title: 'Could not load them',
          detail: ApiFailure.from(error).message,
        ),
        data: (loaded) => _Form(
          propertyId: propertyId,
          initial: loaded ?? PlaceDetailsDto(),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.propertyId, required this.initial});

  final String propertyId;
  final PlaceDetailsDto initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late String? _who = widget.initial.whoCanRent?.toJson();
  late String? _curfew = widget.initial.curfew;
  late String? _visitors = widget.initial.visitors?.toJson();
  late bool? _cooking = widget.initial.cooking;
  late bool? _pets = widget.initial.pets;
  late bool? _smoking = widget.initial.smoking;
  late final _other = TextEditingController(text: widget.initial.otherRules ?? '');
  late int? _deposit = widget.initial.depositMonths;
  late int? _advance = widget.initial.advanceMonths;
  late final Set<String> _amenities = {
    for (final amenity in widget.initial.amenities) amenity.toJson(),
  };

  bool _saving = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _pickCurfew() async {
    final current = _curfew?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 22, minute: 0)
          : TimeOfDay(hour: int.parse(current[0]), minute: int.parse(current[1])),
      helpText: 'Doors close at',
    );
    if (picked == null) return;
    setState(() => _curfew =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(propertiesApiProvider).savePlaceDetails(
            widget.propertyId,
            PlaceDetailsDto(
              whoCanRent: PlaceDetailsDtoWhoCanRentEnum.fromJson(_who),
              curfew: _curfew,
              visitors: PlaceDetailsDtoVisitorsEnum.fromJson(_visitors),
              cooking: _cooking,
              pets: _pets,
              smoking: _smoking,
              otherRules: _other.text.trim().isEmpty ? null : _other.text.trim(),
              depositMonths: _deposit,
              advanceMonths: _advance,
              amenities: [
                for (final amenity in PlaceDetailsDtoAmenitiesEnum.values)
                  if (_amenities.contains(amenity.toJson())) amenity,
              ],
            ),
          );
      ref.invalidate(placeDetailsProvider(widget.propertyId));
      messenger.showSnackBar(const SnackBar(
          content: Text('Saved. Anybody who scans your code sees it now.')));
      navigator.maybePop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            children: [
              Text(
                'What people ask before anything else. It shows on the page they '
                'see after scanning your code. Leave out anything you would '
                'rather talk about; tap a choice again to take it back.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 16),

              _Section(
                title: 'Who can rent',
                children: [
                  _Choices<String>(
                    keyPrefix: 'who',
                    options: const [
                      ('ANYONE', 'Anyone'),
                      ('WOMEN', 'Women only'),
                      ('MEN', 'Men only'),
                    ],
                    selected: _who,
                    onChanged: (value) => setState(() => _who = value),
                  ),
                ],
              ),

              _Section(
                title: 'House rules',
                children: [
                  _Row(
                    label: 'Curfew',
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(
                          key: const ValueKey('curfew-time'),
                          label: _curfew == null
                              ? 'Set a time'
                              : 'Doors close ${curfewLabel(_curfew!)}',
                          selected: _curfew != null,
                          onTap: _pickCurfew,
                        ),
                        if (_curfew != null)
                          TextButton(
                            key: const ValueKey('curfew-clear'),
                            onPressed: () => setState(() => _curfew = null),
                            child: Text('No curfew', style: LizmoType.rowSub),
                          ),
                      ],
                    ),
                  ),
                  _Row(
                    label: 'Visitors',
                    child: _Choices<String>(
                      keyPrefix: 'visitors',
                      options: const [
                        ('ALLOWED', 'Welcome'),
                        ('DAYTIME', 'Daytime only'),
                        ('NONE', 'Not allowed'),
                      ],
                      selected: _visitors,
                      onChanged: (value) => setState(() => _visitors = value),
                    ),
                  ),
                  _Row(
                    label: 'Cooking',
                    child: _YesNo(
                      keyPrefix: 'cooking',
                      value: _cooking,
                      onChanged: (value) => setState(() => _cooking = value),
                    ),
                  ),
                  _Row(
                    label: 'Pets',
                    child: _YesNo(
                      keyPrefix: 'pets',
                      value: _pets,
                      onChanged: (value) => setState(() => _pets = value),
                    ),
                  ),
                  _Row(
                    label: 'Smoking',
                    child: _YesNo(
                      keyPrefix: 'smoking',
                      value: _smoking,
                      yes: 'Outside',
                      onChanged: (value) => setState(() => _smoking = value),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    key: const ValueKey('other-rules'),
                    controller: _other,
                    maxLength: 1000,
                    minLines: 2,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Anything else',
                      hintText: 'Shoes off inside. Quiet after 10.',
                      filled: true,
                      fillColor: LizmoColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),

              _Section(
                title: 'Money up front',
                subtitle: 'In months, so it fits each room’s rent. Filled in '
                    'for you when you start a lease.',
                children: [
                  _Row(
                    label: 'Deposit',
                    child: _Choices<int>(
                      keyPrefix: 'deposit',
                      options: [for (var m = 0; m <= 3; m++) (m, monthsLabel(m))],
                      selected: _deposit,
                      onChanged: (value) => setState(() => _deposit = value),
                    ),
                  ),
                  _Row(
                    label: 'Advance',
                    child: _Choices<int>(
                      keyPrefix: 'advance',
                      options: [for (var m = 0; m <= 3; m++) (m, monthsLabel(m))],
                      selected: _advance,
                      onChanged: (value) => setState(() => _advance = value),
                    ),
                  ),
                ],
              ),

              _Section(
                title: 'What is included',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amenity in PlaceDetailsDtoAmenitiesEnum.values)
                        _Chip(
                          key: ValueKey('amenity-${amenity.toJson()}'),
                          label: amenityLabel(amenity.toJson()),
                          icon: amenityIcon(amenity.toJson()),
                          selected: _amenities.contains(amenity.toJson()),
                          onTap: () => setState(() {
                            final key = amenity.toJson();
                            _amenities.contains(key)
                                ? _amenities.remove(key)
                                : _amenities.add(key);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PrimaryActionButton(
              key: const ValueKey('save-place-details'),
              label: _saving ? 'Saving…' : 'Save',
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LizmoType.sectionHeading),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: LizmoType.rowSub),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LizmoType.rowName.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// One of several, or none: tapping the chosen one again takes it back.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          _Chip(
            key: ValueKey('$keyPrefix-$value'),
            label: label,
            selected: selected == value,
            onTap: () => onChanged(selected == value ? null : value),
          ),
      ],
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
    this.yes = 'Allowed',
  });

  final String keyPrefix;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String yes;

  @override
  Widget build(BuildContext context) {
    return _Choices<bool>(
      keyPrefix: keyPrefix,
      options: [(true, yes), (false, 'Not allowed')],
      selected: value,
      onChanged: onChanged,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? LizmoColors.teal900 : LizmoColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LizmoColors.tealBg : LizmoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
            ] else if (selected) ...[
              Icon(Icons.check, size: 16, color: ink),
              const SizedBox(width: 4),
            ],
            Text(label, style: LizmoType.rowName.copyWith(fontSize: 13, color: ink)),
          ],
        ),
      ),
    );
  }
}
