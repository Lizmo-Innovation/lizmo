import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo or PDF chosen to send, before it is sent.
class PendingFile {
  const PendingFile({
    required this.name,
    required this.bytes,
    this.pdf = false,
  });

  final String name;
  final Uint8List bytes;
  final bool pdf;
}

/// Where photos and PDFs come from: the camera, the gallery, the files app.
///
/// Behind a provider so a test can hand some over without a phone.
abstract class AttachmentPicker {
  Future<PendingFile?> camera();
  Future<List<PendingFile>> photos(int most);
  Future<PendingFile?> pdf();
}

/// The phone's own pickers.
///
/// Photos are shrunk here, before they travel: the server re-encodes them
/// anyway, and four full-size photos would be most of a mobile data day.
class DevicePicker implements AttachmentPicker {
  const DevicePicker();

  static const _edge = 2000.0;
  static const _quality = 85;

  @override
  Future<PendingFile?> camera() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: _edge,
      maxHeight: _edge,
      imageQuality: _quality,
    );
    if (shot == null) return null;
    return PendingFile(name: shot.name, bytes: await shot.readAsBytes());
  }

  @override
  Future<List<PendingFile>> photos(int most) async {
    if (most <= 0) return const [];
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: _edge,
      maxHeight: _edge,
      imageQuality: _quality,
      limit: most > 1 ? most : null,
    );
    return [
      for (final file in picked.take(most))
        PendingFile(name: file.name, bytes: await file.readAsBytes()),
    ];
  }

  @override
  Future<PendingFile?> pdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return PendingFile(name: file.name, bytes: bytes, pdf: true);
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => const DevicePicker(),
);

/// A sent photo, cached by what it is rather than by its link.
///
/// The links last an hour and come back new every time the conversation is
/// read -- every five seconds while somebody is talking. Cached by link, each
/// read would fetch every photo in the thread again.
class AttachmentImage extends ImageProvider<AttachmentImage> {
  const AttachmentImage(this.url, {required this.id});

  final String url;

  /// The attachment, and which copy of it: "preview-…" or "full-…".
  final String id;

  @override
  Future<AttachmentImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<AttachmentImage>(this);

  @override
  ImageStreamCompleter loadImage(
    AttachmentImage key,
    ImageDecoderCallback decode,
  ) {
    final network = NetworkImage(key.url);
    return network.loadImage(network, decode);
  }

  @override
  bool operator ==(Object other) => other is AttachmentImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// "820 KB", "4.2 MB".
String fileSize(num? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
