import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/id_labels.dart';
import '../widgets/full_screen_image.dart';
import '../widgets/end_tenancy_sheet.dart';
import '../widgets/lease_attachments.dart';

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

            // Only when there is something to say. A tenancy where neither
            // was recorded shows no card, rather than a panel of dashes
            // implying somebody forgot to fill it in.
            if (_hasUpfrontMoney(ref, leaseId)) ...[
              _UpfrontMoney(leaseId: leaseId),
              const SizedBox(height: 12),
            ],

            _Section(
              title: 'Identification',
              rows: [
                _Fact('Type', idTypeLabel(person.idType?.toJson())),
                _Fact('Number', person.idNumber),
              ],
            ),
            const SizedBox(height: 12),

            _Documents(leaseId: leaseId),
            const SizedBox(height: 12),

            // Last, because it is the landlord's own filing rather than
            // anything about the person.
            LeaseAttachments(leaseId: leaseId),
            const SizedBox(height: 12),

            // Last, and deliberately plain rather than a red button at the
            // top. Ending a tenancy is a normal part of letting rooms, not a
            // destructive act to be warned about -- but it is also not the
            // thing somebody opened this screen to do.
            _EndTenancy(leaseId: leaseId),
          ],
        ),
      ),
    );
  }
}

/// Ending the tenancy, and freeing the bed.
///
/// Nothing in the app could do this before: the endpoint existed and was
/// tested, and no screen called it. A landlord could let a bed and then never
/// get it back, which made the second tenancy of any bed impossible.
class _EndTenancy extends ConsumerStatefulWidget {
  const _EndTenancy({required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<_EndTenancy> createState() => _EndTenancyState();
}

class _EndTenancyState extends ConsumerState<_EndTenancy> {
  bool _working = false;
  String? _error;

  Future<void> _end(LeaseResponse lease) async {
    final terms = await EndTenancySheet.show(
      context,
      tenantName: lease.tenantName ?? 'this tenant',
      slot: lease.bedLabel == null
          ? 'Unit ${lease.unitNumber}'
          : '${lease.bedLabel}, ${lease.unitNumber}',
      depositAmount: lease.depositAmount,
    );
    if (terms == null) return;

    setState(() {
      _working = true;
      _error = null;
    });

    try {
      await ref.read(leasesApiProvider).endLease(
            widget.leaseId,
            endLeaseRequest: terms,
          );

      // Everything the ending touched. The bed is the one that matters and
      // the one most easily missed: it lives under a different provider from
      // the tenant list, and a stale bed still reading OCCUPIED is a room the
      // landlord cannot re-let without restarting the app.
      ref.invalidate(myTenantsProvider);
      ref.invalidate(propertiesProvider);
      if (lease.propertyId != null) {
        ref.invalidate(propertyLeasesProvider(lease.propertyId!));
        ref.invalidate(unitsProvider(lease.propertyId!));
      }
      if (lease.unitId != null) {
        ref.invalidate(bedsProvider(lease.unitId!));
      }

      // The tenant screen is addressed by a lease that is no longer live, so
      // staying here would show a not-found. Back to the list, which is now
      // one shorter.
      if (mounted) context.go(Routes.tenants);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lease = ref.watch(landlordLeaseProvider(widget.leaseId));
    if (lease == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_working)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else
          OutlinedButton.icon(
            key: const ValueKey('end-tenancy'),
            onPressed: () => _end(lease),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('End this tenancy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LizmoColors.teal900,
              side: const BorderSide(color: Color(0xFFE3E8E6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
        ],
      ],
    );
  }
}

bool _hasUpfrontMoney(WidgetRef ref, String leaseId) {
  final lease = ref.watch(landlordLeaseProvider(leaseId));
  return lease != null &&
      (lease.depositAmount != null || lease.advanceAmount != null);
}

/// What this tenant handed over before moving in.
///
/// Two figures, not one. A deposit is money the landlord is holding and a
/// advance is money they have earned, and the difference only matters at the
/// end of the tenancy -- when it matters a great deal.
class _UpfrontMoney extends ConsumerWidget {
  const _UpfrontMoney({required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(landlordLeaseProvider(leaseId));
    if (lease == null) return const SizedBox.shrink();

    return _Section(
      title: 'Before they moved in',
      rows: [
        _Fact(
          'Deposit',
          lease.depositAmount == null
              ? null
              : '₱${lease.depositAmount!.toStringAsFixed(0)}',
        ),
        _Fact(
          'Advance rent',
          lease.advanceAmount == null
              ? null
              : '₱${lease.advanceAmount!.toStringAsFixed(0)}',
        ),
      ],
      subtitle: 'The deposit goes back when they move out. The advance pays '
          'for their first month.',
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
          onTap: url == null ? null : () => FullScreenImage.show(context, url, label),
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
