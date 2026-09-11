import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/declare_payment_sheet.dart';
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
    final months = lease == null
        ? null
        : ref.watch(myBillingProvider(lease.id!)).valueOrNull;
    final owed = months?.fold<num>(
        0, (sum, month) => sum + (month.outstanding ?? 0));
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
                    // What a settled tenant opens the app to check. It was the
                    // monthly rent, from before anything recorded what had
                    // been paid; payments are recorded now, so it is what is
                    // actually owed. A dash until that is known.
                    LatticeHeaderStat(
                      value: owed == null ? '—' : '₱${owed.toStringAsFixed(0)}',
                      label: 'Owed',
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
                if (lease != null) {
                  ref.invalidate(myBillingProvider(lease.id!));
                  ref.invalidate(myPaymentsProvider(lease.id!));
                }
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
                    _RentDue(lease: lease),
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
      onAction: (context) => context.push(Routes.tenantProfile),
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

/// What is owed right now, and the way to say it has been paid.
///
/// Home said nothing about rent: the monthly figure in the header, and a card
/// saying the tenancy was active. Somebody who opens the app on the 4th wants
/// to know whether rent is due tomorrow, and to say they paid it without going
/// looking for where.
///
/// The oldest month still owed, since that is the one a landlord is waiting
/// on. Nothing at all while the months are loading or failed to load -- the
/// Rent tab says why -- because "paid up" over a list that never arrived
/// would be a false all-clear.
class _RentDue extends ConsumerWidget {
  const _RentDue({required this.lease});

  final LeaseResponse lease;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _day(DateTime? date) =>
      date == null ? '' : '${date.day} ${_months[date.month - 1]}';

  Future<void> _declare(
    BuildContext context,
    WidgetRef ref,
    BillingPeriodResponse period,
  ) async {
    final said = await DeclarePaymentSheet.show(
      context,
      periodLabel: period.label ?? 'this month',
      outstanding: period.outstanding ?? 0,
    );
    if (said == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await sendDeclaration(ref, leaseId: lease.id!, period: period, said: said);
      messenger.showSnackBar(const SnackBar(
        content: Text('Told your landlord. They will confirm it.'),
      ));
    } on ApiFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(myBillingProvider(lease.id!)).valueOrNull;
    // A tenancy that has not started has no months yet; the card below it
    // already says the tenancy exists.
    if (months == null || months.isEmpty) return const SizedBox.shrink();

    final payments =
        ref.watch(myPaymentsProvider(lease.id!)).valueOrNull ?? const [];
    final owing = months.where((month) => (month.outstanding ?? 0) > 0).toList();

    final Widget card;
    if (owing.isEmpty) {
      card = _Card(
        colour: LizmoColors.white,
        textColour: LizmoColors.ink,
        icon: Icons.check_circle_outline,
        title: 'You are paid up',
        detail: 'Your next rent is due on the '
            '${TenantHomeScreen._ordinal(lease.dueDateDay ?? 1)}.',
      );
    } else {
      // The server sends oldest first, and the oldest is the one owed longest.
      final oldest = owing.first;
      final left = oldest.outstanding ?? 0;
      final said = payments.where((payment) =>
          payment.billingPeriodId == oldest.id &&
          payment.status == PaymentResponseStatusEnum.PENDING_VERIFICATION);

      if (said.isNotEmpty) {
        // Not asked again. Somebody who has already said they paid and is
        // offered "I have paid" a second time would reasonably think the
        // first one was lost.
        card = _Card(
          colour: LizmoColors.amberBg,
          textColour: LizmoColors.amberText,
          icon: Icons.hourglass_empty,
          title: 'Waiting for your landlord',
          detail: 'You said you paid ₱${(said.first.amountPaid ?? 0).toStringAsFixed(0)} '
              'for ${oldest.label}. It counts once they confirm it.',
        );
      } else if (oldest.overdue == true) {
        final late = owing.where((month) => month.overdue == true).length;
        final total =
            owing.fold<num>(0, (sum, month) => sum + (month.outstanding ?? 0));
        card = _Card(
          colour: LizmoColors.redBg,
          textColour: LizmoColors.red,
          icon: Icons.error_outline,
          title: '₱${total.toStringAsFixed(0)} is late',
          detail: late == 1
              ? '${oldest.label} was due on ${_day(oldest.dueDate)}.'
              : '$late months are overdue, the oldest since '
                  '${_day(oldest.dueDate)}.',
          actionLabel: 'I have paid',
          onAction: (context) => _declare(context, ref, oldest),
        );
      } else {
        card = _Card(
          colour: LizmoColors.white,
          textColour: LizmoColors.ink,
          icon: Icons.receipt_long_outlined,
          title: '₱${left.toStringAsFixed(0)} due on ${_day(oldest.dueDate)}',
          detail: 'Rent for ${oldest.label}.',
          actionLabel: 'I have paid',
          onAction: (context) => _declare(context, ref, oldest),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KeyedSubtree(key: const ValueKey('rent-due'), child: card),
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
