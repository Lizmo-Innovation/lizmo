import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import 'document_download.dart';
import 'full_screen_image.dart';

/// The paperwork a landlord keeps against a tenancy.
///
/// Unlike everything else on the tenant screen, these survive the tenancy —
/// a dispute happens after somebody has moved out, and that is when the signed
/// contract is wanted.
///
/// Each row carries who can see it. That is deliberately on the row rather
/// than hidden in a menu: a landlord who cannot tell at a glance which
/// documents their tenant is reading will eventually share the wrong one.
class LeaseAttachments extends ConsumerStatefulWidget {
  const LeaseAttachments({super.key, required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<LeaseAttachments> createState() => _LeaseAttachmentsState();
}

class _LeaseAttachmentsState extends ConsumerState<LeaseAttachments> {
  bool _busy = false;
  String? _error;

  Future<void> _add() async {
    setState(() => _error = null);

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
      withData: true,
    );
    // Cancelling the picker is not an error.
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'That file could not be read. Try another.');
      return;
    }

    // The picker is a separate activity on Android and this widget can be
    // gone by the time it returns.
    if (!mounted) return;

    final choice = await _AddSheet.show(context, file.name);
    if (choice == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(leasesApiProvider)
          .uploadLeaseDocument(
            widget.leaseId,
            http.MultipartFile.fromBytes('file', bytes, filename: file.name),
            docType: choice.docType,
            label: choice.label,
            sharedWithTenant: choice.shared,
          );
      ref.invalidate(leaseDocumentsProvider(widget.leaseId));
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setShared(LeaseDocumentResponse document, bool shared) async {
    setState(() => _error = null);
    try {
      await ref
          .read(leasesApiProvider)
          .updateLeaseDocument(
            widget.leaseId,
            document.id!,
            sharedWithTenant: shared,
          );
      ref.invalidate(leaseDocumentsProvider(widget.leaseId));
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    }
  }

  Future<void> _delete(LeaseDocumentResponse document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this document?'),
        // Said plainly. There is no copy of this anywhere else, and the
        // tenant may be relying on it too.
        content: Text(
          '${document.label ?? 'This document'} will be removed for good, for '
          'you and for your tenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: LizmoType.rowName.copyWith(color: LizmoColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(leasesApiProvider)
          .deleteLeaseDocument(widget.leaseId, document.id!);
      ref.invalidate(leaseDocumentsProvider(widget.leaseId));
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(leaseDocumentsProvider(widget.leaseId));
    final rows = documents.valueOrNull ?? const <LeaseDocumentResponse>[];

    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Text('Attachments', style: LizmoType.sectionHeading),
              ),
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  key: const ValueKey('add-attachment'),
                  onPressed: _add,
                  child: Text(
                    'Add',
                    style: LizmoType.rowSub.copyWith(
                      color: LizmoColors.teal900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            'The signed contract, receipts, anything worth keeping. These stay '
            'after the tenancy ends.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 10),

          if (documents.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            Text('Nothing attached yet.', style: LizmoType.rowSub)
          else
            for (final document in rows)
              _Row(
                document: document,
                onShare: (shared) => _setShared(document, shared),
                onDelete: () => _delete(document),
              ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.document,
    required this.onShare,
    required this.onDelete,
  });

  final LeaseDocumentResponse document;
  final ValueChanged<bool> onShare;
  final VoidCallback onDelete;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _saving = false;

  bool get _isPdf => widget.document.contentType == 'application/pdf';

  /// A landlord could file paperwork and then never look at it again: the row
  /// carried only "share" and "delete". Opening your own contract is the
  /// obvious thing to want from a list of contracts.
  Future<void> _open() async {
    if (!_isPdf) {
      FullScreenImage.show(
        context,
        widget.document.url ?? '',
        widget.document.label ?? 'Document',
      );
      return;
    }

    setState(() => _saving = true);
    final error = await DocumentDownload.save(widget.document);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) showDownloadError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final isPdf = _isPdf;
    final shared = document.sharedWithTenant == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // The icon is inside the tap target, not beside it. It is the most
          // obvious thing to reach for, and a document icon that does nothing
          // when tapped reads as a row that does nothing.
          Expanded(
            child: InkWell(
              key: ValueKey('open-${document.id}'),
              onTap: _saving ? null : _open,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                      size: 20,
                      color: LizmoColors.slate,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.label ?? 'Document',
                            style: LizmoType.rowName.copyWith(
                              color: LizmoColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Who can see it, and what tapping does, on one
                          // line. The second line is the only room there is,
                          // and both facts have to fit in it.
                          Text(
                            '${shared ? 'Your tenant can see this' : 'Only you can see this'}'
                            ' · ${isPdf ? 'Tap to download' : 'Tap to view'}',
                            style: LizmoType.rowSub.copyWith(
                              fontSize: 11,
                              color: shared
                                  ? LizmoColors.teal900
                                  : LizmoColors.slate,
                            ),
                            // Two lines: "Your tenant can see this · Tap to
                            // download" does not fit on one at this width, and
                            // truncating it hides the half that says what
                            // tapping does.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            key: ValueKey('share-${document.id}'),
            onPressed: () => widget.onShare(!shared),
            icon: Icon(
              shared
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: shared ? LizmoColors.teal900 : LizmoColors.slate,
            ),
            tooltip: shared
                ? 'Stop sharing with the tenant'
                : 'Share with the tenant',
          ),
          IconButton(
            key: ValueKey('delete-${document.id}'),
            onPressed: widget.onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: LizmoColors.slate,
            ),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

/// What kind of document this is, what to call it, and who may read it.
///
/// Asked after the file is chosen rather than before: picking is the part
/// somebody might abandon, and three questions in front of that is three
/// reasons not to bother.
class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.filename});

  final String filename;

  static Future<_Choice?> show(BuildContext context, String filename) {
    return showModalBottomSheet<_Choice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSheet(filename: filename),
    );
  }

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _Choice {
  const _Choice({
    required this.docType,
    required this.label,
    required this.shared,
  });

  final String docType;
  final String label;
  final bool shared;
}

class _AddSheetState extends State<_AddSheet> {
  late final TextEditingController _label = TextEditingController(
    text: _stripExtension(widget.filename),
  );

  String _docType = 'LEASE_CONTRACT';

  // Defaults to shared: the commonest attachment is the contract, and a lease
  // one party cannot read is not much of an agreement.
  bool _shared = true;

  static const _kinds = {
    'LEASE_CONTRACT': 'Lease contract',
    'RECEIPT': 'Receipt',
    'OTHER': 'Something else',
  };

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  static String _stripExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot <= 0 ? filename : filename.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Attach a document', style: LizmoType.sectionHeading),
            const SizedBox(height: 14),

            Text('What is it?', style: LizmoType.rowSub),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in _kinds.entries)
                  ChoiceChip(
                    key: ValueKey('kind-${entry.key}'),
                    label: Text(entry.value),
                    selected: _docType == entry.key,
                    onSelected: (_) => setState(() => _docType = entry.key),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            Text('Name', style: LizmoType.rowSub),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('attachment-label'),
              controller: _label,
              decoration: const InputDecoration(
                filled: true,
                fillColor: LizmoColors.white,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('attachment-shared'),
              contentPadding: EdgeInsets.zero,
              value: _shared,
              onChanged: (value) => setState(() => _shared = value),
              title: Text('Let the tenant see it', style: LizmoType.rowName),
              subtitle: Text(
                _shared
                    ? 'They will find it under their lease.'
                    : 'Kept for your records only.',
                style: LizmoType.rowSub,
              ),
            ),

            const SizedBox(height: 14),
            PrimaryActionButton(
              label: 'Attach',
              onPressed: () => Navigator.of(context).pop(
                _Choice(
                  docType: _docType,
                  label: _label.text.trim(),
                  shared: _shared,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
