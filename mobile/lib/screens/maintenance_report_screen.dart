import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../maintenance/maintenance_providers.dart';
import '../widgets/full_screen_image.dart';
import '../widgets/maintenance_status_chip.dart';

/// One report, as the landlord deals with it.
///
/// Everything the tenant sent -- what, where, the photos -- and the two moves
/// that are the landlord's to make: start on it, and say it is fixed. Saying it
/// is fixed does not close it. The tenant does that, or says it is still broken.
class MaintenanceReportScreen extends ConsumerStatefulWidget {
  const MaintenanceReportScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<MaintenanceReportScreen> createState() =>
      _MaintenanceReportScreenState();
}

class _MaintenanceReportScreenState
    extends ConsumerState<MaintenanceReportScreen> {
  bool _working = false;

  Future<void> _move({required bool fixed}) async {
    final remarks = await _Remark.ask(context, fixed: fixed);
    // Null is backing out; an empty remark is a move with nothing said.
    if (remarks == null || !mounted) return;

    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(maintenanceToHandleApiProvider);
    final note = remarks.isEmpty ? null : MaintenanceNote(text: remarks);

    try {
      if (fixed) {
        await api.resolveMaintenance(widget.reportId, maintenanceNote: note);
      } else {
        await api.startMaintenance(widget.reportId, maintenanceNote: note);
      }
      messenger.showSnackBar(SnackBar(
        content: Text(fixed
            ? 'Marked fixed. Your tenant is asked to confirm.'
            : 'Your tenant is told you are on it.'),
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(maintenanceReportProvider(widget.reportId));
      ref.invalidate(maintenanceToHandleProvider);
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(maintenanceReportProvider(widget.reportId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Report',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.build_outlined,
          title: 'Not available',
          detail: ApiFailure.from(error).message,
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                          [
                            maintenanceWhere(report),
                            if (report.propertyName != null) report.propertyName!,
                          ].join(' · '),
                          style: LizmoType.rowSub,
                        ),
                      ),
                      MaintenanceStatusChip(report: report, forTenant: false),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.description ?? '',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reported by ${report.tenantName ?? 'your tenant'} on '
                    '${maintenanceDay(report.submittedAt)}',
                    style: LizmoType.rowSub.copyWith(fontSize: 11),
                  ),
                  if (report.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (index, url) in report.photoUrls.indexed)
                          InkWell(
                            key: ValueKey('maintenance-photo-$index'),
                            onTap: () => FullScreenImage.show(
                                context, url, 'Photo ${index + 1}'),
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 96,
                                  height: 96,
                                  color: LizmoColors.canvas,
                                  child: const Icon(Icons.image_outlined,
                                      color: LizmoColors.slate),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Said first when there is one: a reopened report looks exactly
            // like a new one otherwise, and it is not.
            if (report.reopened == true && report.reopenReason != null) ...[
              const SizedBox(height: 12),
              _Note(
                title: 'Your tenant says it is still broken',
                text: report.reopenReason!,
                colour: LizmoColors.redBg,
                ink: LizmoColors.red,
              ),
            ],
            if ((report.landlordRemarks ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _Note(
                title: 'What you last said',
                text: report.landlordRemarks!,
                colour: LizmoColors.white,
                ink: LizmoColors.ink,
              ),
            ],

            const SizedBox(height: 16),
            if (_working)
              const Center(child: CircularProgressIndicator())
            else
              ..._moves(report),
          ],
        ),
      ),
    );
  }

  List<Widget> _moves(MaintenanceReportResponse report) {
    Widget plain(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(text, style: LizmoType.rowSub),
        );

    return switch (report.status?.toJson()) {
      'SUBMITTED' => [
          OutlinedButton(
            key: const ValueKey('start-maintenance'),
            onPressed: () => _move(fixed: false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE3E8E6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Start on it',
                style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            key: const ValueKey('resolve-maintenance'),
            label: 'Mark fixed',
            onPressed: () => _move(fixed: true),
          ),
        ],
      'IN_PROGRESS' => [
          PrimaryActionButton(
            key: const ValueKey('resolve-maintenance'),
            label: 'Mark fixed',
            onPressed: () => _move(fixed: true),
          ),
        ],
      'RESOLVED' =>
        [plain('Waiting for your tenant to confirm it is fixed.')],
      'CLOSED' => [plain('Your tenant confirmed it is fixed.')],
      'WITHDRAWN' => [plain('Your tenant took this report back.')],
      _ => const [],
    };
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.title,
    required this.text,
    required this.colour,
    required this.ink,
  });

  final String title;
  final String text;
  final Color colour;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(14),
        border: colour == LizmoColors.white
            ? Border.all(color: const Color(0xFFE3E8E6))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LizmoType.rowSub.copyWith(fontSize: 11, color: ink)),
          const SizedBox(height: 4),
          Text(text, style: LizmoType.rowSub.copyWith(color: ink)),
        ],
      ),
    );
  }
}

/// Anything the landlord wants to say alongside the move. Optional: the tenant
/// is told either way.
class _Remark extends StatefulWidget {
  const _Remark({required this.fixed});

  final bool fixed;

  static Future<String?> ask(BuildContext context, {required bool fixed}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _Remark(fixed: fixed),
    );
  }

  @override
  State<_Remark> createState() => _RemarkState();
}

class _RemarkState extends State<_Remark> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fixed ? 'Mark it fixed?' : 'Start on it?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fixed
                ? 'Your tenant is asked to confirm, or to say it is still broken.'
                : 'Your tenant is told you are on it.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('maintenance-remark'),
            controller: _text,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: widget.fixed
                  ? 'New washer fitted.'
                  : 'The plumber comes on Saturday.',
              helperText: 'Optional. Your tenant sees this.',
              counterText: '',
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
          key: const ValueKey('remark-confirm'),
          onPressed: () => Navigator.of(context).pop(_text.text.trim()),
          child: Text(widget.fixed ? 'Mark fixed' : 'Start',
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
        ),
      ],
    );
  }
}
