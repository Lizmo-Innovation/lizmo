import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';
import '../property/property_providers.dart';

/// What the place looks like, on the landlord's own screen.
///
/// Somebody scanning the code used to get an address, a type and counts per
/// floor — enough to rule a place out, nowhere near enough to choose it. The
/// first photograph here is the one they see against the building, which is
/// why it can be moved.
class PropertyPhotosCard extends ConsumerStatefulWidget {
  const PropertyPhotosCard({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyPhotosCard> createState() => _PropertyPhotosCardState();
}

class _PropertyPhotosCardState extends ConsumerState<PropertyPhotosCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await work();
      ref.invalidate(propertyPhotosProvider(widget.propertyId));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(ImageSource from) async {
    final pick = from == ImageSource.camera
        ? ref.read(takePhotoProvider)
        : ref.read(pickGalleryImageProvider);
    final image = await pick();
    if (image == null) return;

    await _run(() async {
      await ref.read(propertiesApiProvider).addPropertyPhoto(
            widget.propertyId,
            http.MultipartFile.fromBytes('file', image.bytes,
                filename: image.name),
          );
    });
  }

  Future<void> _offerSources() async {
    final from = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: LizmoColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo-from-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo', style: LizmoType.rowName),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              key: const ValueKey('photo-from-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery', style: LizmoType.rowName),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (from != null) await _add(from);
  }

  /// Moves one to the front, which is the only ordering question anybody
  /// actually has: a landlord cares which photograph represents the place,
  /// not whether the fifth comes before the sixth.
  Future<void> _makeCover(List<PropertyPhoto> photos, PropertyPhoto photo) {
    final ids = [
      photo.id!,
      for (final other in photos)
        if (other.id != photo.id) other.id!,
    ];
    return _run(() async {
      await ref
          .read(propertiesApiProvider)
          .reorderPropertyPhotos(widget.propertyId, PhotoOrder(ids: ids));
    });
  }

  Future<void> _remove(PropertyPhoto photo) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LizmoColors.white,
        title: Text('Remove this photo?', style: LizmoType.sectionHeading),
        content: Text(
          'Anybody who scans your code stops seeing it.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const ValueKey('confirm-remove-photo'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove', style: TextStyle(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (sure != true) return;

    await _run(() async {
      await ref
          .read(propertiesApiProvider)
          .deletePropertyPhoto(widget.propertyId, photo.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos =
        ref.watch(propertyPhotosProvider(widget.propertyId)).valueOrNull ??
            const <PropertyPhoto>[];
    final room = photos.length < 8;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        key: const ValueKey('property-photos'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                  child: Text('Photos', style: LizmoType.sectionHeading),
                ),
                if (room)
                  TextButton(
                    key: const ValueKey('add-photo'),
                    onPressed: _busy ? null : _offerSources,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Add',
                        style: LizmoType.rowName
                            .copyWith(color: LizmoColors.teal900)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              photos.isEmpty
                  ? 'Somebody scanning your code sees an address and a price. '
                      'A photo is what makes them ask.'
                  : 'The first one is what they see against the place. '
                      '${photos.length} of 8.',
              style: LizmoType.rowSub,
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _Photo(
                    photo: photos[index],
                    cover: index == 0,
                    busy: _busy,
                    onMakeCover: () => _makeCover(photos, photos[index]),
                    onRemove: () => _remove(photos[index]),
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

class _Photo extends StatelessWidget {
  const _Photo({
    required this.photo,
    required this.cover,
    required this.busy,
    required this.onMakeCover,
    required this.onRemove,
  });

  final PropertyPhoto photo;
  final bool cover;
  final bool busy;
  final VoidCallback onMakeCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: LizmoColors.canvas,
                child: photo.url == null
                    ? const Icon(Icons.image_outlined, color: LizmoColors.slate)
                    : Image.network(
                        photo.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: LizmoColors.slate),
                      ),
              ),
            ),
          ),
          if (cover)
            const Positioned(
              left: 6,
              top: 6,
              child: StatusChip(status: LizmoStatus.paid, label: 'Cover'),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: PopupMenuButton<String>(
              key: ValueKey('photo-menu-${photo.id}'),
              enabled: !busy,
              tooltip: 'More',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: LizmoColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_horiz, size: 16),
              ),
              onSelected: (choice) =>
                  choice == 'cover' ? onMakeCover() : onRemove(),
              itemBuilder: (context) => [
                if (!cover)
                  const PopupMenuItem(
                    key: ValueKey('make-cover'),
                    value: 'cover',
                    child: Text('Make this the cover'),
                  ),
                const PopupMenuItem(
                  key: ValueKey('remove-photo'),
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
