import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';

/// A unit's fixed monthly utility charges.
///
/// Fixed is the whole point: the landlord sets a figure once and stops
/// recalculating it every month, and the tenant knows what they owe before the
/// bill arrives. Nothing here reads a meter.
///
/// Each utility is independent — a boarding house may include WiFi and bill
/// water separately, or any combination — so the three switches never affect
/// one another.
class UnitUtilitiesScreen extends ConsumerStatefulWidget {
  const UnitUtilitiesScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
  });

  final String propertyId;
  final String unitId;

  @override
  ConsumerState<UnitUtilitiesScreen> createState() => _UnitUtilitiesScreenState();
}

class _UnitUtilitiesScreenState extends ConsumerState<UnitUtilitiesScreen> {
  final _formKey = GlobalKey<FormState>();

  /// What is on screen, before saving. Seeded once from the API so a rebuild
  /// never overwrites what the landlord has typed.
  final Map<UtilityResponseKindEnum, bool> _enabled = {};
  final Map<UtilityResponseKindEnum, TextEditingController> _amounts = {};

  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seed(List<UtilityResponse> utilities) {
    for (final utility in utilities) {
      final kind = utility.kind;
      if (kind == null) continue;
      _enabled[kind] = utility.enabled ?? false;
      _amounts[kind] = TextEditingController(text: utility.amount?.toString() ?? '');
    }
    _seeded = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(unitsApiProvider).setUtilities(
            widget.unitId,
            UtilitiesRequest(
              utilities: [
                for (final entry in _enabled.entries)
                  UtilityRequest(
                    kind: UtilityRequestKindEnum.fromJson(entry.key.toJson())!,
                    enabled: entry.value,
                    // Blank leaves whatever figure is stored, which is what
                    // lets an amount survive being switched off.
                    amount: _parse(_amounts[entry.key]?.text),
                  ),
              ],
            ),
          );

      ref.invalidate(utilitiesProvider(widget.unitId));
      // The unit's monthly utilities figure moves with it.
      ref.invalidate(unitProvider(widget.unitId));
      ref.invalidate(unitsProvider(widget.propertyId));

      if (mounted) context.pop();
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static num? _parse(String? text) {
    final trimmed = (text ?? '').trim();
    return trimmed.isEmpty ? null : num.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final utilities = ref.watch(utilitiesProvider(widget.unitId));

    if (!_seeded) {
      switch (utilities) {
        case AsyncData(:final value):
          _seed(value);
        case AsyncError(:final error):
          return _LoadFailed(failure: ApiFailure.from(error));
        default:
          return const _LoadingScaffold();
      }
    }

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Utilities', style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A fixed amount each month, charged on top of rent. Switch off '
                  'anything you include for free or bill separately.',
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 18),

                for (final kind in _enabled.keys) ...[
                  _UtilityRow(
                    kind: kind,
                    enabled: _enabled[kind]!,
                    controller: _amounts[kind]!,
                    onToggled: (on) => setState(() => _enabled[kind] = on),
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 4),
                _Total(enabled: _enabled, amounts: _amounts),

                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: _error!),
                ],

                const SizedBox(height: 28),
                _saving
                    ? const _SavingButton()
                    : PrimaryActionButton(label: 'Save utilities', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One switch and its amount.
class _UtilityRow extends StatelessWidget {
  const _UtilityRow({
    required this.kind,
    required this.enabled,
    required this.controller,
    required this.onToggled,
  });

  final UtilityResponseKindEnum kind;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggled;

  static const _labels = {
    'WIFI': 'WiFi',
    'ELECTRICITY': 'Electricity',
    'WATER': 'Water',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[kind.toJson()] ?? kind.toJson();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: LizmoType.rowName)),
              Switch(
                value: enabled,
                activeThumbColor: LizmoColors.white,
                activeTrackColor: LizmoColors.teal900,
                onChanged: onToggled,
              ),
            ],
          ),
          TextFormField(
            controller: controller,
            // Editable even when switched off: a landlord may set next month's
            // figure before turning it on.
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              prefixText: '₱ ',
              hintText: '500',
              hintStyle: LizmoType.rowSub,
              isDense: true,
              errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                // Only a problem if it is actually being charged.
                return enabled ? 'Set an amount, or switch $label off' : null;
              }
              final parsed = num.tryParse(text);
              if (parsed == null) return 'Enter an amount';
              // Zero would read as free, which is what switching off means.
              if (parsed <= 0) return 'Enter more than zero';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

/// What the switched-on utilities come to, moving as the switches do.
class _Total extends StatelessWidget {
  const _Total({required this.enabled, required this.amounts});

  final Map<UtilityResponseKindEnum, bool> enabled;
  final Map<UtilityResponseKindEnum, TextEditingController> amounts;

  @override
  Widget build(BuildContext context) {
    num total = 0;
    for (final entry in enabled.entries) {
      if (!entry.value) continue;
      total += num.tryParse(amounts[entry.key]?.text.trim() ?? '') ?? 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Each month', style: LizmoType.rowName),
        Text(total == 0 ? '—' : '₱$total', style: LizmoType.dataMedium),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.redBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: LizmoColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );
  }
}

class _SavingButton extends StatelessWidget {
  const _SavingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: LizmoColors.coral.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
          title: failure.isNetwork ? "Can't reach Lizmo" : "Can't open utilities",
          detail: failure.message,
          actionLabel: 'Go back',
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
