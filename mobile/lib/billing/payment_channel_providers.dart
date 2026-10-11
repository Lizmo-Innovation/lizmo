import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// How a landlord's tenants pay them.
final paymentChannelsApiProvider = Provider<PaymentChannelsApi>((ref) {
  return PaymentChannelsApi(ref.watch(apiClientProvider));
});

/// This landlord's own list, hidden channels included, in their order.
final myPaymentChannelsProvider =
    FutureProvider.autoDispose<List<PaymentChannelResponse>>((ref) async {
  try {
    return await ref.watch(paymentChannelsApiProvider).listMyPaymentChannels() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The line under their channels. Null when there is none.
final myPaymentNoteProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    final answer = await ref.watch(paymentChannelsApiProvider).getMyPaymentNote();
    final text = answer?.note?.trim();
    return text == null || text.isEmpty ? null : text;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// An image chosen from the phone, as bytes ready to upload.
typedef PickedImage = ({String name, Uint8List bytes});

/// Opens the gallery for one image.
///
/// A provider so tests can hand back bytes without a plugin or a phone.
final pickGalleryImageProvider = Provider<Future<PickedImage?> Function()>((ref) {
  return () => _pick(ImageSource.gallery);
});

/// The camera, for a landlord standing in front of their own building.
///
/// Separate from the gallery rather than a parameter, so a test can hand back
/// bytes for one without stubbing the other.
final takePhotoProvider = Provider<Future<PickedImage?> Function()>((ref) {
  return () => _pick(ImageSource.camera);
});

/// Shrunk on the phone before it is sent: the server re-encodes anyway, and
/// a 12-megapixel original is a slow upload on a jeepney's worth of signal.
Future<PickedImage?> _pick(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 90,
  );
  if (picked == null) return null;
  return (name: picked.name, bytes: await picked.readAsBytes());
}
