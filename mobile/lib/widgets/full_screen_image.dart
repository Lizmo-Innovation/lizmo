import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// One photograph, as large as the screen allows.
///
/// A 120px thumbnail proves a document was uploaded; it does not let anybody
/// read the number on it, check a face against the person at the door, or see
/// that a photo is of somebody's thumb. All of which are the reason a landlord
/// opens this screen at all.
///
/// Pinch and drag are handled by InteractiveViewer rather than written here:
/// an ID photographed at an angle is often only legible zoomed into one
/// corner.
class FullScreenImage extends StatelessWidget {
  const FullScreenImage({super.key, required this.url, required this.label});

  final String url;
  final String label;

  static Future<void> show(BuildContext context, String url, String label) {
    return showDialog<void>(
      context: context,
      // Near-black rather than the usual scrim: a photograph is easier to
      // read against something that is not competing with it.
      barrierColor: Colors.black87,
      builder: (_) => FullScreenImage(url: url, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Tapping the backdrop closes it, which is what people try first.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
                        ),
                      ),
                // The URL is presigned and short-lived, so an expired one is
                // an ordinary outcome here rather than a fault. Saying which
                // it is beats a broken-image glyph on a black screen.
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 40, color: LizmoColors.white),
                      const SizedBox(height: 12),
                      Text(
                        'That photograph could not be loaded. Close this and '
                        'open the tenant again.',
                        textAlign: TextAlign.center,
                        style: LizmoType.rowSub
                            .copyWith(color: LizmoColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('close-photo'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: LizmoColors.white),
                    tooltip: 'Close',
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: LizmoType.rowName
                          .copyWith(color: LizmoColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
