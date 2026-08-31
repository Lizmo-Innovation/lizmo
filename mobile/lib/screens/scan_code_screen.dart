import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../router.dart';

/// Reads a property code out of whatever a QR turned out to contain.
///
/// Accepts both a bare code and a URL ending in one. The QR carries the bare
/// code today, but it was briefly a link and may be again once there is a
/// domain — so a sign printed under either scheme has to keep working. A
/// scanner that only understood today's format would strand every code already
/// on a wall.
///
/// Returns null for anything that is not a Lizmo code, so a tenant pointing the
/// camera at a shop receipt or a Wi-Fi QR is told plainly rather than sent to a
/// lookup that will fail.
String? codeFromScan(String? raw) {
  if (raw == null) return null;

  var text = raw.trim();
  // A URL: the code is the last thing in the path. Query and fragment are
  // dropped first so ".../p/PHK7M4Q2?utm=poster" still reads.
  if (text.contains('/')) {
    text = text.split(RegExp(r'[?#]')).first;
    final segments = text.split('/').where((part) => part.isNotEmpty);
    if (segments.isEmpty) return null;
    text = segments.last;
  }

  final code = text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  // Mirrors chk_properties_code_shape. Checked here rather than left to the
  // server so the camera can keep looking instead of navigating to a certain
  // 404.
  return RegExp(r'^PH[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$').hasMatch(code)
      ? code
      : null;
}

/// Points the camera at the sign on the gate.
class ScanCodeScreen extends ConsumerStatefulWidget {
  const ScanCodeScreen({super.key});

  @override
  ConsumerState<ScanCodeScreen> createState() => _ScanCodeScreenState();
}

class _ScanCodeScreenState extends ConsumerState<ScanCodeScreen> {
  final _controller = MobileScannerController(
    // One format, so a barcode on a shampoo bottle does not even register.
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// A QR is read many times a second. Without this the first good code fires
  /// a navigation on every frame until the route changes.
  bool _handled = false;

  String? _rejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final code = codeFromScan(barcode.rawValue);
      if (code != null) {
        _handled = true;
        // Replaces rather than pushes: coming back from the property should
        // return to where the tenant started, not to a live camera.
        context.pushReplacement(Routes.propertyByCode(code));
        return;
      }
    }

    // Something scanned, and it was not one of ours. Said once rather than
    // flashed on every frame.
    final seen = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (seen != null && _rejected != seen) {
      setState(() => _rejected = seen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.ink,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Scan the code',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            // A code on a gate is read after dark as often as not.
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraUnavailable(error: error),
          ),
          const _Reticle(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Footer(rejected: _rejected),
          ),
        ],
      ),
    );
  }
}

/// A window in a dimmed field, so it is obvious where to point.
class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: LizmoColors.white, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.rejected});

  final String? rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LizmoColors.ink.withValues(alpha: 0.75),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rejected == null
                  ? 'Point the camera at the code on the gate.'
                  : 'That is a QR code, but not a Lizmo one.',
              textAlign: TextAlign.center,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              // Always offered, not only when the camera fails. Codes get read
              // out over the phone, and a cracked screen or a dirty lens is
              // somebody else's problem to work around.
              onPressed: () => context.pushReplacement(Routes.findProperty),
              child: Text(
                'Type it instead',
                style: LizmoType.rowName.copyWith(color: LizmoColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No camera, or permission refused.
///
/// Not a dead end: the same lookup works by typing, and that is one tap away.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return LizmoMessageState(
      tone: LizmoMessageTone.problem,
      icon: denied ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
      title: denied ? 'Camera not allowed' : "Can't open the camera",
      detail: denied
          ? 'Lizmo needs the camera to read a code. You can allow it in '
                'Settings, or type the code instead.'
          : 'Type the code instead — it is printed under the QR.',
      actionLabel: 'Type it instead',
      onAction: () => context.pushReplacement(Routes.findProperty),
    );
  }
}
