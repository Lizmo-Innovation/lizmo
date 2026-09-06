import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// What is waiting on the tenant.
///
/// Everything the app wants to tell them, newest concern first: a profile that
/// is not finished, a request nobody has answered, rent that falls due,
/// announcements from their landlord and from Lizmo.
///
/// Defined that widely on purpose. As only a list of announcements it would be
/// empty on the day somebody signs up, which is the worst moment to show an
/// empty screen — and it would leave the one genuinely silent part of the app
/// still silent, which is a request sent and never answered.
///
/// This screen used to render three hardcoded billing periods and a header
/// reading "Sunrise Apartments · Bed 2, Unit 2B". Somebody who had just signed
/// up and rented nothing was told they owed 2,500 pesos, overdue, on a property
/// they had never heard of.
class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myTenantProfileProvider);
    final requests = ref.watch(myRentalRequestsProvider);
    final leases = ref.watch(myLeasesProvider);

    final lease = leases.valueOrNull?.firstOrNull;
    final waiting = (requests.valueOrNull ?? const <RentalRequestResponse>[])
        .where((request) => request.status == RentalRequestResponseStatusEnum.PENDING)
        .toList();
    final unfinished = profile.valueOrNull?.readyForALease == false;

    final nothingToSay = !unfinished && waiting.isEmpty && lease == null;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: 'Lizmo',
            title: lease == null ? 'Home' : _where(lease),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: lease == null
                ? const []
                : [
                    // What a settled tenant opens the app to check. Not "due
                    // now" — nothing records what has been paid yet, and a
                    // balance nobody maintains is worse than no balance.
                    LatticeHeaderStat(
                      value: '₱${(lease.rentAmount ?? 0).toStringAsFixed(0)}',
                      label: 'Monthly rent',
                    ),
                    LatticeHeaderStat(
                      value: 'The ${_ordinal(lease.dueDateDay ?? 1)}',
                      label: 'Rent day',
                    ),
                  ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myTenantProfileProvider);
                ref.invalidate(myRentalRequestsProvider);
                ref.invalidate(myLeasesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (unfinished) ...[
                    const _FinishYourProfile(),
                    const SizedBox(height: 12),
                  ],

                  for (final request in waiting) ...[
                    _Waiting(request: request),
                    const SizedBox(height: 12),
                  ],

                  if (lease != null) ...[
                    _Settled(lease: lease),
                    const SizedBox(height: 12),
                  ],

                  if (nothingToSay) const _AllQuiet(),

                  const SizedBox(height: 10),
                  _NoticesNotYet(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _where(LeaseResponse lease) => lease.bedLabel == null
      ? 'Unit ${lease.unitNumber}'
      : '${lease.bedLabel}, ${lease.unitNumber}';

  /// "the 1st", "the 22nd". A due date read as "the 1" looks like a bug.
  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

/// Shown until the profile carries what a lease needs.
///
/// A tenant has no reason to go looking for a profile screen, so the app asks
/// on the one screen they do open — and says why, rather than nagging.
class _FinishYourProfile extends StatelessWidget {
  const _FinishYourProfile();

  @override
  Widget build(BuildContext context) {
    return _Card(
      colour: LizmoColors.amberBg,
      textColour: LizmoColors.amberText,
      icon: Icons.badge_outlined,
      title: 'Finish your profile',
      detail: 'A landlord needs your ID and an emergency contact before they '
          'can accept you.',
      actionLabel: 'Open my profile',
      onAction: (context) => context.go(Routes.tenantProfile),
    );
  }
}

/// A request sent and not yet answered.
///
/// The one genuinely silent part of the app before this screen existed: a
/// tenant asked for a bed, closed the app, and had no way to find out what
/// happened. The endpoint has always been there.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.request});

  final RentalRequestResponse request;

  @override
  Widget build(BuildContext context) {
    final where = request.bedLabel == null
        ? 'Unit ${request.unitNumber}'
        : '${request.bedLabel}, ${request.unitNumber}';

    return _Card(
      colour: LizmoColors.white,
      textColour: LizmoColors.ink,
      icon: Icons.hourglass_empty,
      title: 'Waiting for a reply',
      detail: 'You asked for $where at ${request.propertyName ?? 'a property'}. '
          'Your landlord has not answered yet.',
    );
  }
}

class _Settled extends StatelessWidget {
  const _Settled({required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colour: LizmoColors.tealBg,
      textColour: LizmoColors.teal900,
      icon: Icons.check_circle_outline,
      title: lease.propertyName ?? 'Your place',
      detail: 'Your tenancy is active. Rent is ₱'
          '${(lease.rentAmount ?? 0).toStringAsFixed(0)} a month.',
      actionLabel: 'See my place',
      onAction: (context) => context.go(Routes.tenantPlace),
    );
  }
}

class _AllQuiet extends StatelessWidget {
  const _AllQuiet();

  @override
  Widget build(BuildContext context) {
    return const LizmoMessageState(
      icon: Icons.check_circle_outline,
      title: 'Nothing needs you',
      detail: 'Anything waiting on you shows up here — a reply from a '
          'landlord, rent falling due, a notice about your building.',
    );
  }
}

/// Says what this screen will carry and does not yet.
///
/// A tenant who never sees an announcement should know whether that means
/// there are none or that the feature does not exist.
class _NoticesNotYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Announcements from your landlord will appear here. They cannot send '
        'any yet.',
        style: LizmoType.rowSub,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.colour,
    required this.textColour,
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final Color colour;
  final Color textColour;
  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final void Function(BuildContext)? onAction;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColour),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: LizmoType.rowName.copyWith(color: textColour)),
                const SizedBox(height: 3),
                Text(detail,
                    style: LizmoType.rowSub.copyWith(color: textColour)),
                if (actionLabel != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => onAction?.call(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        actionLabel!,
                        style: LizmoType.rowName.copyWith(
                          fontSize: 13,
                          color: textColour,
                          decoration: TextDecoration.underline,
                          decorationColor: textColour,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
