import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// What the tenant described, and the photos they chose.
class ReportedProblem {
  const ReportedProblem({required this.description, required this.photos});

  final String description;
  final List<PickedPhoto> photos;
}

/// A photo already read into memory, so it can be shown before it is sent.
class PickedPhoto {
  const PickedPhoto({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Reporting something broken.
///
/// A description and nothing else required, as the spec has it: no category,
/// no priority. Somebody with water on the floor should not be asked which of
/// eight kinds of leak it is.
class ReportProblemSheet extends StatefulWidget {
  const ReportProblemSheet({super.key});

  static const maxPhotos = 3;

  static Future<ReportedProblem?> show(BuildContext context) {
    return showModalBottomSheet<ReportedProblem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReportProblemSheet(),
    );
  }

  @override
  State<ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<ReportProblemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _photos = <PickedPhoto>[];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final room = ReportProblemSheet.maxPhotos - _photos.length;
    if (room <= 0) return;

    final picked = await ImagePicker().pickMultiImage(
      // A courtesy to the connection: the server re-encodes anyway.
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
      limit: room > 1 ? room : null,
    );
    if (picked.isEmpty) return;

    final read = <PickedPhoto>[];
    for (final file in picked.take(room)) {
      read.add(PickedPhoto(name: file.name, bytes: await file.readAsBytes()));
    }
    if (!mounted) return;
    setState(() => _photos.addAll(read));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(ReportedProblem(
      description: _description.text.trim(),
      photos: List.unmodifiable(_photos),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final full = _photos.length >= ReportProblemSheet.maxPhotos;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report a problem',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                'Your landlord is told straight away, and you can follow what '
                'happens to it here.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 20),
              Text('What is wrong',
                  style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('problem-description'),
                controller: _description,
                maxLines: 4,
                maxLength: 2000,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
                decoration: _field(
                        'The tap in the bathroom will not stop dripping.')
                    .copyWith(counterText: ''),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Say what is broken'
                    : null,
              ),
              const SizedBox(height: 18),
              Text('Photos', style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              if (_photos.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, photo) in _photos.indexed)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(photo.bytes,
                                width: 84, height: 84, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: InkWell(
                              key: ValueKey('remove-photo-$index'),
                              onTap: () =>
                                  setState(() => _photos.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: LizmoColors.ink,
                                child: Icon(Icons.close,
                                    size: 14, color: LizmoColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                key: const ValueKey('add-photos'),
                onPressed: full ? null : _addPhotos,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(
                  full ? 'That is three' : 'Add photos',
                  style: LizmoType.rowName.copyWith(
                    color: full ? LizmoColors.slate : LizmoColors.teal900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.teal900,
                  side: const BorderSide(color: Color(0xFFE3E8E6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional, up to three. A photo often saves your landlord a '
                'trip to come and look.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('send-report'),
                label: 'Send to my landlord',
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: LizmoType.rowSub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _field(String hint) {
  OutlineInputBorder border(Color colour) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colour),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: LizmoType.rowSub,
    filled: true,
    fillColor: LizmoColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(const Color(0xFFE3E8E6)),
    focusedBorder: border(LizmoColors.teal900),
    errorBorder: border(LizmoColors.red),
    focusedErrorBorder: border(LizmoColors.red),
    errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
  );
}
