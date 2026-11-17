import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// How a kind of to-do looks: the tint behind its icon and avatars, and the
/// ink on them.
class TodoTone {
  const TodoTone(this.tint, this.ink);

  final Color tint;
  final Color ink;

  static const asking = TodoTone(LizmoColors.tealTint, LizmoColors.teal900);
  static const confirm = TodoTone(LizmoColors.amberBg, LizmoColors.amberText);
  static const repairs = TodoTone(LizmoColors.amberBg, LizmoColors.amberText);
  static const behind = TodoTone(LizmoColors.redBg, LizmoColors.redText);
  static const ending = TodoTone(Color(0xFFEFF2F1), LizmoColors.slateText);
  static const bill = TodoTone(LizmoColors.tealTint, LizmoColors.teal900);
}

/// The way to the rest of a kind when the card shows only some of it.
class TodoSeeAll {
  const TodoSeeAll({this.key, this.onTap, this.note, this.always = false});

  final Key? key;

  /// Where the rest is. Null opens the rest in place.
  final VoidCallback? onTap;

  /// Said after the count, e.g. "2 in progress".
  final String? note;

  /// Shown even when every row is already on the card, because [note] says
  /// something the rows do not.
  final bool always;
}

/// One kind of thing waiting on a landlord: an icon, a title, how many, and a
/// row for each.
///
/// With [compact] -- other kinds are on the screen too -- it shows its first
/// two rows and a way to the rest, so six kinds still fit a phone without
/// any one of them pushing the others off it. On its own it shows everything.
///
/// Carries its own space below, so a card with nothing to say leaves no gap.
class TodoCard extends StatefulWidget {
  const TodoCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.count,
    required this.rows,
    this.compact = false,
    this.seeAll,
    this.body,
  });

  final IconData icon;
  final TodoTone tone;
  final String title;
  final int count;
  final List<Widget> rows;
  final bool compact;
  final TodoSeeAll? seeAll;

  /// Said under the title instead of rows, for a card with nothing to list.
  final Widget? body;

  /// Rows shown when other kinds share the screen.
  static const shown = 2;

  /// Rows shown on a card alone. Every row, up to a point: twenty
  /// conversations would turn Today into an inbox.
  static const most = 5;

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final limit = _open
        ? rows.length
        : widget.compact
        ? TodoCard.shown
        : TodoCard.most;
    final cut = rows.length > limit;
    final seeAll = widget.seeAll;
    final showSeeAll = cut || (seeAll?.always ?? false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.tone.tint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.tone.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          style: LizmoType.rowName.copyWith(
                            color: LizmoColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.count}',
                      style: LizmoType.dataMedium.copyWith(
                        fontSize: 14,
                        color: widget.tone.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.body case final body?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: body,
                ),
              for (final row in cut ? rows.take(limit) : rows) row,
              if (showSeeAll)
                _SeeAllRow(
                  key: seeAll?.key,
                  label: [
                    if (cut) 'See all ${rows.length}' else 'See all',
                    ?seeAll?.note,
                  ].join(' · '),
                  onTap: seeAll?.onTap ?? () => setState(() => _open = true),
                )
              else if (rows.isNotEmpty)
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllRow extends StatelessWidget {
  const _SeeAllRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEFF2F1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: LizmoType.rowName.copyWith(
                  fontSize: 13,
                  color: LizmoColors.teal900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: LizmoColors.teal900,
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing to do: who, what, and the one control that does it.
///
/// The whole row opens where it gets dealt with; [trailing] is for the
/// action that does not need opening anything -- Confirm, Remind.
class TodoRow extends StatelessWidget {
  const TodoRow({
    super.key,
    required this.leading,
    required this.title,
    required this.sub,
    this.unread = false,
    this.trailing,
    this.below,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final Widget sub;

  /// A coral dot after the name: the last word was theirs.
  final bool unread;
  final Widget? trailing;

  /// A second line of controls under the row, for a card shown on its own.
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LizmoType.rowName.copyWith(
                                  color: LizmoColors.ink,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                key: const ValueKey('unread-dot'),
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: LizmoColors.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        sub,
                      ],
                    ),
                  ),
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: 8),
                    trailing,
                  ],
                ],
              ),
            ),
            if (below case final below?)
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 8),
                child: below,
              ),
          ],
        ),
      ),
    );
  }
}

/// A person, by their initials, in the kind's tint.
class TodoAvatar extends StatelessWidget {
  const TodoAvatar({super.key, this.name, this.icon, required this.tone});

  final String? name;

  /// For a row that is not about a person -- Lizmo's own bill.
  final IconData? icon;
  final TodoTone tone;

  /// "Ana Reyes" → "AR"; one name → its first letter.
  static String initials(String? name) {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tone.tint, shape: BoxShape.circle),
        child: icon != null
            ? Icon(icon, size: 18, color: tone.ink)
            : Text(
                initials(name),
                style: LizmoType.rowName.copyWith(
                  fontSize: 13,
                  color: tone.ink,
                ),
              ),
      ),
    );
  }
}

/// "3 h", "1 d": how long ago, short enough to sit at the end of a row.
String ageShort(DateTime at, {DateTime? now}) {
  final gap = (now ?? DateTime.now()).difference(at.toLocal());
  if (gap.inMinutes < 1) return 'now';
  if (gap.inHours < 1) return '${gap.inMinutes} m';
  if (gap.inDays < 1) return '${gap.inHours} h';
  return '${gap.inDays} d';
}

/// A row's figure, in mono.
TextStyle todoMono(Color ink) =>
    LizmoType.dataMedium.copyWith(fontSize: 12, color: ink);

/// A to-do card in the shape it will have, while the first answer comes in.
class TodoSkeleton extends StatelessWidget {
  const TodoSkeleton({super.key});

  static const _grey = Color(0xFFE9EEEC);

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _grey,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                bar(120, 12),
              ],
            ),
            for (var i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(140, 10),
                          const SizedBox(height: 8),
                          bar(200, 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
