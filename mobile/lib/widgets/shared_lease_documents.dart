import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../property/property_providers.dart';
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
  String? _error;

  bool get _isPdf => widget.document.contentType == 'application/pdf';

  Future<void> _open() async {
    setState(() => _error = null);

    final url = widget.document.url;
    if (url == null) {
      setState(() => _error = 'That document is not available just now.');
      return;
    }

    if (!_isPdf) {
      FullScreenImage.show(
          context, url, widget.document.label ?? 'Document');
      return;
    }

    // Nothing in the app renders a PDF, so it goes to whatever the phone
    // already uses for one. The link is presigned and lapses in minutes, which
    // is the point: it is a document, not an address.
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error =
          'Nothing on this phone could open it. Try again from a browser.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: ValueKey('shared-doc-${widget.document.id}'),
          onTap: _open,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 20,
                  color: LizmoColors.slate,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.document.label ?? 'Document',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: LizmoColors.slate),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
          ),
      ],
    );
  }
}
