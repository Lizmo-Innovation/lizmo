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
  return () async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return (name: picked.name, bytes: await picked.readAsBytes());
  };
});
