import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../property/property_labels.dart';
import '../property/property_providers.dart';

/// The code a landlord puts on the gate.
///
/// A screen of its own rather than a strip on the property page, because its
/// whole job is to be held up and pointed at: the QR wants to be large, bright
/// and uncluttered, and a landlord will screenshot this to print it.
class PropertyShareScreen extends ConsumerWidget {
  const PropertyShareScreen({super.key, required this.propertyId});

  final String propertyId;

  /// What the QR actually encodes: the code, and nothing else.
  ///
  /// It was briefly a https://lizmo.app/p/<code> URL, on the reasoning that a
  /// phone's own camera can act on a link and cannot act on a bare string.
  /// True, but there is no such domain — so the link resolved nowhere and the
  /// QR promised something it could not do. A code that a camera app merely
  /// displays is at least honest, and the tenant can type it.
  ///
  /// One function so that the day there is a domain, this is a single edit and
  /// old printed codes keep working — Lizmo's own scanner will accept both.
  static String qrPayloadFor(String code) => code;

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

/// Renders whatever [key]'s boundary is showing as PNG bytes.
///
/// A top-level function rather than a method on the screen so it can be tested
/// without driving the share sheet, which no test can open.
///
/// Captured at three times the logical size: this ends up printed on a sign or
/// zoomed into on somebody else's phone, and a QR resampled from a 1x capture
/// is exactly the kind of thing that scans on the screen it was made on and
/// fails on paper.
/// Marks the block that gets exported, so tests and tooling can find exactly
/// the boundary the share button captures.
const shareCardKey = ValueKey('share-card');

Future<Uint8List?> captureBoundaryPng(GlobalKey key, {double pixelRatio = 3}) async {
  final object = key.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;

  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class _Share extends StatefulWidget {
  const _Share({required this.property});

  final PropertyResponse property;

  @override
  State<_Share> createState() => _ShareState();
}

class _ShareState extends State<_Share> {
  /// Wraps only the part worth sending: the name, address, kind, QR and code.
  /// The explainer above it is instruction for the landlord, not something a
  /// tenant needs on a saved image.
  final _card = GlobalKey();

  bool _sharing = false;

  PropertyResponse get property => widget.property;

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await captureBoundaryPng(_card);
      if (png == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't make the image. Try again.")),
        );
        return;
      }

      final code = property.code ?? '';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              // Named so it is findable later in a gallery full of screenshots.
              name: 'lizmo-$code.png',
            ),
          ],
          // Carried alongside the image so the code survives being forwarded
          // into a chat that strips or compresses the picture.
          text: '${property.name ?? 'This place'} — Lizmo code $code',
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open sharing. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = property.code ?? '';
    // Larger than the app's usual scale throughout this page. It is read at
    // arm's length by whoever is being shown the phone, and often by somebody
    // older than the landlord holding it.
    final scale = context.lizmoTextScale;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Everything inside this boundary is what gets exported. The name,
          // address and kind travel with the code: an image of a QR alone,
          // forwarded into a group chat, tells nobody which building it opens.
          RepaintBoundary(
            key: _card,
            child: Container(
              // Painted rather than transparent: what is captured is exactly
              // what is drawn, and a boundary with no background of its own
              // exports with black behind it.
              key: shareCardKey,
              color: LizmoColors.canvas,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    property.name ?? 'This property',
                    style: LizmoType.sectionHeading.copyWith(
                      fontSize: 22 * scale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if ((property.address ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      property.address!,
                      style: LizmoType.rowSub.copyWith(fontSize: 15 * scale),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    propertyKindAndUsageLabel(property),
                    style: LizmoType.rowSub.copyWith(
                      color: LizmoColors.slate,
                      letterSpacing: 0.6,
                      fontSize: 14 * scale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _QrCard(code: code, scale: scale),
                  const SizedBox(height: 20),
                  _CodeRow(code: code, scale: scale),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Outside the boundary on purpose. The capture renders the live
          // widget tree, so a control left inside the card would be painted
          // into the picture somebody receives — a copy button they cannot
          // press, in an image of a building.
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: code));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Code copied')),
                );
              },
              icon: const Icon(Icons.copy_outlined,
                  size: 18, color: LizmoColors.teal900),
              label: Text(
                'Copy code',
                style: LizmoType.rowName.copyWith(
                  color: LizmoColors.teal900,
                  fontSize: 15 * scale,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Below the card too: this is instruction for the landlord holding
          // the phone, and would be nonsense to whoever receives the image.
          Text(
            'Show this to anyone looking for a room. They scan it, or type the '
            'code, and see what is vacant.',
            style: LizmoType.rowSub.copyWith(fontSize: 15 * scale),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),
          _sharing
              ? const _Sharing()
              : PrimaryActionButton(
                  label: 'Share or save this code',
                  onPressed: _shareCard,
                ),
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
  const _QrCard({required this.code, required this.scale});

  /// The code grows with the screen too. A QR that stayed 220pt on a tablet
  /// would sit in the middle of the page looking like an afterthought, and the
  /// larger it is drawn the further away it can be scanned.
  static const _baseQrSize = 220.0;

  final String code;
  final double scale;

  double get _qrSize => _baseQrSize * scale;

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
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: PropertyShareScreen.qrPayloadFor(code),
              version: QrVersions.auto,
              size: _qrSize,
              backgroundColor: Colors.white,
              // The whole reason the logo can sit in the middle at all. The
              // package defaults to level L, which recovers 7% of the code —
              // cover the centre of that and it stops scanning in poor light,
              // at an angle, or on a photocopied sign. H recovers 30%.
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              // Fixed rather than themed: a QR whose modules follow the app's
              // dark mode would invert, and an inverted QR does not scan.
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: LizmoColors.ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: LizmoColors.ink,
              ),
            ),
            _CentreMark(qrSize: _qrSize),
          ],
        ),
      ),
    );
  }
}

/// Lizmo's mark in the middle of the code: the teal tile, ringed in white.
///
/// icon.png rather than icon_foreground.png. The foreground layer is the
/// adaptive-icon mark alone — every opaque pixel in it is pure white, meant to
/// sit on a coloured background supplied by the launcher. Put it on a white
/// plate and it is invisible: a hole in the middle of the code. icon.png is
/// the whole icon, teal and opaque, which is what makes the mark readable.
///
/// The white ring is still ours, and still necessary: it separates the tile
/// from the modules so the two do not read as one shape.
///
/// Sized at a quarter of the QR's width — about 6% of its area, comfortably
/// inside what level H recovers. Growing it is the fastest way to make a code
/// that scans on a phone screen and fails on a wall.
class _CentreMark extends StatelessWidget {
  const _CentreMark({required this.qrSize});

  final double qrSize;

  double get _plate => qrSize * 0.25;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _plate,
      height: _plate,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
          // A missing asset should cost the landlord a logo, never the code
          // itself — the QR underneath is still perfectly scannable.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The code in type big enough to read across a room, and to copy.
class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code, required this.scale});

  final String code;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  style: LizmoType.rowSub.copyWith(
                    color: LizmoColors.teal900,
                    fontSize: 14 * scale,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  // Monospaced and spaced out: this gets read aloud and copied
                  // by hand more often than it gets scanned.
                  style: LizmoType.dataMedium.copyWith(
                    color: LizmoColors.teal900,
                    letterSpacing: 2,
                    // The largest thing on the page after the code itself.
                    // Most people will type this rather than scan it.
                    fontSize: 26 * scale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sharing extends StatelessWidget {
  const _Sharing();

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
