import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../maintenance/maintenance_providers.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/full_screen_image.dart';
import '../widgets/maintenance_status_chip.dart';
import '../widgets/notification_bell.dart';
import '../widgets/report_problem_sheet.dart';
import '../widgets/role_switcher.dart';

/// Reporting something broken, and what happened to what you reported.
///
/// This tab said "Not built yet" and told tenants to tell their landlord the
/// way they normally would. It is built as a pair with the landlord's side,
/// because a report the landlord never sees is a suggestion box, and a tenant
/// only has to be ignored once to stop using it.
///
/// The last word on "fixed" is the tenant's. A landlord marks something fixed;
/// the tenant says it is, or says it is still broken and why.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool _sending = false;

  Future<void> _report() async {
    final problem = await ReportProblemSheet.show(context);
    if (problem == null || !mounted) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(maintenanceApiProvider);

    try {
      final report = await api.reportProblem(
        ReportProblemRequest(description: problem.description),
      );

      // One at a time, after the report exists. A photo that fails to upload
      // must not lose the report it belongs to.
      var failed = 0;
      for (final photo in problem.photos) {
        try {
          await api.addMaintenancePhoto(
            report!.id!,
            http.MultipartFile.fromBytes('photo', photo.bytes,
                filename: photo.name),
          );
        } catch (_) {
          failed++;
        }
      }

      messenger.showSnackBar(SnackBar(
        content: Text(failed == 0
            ? 'Sent to your landlord.'
            : 'Sent to your landlord, but $failed '
                '${failed == 1 ? 'photo' : 'photos'} did not upload.'),
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(myMaintenanceProvider);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lease = ref.watch(myLeasesProvider).valueOrNull?.firstOrNull;
    final reports = ref.watch(myMaintenanceProvider);
    final rows = reports.valueOrNull ?? const <MaintenanceReportResponse>[];

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          const LatticeHeader(
            eyebrow: 'Lizmo',
            title: 'Maintenance',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
          ),
          Expanded(
            child: lease == null && rows.isEmpty
                // A report belongs to a tenancy: there is nothing to report
                // about a room you do not live in.
                ? const LizmoMessageState(
                    icon: Icons.build_outlined,
                    title: 'Nothing to report yet',
                    detail: 'Once you are renting through Lizmo, you can report '
                        'anything broken here and follow what happens to it.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(myMaintenanceProvider),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        if (lease != null) ...[
                          if (_sending)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            PrimaryActionButton(
                              key: const ValueKey('report-problem'),
                              label: 'Report a problem',
                              onPressed: _report,
                            ),
                          const SizedBox(height: 16),
                        ],
                        ...switch (reports) {
                          AsyncError(:final error) => [
                              LizmoMessageState(
                                tone: LizmoMessageTone.problem,
                                icon: Icons.error_outline,
                                title: 'Could not load your reports',
                                detail: ApiFailure.from(error).message,
                              ),
                            ],
                          AsyncData(:final value) when value.isEmpty => [
                              const LizmoMessageState(
                                tone: LizmoMessageTone.neutral,
                                icon: Icons.build_outlined,
                                title: 'Nothing reported',
                                detail: 'If something breaks, report it here. '
                                    'Your landlord is told, and you can see '
                                    'what happens to it.',
                              ),
                            ],
                          AsyncData(:final value) => [
                              for (final report in value)
                                _ReportCard(report: report),
                            ],
                          _ => [
                              const Center(child: CircularProgressIndicator()),
                            ],
                        },
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One report, as the tenant who sent it follows it.
class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final MaintenanceReportResponse report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _working = false;

  MaintenanceReportResponse get report => widget.report;

  Future<void> _send(Future<void> Function() call, String done) async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(myMaintenanceProvider);
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _withdraw() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take this report back?'),
        content: Text(
          'Your landlord will see you took it back.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const ValueKey('withdraw-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Take it back',
                style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _send(
      () => ref.read(maintenanceApiProvider).withdrawMaintenanceReport(report.id!),
      'Taken back.',
    );
  }

  Future<void> _reopen() async {
    final reason = await _StillBroken.ask(context);
    if (reason == null || !mounted) return;
    await _send(
      () => ref.read(maintenanceApiProvider).reopenMaintenanceReport(
            report.id!,
            MaintenanceNote(text: reason),
          ),
      'Told your landlord it is still broken.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = report.status?.toJson();
    final remarks = report.landlordRemarks;

    return Container(
      key: ValueKey('report-${report.id}'),
      margin: const EdgeInsets.only(bottom: 10),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Reported ${maintenanceDay(report.submittedAt)}',
                  style: LizmoType.rowSub.copyWith(fontSize: 11),
                ),
              ),
              MaintenanceStatusChip(report: report, forTenant: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.description ?? '',
            style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
          ),
          if (report.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Photos(urls: report.photoUrls),
          ],
          if (report.reopened == true && report.reopenReason != null) ...[
            const SizedBox(height: 10),
            _Said(who: 'You said it was still broken', text: report.reopenReason!),
          ],
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Said(who: 'Your landlord', text: remarks),
          ],

          if (_working)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (status == 'RESOLVED') ...[
            // The question the landlord has asked. Only the person living
            // with it can say whether it is fixed.
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
              decoration: BoxDecoration(
                color: LizmoColors.amberBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your landlord says this is fixed. Is it?',
                    style:
                        LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: ValueKey('reopen-${report.id}'),
                        onPressed: _reopen,
                        child: Text('Still broken',
                            style: LizmoType.rowSub
                                .copyWith(color: LizmoColors.red)),
                      ),
                      TextButton(
                        key: ValueKey('fixed-${report.id}'),
                        onPressed: () => _send(
                          () => ref
                              .read(maintenanceApiProvider)
                              .confirmMaintenanceFixed(report.id!),
                          'Glad it is sorted.',
                        ),
                        child: Text('Yes, it is fixed',
                            style: LizmoType.rowName
                                .copyWith(color: LizmoColors.teal900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (status == 'SUBMITTED')
            // Only before anybody has started: somebody may already have
            // bought the part.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: ValueKey('withdraw-${report.id}'),
                onPressed: _withdraw,
                child: Text('Take it back',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.slate)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Something one side said, attributed.
class _Said extends StatelessWidget {
  const _Said({required this.who, required this.text});

  final String who;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LizmoColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(who, style: LizmoType.rowSub.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(text, style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
        ],
      ),
    );
  }
}

/// Thumbnails that open full screen.
class _Photos extends StatelessWidget {
  const _Photos({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final url in urls)
          InkWell(
            onTap: () => FullScreenImage.show(context, url, 'Photo'),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                // A link that has lapsed shows a gap, not a crash.
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: LizmoColors.canvas,
                  child: const Icon(Icons.image_outlined,
                      color: LizmoColors.slate),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Why it is still broken. Required: it is the whole of what the landlord
/// needs to hear.
class _StillBroken extends StatefulWidget {
  const _StillBroken();

  static Future<String?> ask(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _StillBroken(),
    );
  }

  @override
  State<_StillBroken> createState() => _StillBrokenState();
}

class _StillBrokenState extends State<_StillBroken> {
  final _why = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Still broken?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your landlord sees this, so say what is still wrong.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('reopen-reason'),
            controller: _why,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'It started dripping again the next day.',
              counterText: '',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('reopen-confirm'),
          onPressed: () {
            final why = _why.text.trim();
            if (why.isEmpty) {
              setState(() => _error = 'Say what is still wrong');
              return;
            }
            Navigator.of(context).pop(why);
          },
          child: Text('Send',
              style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
        ),
      ],
    );
  }
}
