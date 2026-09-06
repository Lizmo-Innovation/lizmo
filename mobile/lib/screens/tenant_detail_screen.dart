import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../tenant/id_labels.dart';

/// The person living in the room, as their landlord sees them.
///
/// The only place in the app that shows an emergency contact, and it exists
/// because that contact had nowhere to appear. A tenant could not ask about a
/// bed without naming somebody to ring — and once they had moved in, the one
/// person who might need to ring had no way to read it.
///
/// Everything here is scoped to a live tenancy. When it ends, the endpoint
/// behind this screen starts answering 404 and this becomes an ordinary
/// not-found — which is the intended behaviour, not a bug to smooth over.
class TenantDetailScreen extends ConsumerWidget {
  const TenantDetailScreen({super.key, required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(leaseTenantProvider(leaseId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        // Teal, like every other pushed screen. It was canvas, which left
        // LizmoType.screenTitle -- white, because it is drawn on the teal
        // header -- as white text on an almost-white bar.
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          tenant.valueOrNull?.name ?? 'Tenant',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: tenant.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.person_off_outlined,
          title: 'Not available',
          detail: ApiFailure.from(error).message,
        ),
        data: (person) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Section(
              title: 'Contact',
              rows: [
                _Fact('Name', person.name),
                _Fact('Phone', person.phone),
                _Fact('Email', person.email),
                _Fact('Age', person.age?.toString()),
                _Fact('Occupation', person.occupation),
                _Fact('Permanent address', person.permanentAddress),
              ],
            ),
            const SizedBox(height: 12),

            // The reason this screen exists.
            _Section(
              title: 'In an emergency',
              subtitle: 'Who to ring. Given by the tenant, and shown only '
                  'while they are renting from you.',
              rows: [
                _Fact('Name', person.emergencyContactName),
                _Fact('Relationship', person.emergencyContactRelationship),
                _Fact('Phone', person.emergencyContactPhone),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              title: 'Identification',
              rows: [
                _Fact('Type', idTypeLabel(person.idType?.toJson())),
                _Fact('Number', person.idNumber),
              ],
            ),
            const SizedBox(height: 12),

            _Documents(leaseId: leaseId),
          ],
        ),
      ),
    );
  }
}

/// One labelled fact, which may not have been given.
///
/// A missing field reads as a dash, never as an empty string and never as a
/// zero: "no occupation recorded" and "unemployed" are different statements,
/// and only the tenant can make the second one.
class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String? value;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.subtitle});

  final String title;
  final String? subtitle;
  final List<_Fact> rows;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: LizmoType.sectionHeading),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: LizmoType.rowSub),
          ],
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Text(row.label, style: LizmoType.rowSub),
                  ),
                  Expanded(
                    child: Text(
                      (row.value == null || row.value!.isEmpty)
                          ? '—'
                          : row.value!,
                      style: LizmoType.rowName.copyWith(
                        color: (row.value == null || row.value!.isEmpty)
                            ? LizmoColors.slate
                            : LizmoColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The photographs, which the backend has served since leases existed and
/// which nothing in the app ever asked for.
class _Documents extends ConsumerWidget {
  const _Documents({required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(leaseTenantDocumentsProvider(leaseId));
    final rows = documents.valueOrNull ?? const <TenantDocumentResponse>[];

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
          Text('Photographs', style: LizmoType.sectionHeading),
          const SizedBox(height: 10),
          if (documents.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ))
          else if (rows.isEmpty)
            Text('None on file.', style: LizmoType.rowSub)
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => _Photo(document: rows[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.document});

  final TenantDocumentResponse document;

  @override
  Widget build(BuildContext context) {
    final url = document.url;
    final label = docTypeLabel(document.docType?.toJson());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          // Keyed by kind: a tenant has at most one of each.
          key: ValueKey('photo-${document.docType?.toJson()}'),
          // A 120px square is enough to see that an ID is there and not
          // enough to read the number on it, which is the whole reason a
          // landlord opens this.
          onTap: url == null ? null : () => _FullPhoto.show(context, url, label),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 120,
            height: 120,
            child: url == null
                ? const ColoredBox(color: LizmoColors.canvas)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    // The URL is presigned and short-lived. An expired one is
                    // a broken image, not an error worth a dialog.
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: LizmoColors.canvas,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: LizmoColors.slate),
                    ),
                  ),
          ),
        ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: LizmoType.rowSub.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.url, required this.label});

  final String url;
  final String label;

  static Future<void> show(BuildContext context, String url, String label) {
    return showDialog<void>(
      context: context,
      // Near-black rather than the usual scrim: a photograph is easier to
      // read against something that is not competing with it.
      barrierColor: Colors.black87,
      builder: (_) => _FullPhoto(url: url, label: label),
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
