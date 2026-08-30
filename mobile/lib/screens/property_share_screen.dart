import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../property/property_providers.dart';

/// The code a landlord puts on the gate.
///
/// A screen of its own rather than a strip on the property page, because its
/// whole job is to be held up and pointed at: the QR wants to be large, bright
/// and uncluttered, and a landlord will screenshot this to print it.
class PropertyShareScreen extends ConsumerWidget {
  const PropertyShareScreen({super.key, required this.propertyId});

  final String propertyId;

  /// What the QR actually encodes.
  ///
  /// A URL rather than the bare code, because a bare string does nothing when
  /// scanned with the phone's own camera — and that is how most people will try
  /// it first. Lizmo's own scanner accepts either.
  ///
  /// The domain has to be one we control before any of these are printed: until
  /// it resolves, a camera-app scan opens nothing. Deliberately in one place so
  /// it is a single edit rather than a hunt.
  static const _linkBase = 'https://lizmo.app/p/';

  static String linkFor(String code) => '$_linkBase$code';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyProvider(propertyId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Share this place',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: switch (property) {
          AsyncData(:final value) => _Share(property: value),
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

class _Share extends StatelessWidget {
  const _Share({required this.property});

  final PropertyResponse property;

  @override
  Widget build(BuildContext context) {
    final code = property.code ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            property.name ?? 'This property',
            style: LizmoType.sectionHeading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Show this to anyone looking for a room. They scan it, or type the '
            'code, and see what is free.',
            style: LizmoType.rowSub,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          _QrCard(code: code),

          const SizedBox(height: 20),
          _CodeRow(code: code),

          const SizedBox(height: 24),
          const _Note(),
        ],
      ),
    );
  }
}

/// The QR itself, on white whatever the theme.
///
/// Scanners read dark-on-light. Rendering this on the app's canvas colour would
/// still work, but a landlord photographing or printing the screen gets a
/// cleaner result from a plain white field with a quiet margin.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [LizmoColors.cardShadow],
        ),
        child: QrImageView(
          data: PropertyShareScreen.linkFor(code),
          version: QrVersions.auto,
          size: 220,
          backgroundColor: Colors.white,
          // Fixed rather than themed: a QR whose modules follow the app's dark
          // mode would invert, and an inverted QR does not scan.
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: LizmoColors.ink,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: LizmoColors.ink,
          ),
        ),
      ),
    );
  }
}

/// The code in type big enough to read across a room, and to copy.
class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: LizmoColors.tealBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property code',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  // Monospaced and spaced out: this gets read aloud and copied
                  // by hand more often than it gets scanned.
                  style: LizmoType.dataMedium.copyWith(
                    color: LizmoColors.teal900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy code',
            icon: const Icon(Icons.copy_outlined, color: LizmoColors.teal900),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: code));
              messenger.showSnackBar(
                const SnackBar(content: Text('Code copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: LizmoColors.amberText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This code belongs to this property for good. It never changes, '
              'and it is never given to another property — so a sign you put '
              'up today keeps working.',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
            ),
          ),
        ],
      ),
    );
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
      title: failure.isNetwork ? "Can't reach Lizmo" : "Can't show the code",
      detail: failure.message,
      actionLabel: 'Go back',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
