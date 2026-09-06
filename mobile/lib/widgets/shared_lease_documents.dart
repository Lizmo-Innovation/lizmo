import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import 'document_download.dart';
import 'full_screen_image.dart';

/// Paperwork the landlord has shared with this tenant.
///
/// Read only, and only what was shared — the filtering happens on the server,
/// so nothing here decides what a tenant may see.
///
/// Renders nothing when the list is empty. The screen it sits on already
/// explains what a tenancy does and does not record yet, and an empty
/// "Documents" panel underneath that would read as a fault rather than as an
/// absence.
class SharedLeaseDocuments extends ConsumerWidget {
  const SharedLeaseDocuments({super.key, required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(myLeaseDocumentsProvider(leaseId));
    final rows = documents.valueOrNull ?? const <LeaseDocumentResponse>[];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your documents', style: LizmoType.sectionHeading),
          const SizedBox(height: 4),
          Text(
            'Shared by your landlord. Yours to keep, including after you move '
            'out.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 10),
          for (final document in rows) _Row(document: document),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.document});

  final LeaseDocumentResponse document;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _saving = false;

  bool get _isPdf => widget.document.contentType == 'application/pdf';

  Future<void> _open() async {
    // An image is worth looking at in place; a PDF is worth keeping. The link
    // behind either lapses in minutes, so a PDF opened rather than saved is a
    // view of something about to stop existing -- no use for a contract, whose
    // whole point is having your own copy.
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
    return InkWell(
      key: ValueKey('shared-doc-${widget.document.id}'),
      onTap: _open,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 20,
              color: LizmoColors.slate,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.label ?? 'Document',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPdf ? 'Tap to download' : 'Tap to view',
                    style: LizmoType.rowSub.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_saving)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                _isPdf ? Icons.download_outlined : Icons.chevron_right,
                color: LizmoColors.slate,
              ),
          ],
        ),
      ),
    );
  }
}
