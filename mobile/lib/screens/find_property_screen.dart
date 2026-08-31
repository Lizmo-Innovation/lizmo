import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';

/// Where a tenant starts: the code off the gate.
///
/// Typed rather than scanned, for now. Scanning is an input method for this
/// same lookup and comes later; a tenant who cannot type a code cannot use the
/// app at all, so this is the one that has to exist.
class FindPropertyScreen extends ConsumerStatefulWidget {
  const FindPropertyScreen({super.key});

  @override
  ConsumerState<FindPropertyScreen> createState() => _FindPropertyScreenState();
}

class _FindPropertyScreenState extends ConsumerState<FindPropertyScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// The server does the real tidying — this only keeps the field honest while
  /// somebody is typing, so the button enables when they have entered enough.
  String get _typed => _code.text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  bool get _looksComplete => _typed.length >= 8;

  void _look() {
    if (!_looksComplete) return;
    context.push(Routes.propertyByCode(_typed));
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.lizmoTextScale;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Find a place',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the code',
                style: LizmoType.sectionHeading.copyWith(fontSize: 20 * scale),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'It is on the sign by the gate, or the landlord can send it to '
                'you. It looks like PHLZ7K4M.',
                style: LizmoType.rowSub.copyWith(fontSize: 15 * scale),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: LizmoColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [LizmoColors.cardShadow],
                ),
                child: TextField(
                  controller: _code,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _look(),
                  onChanged: (_) => setState(() {}),
                  // Upper-cased as it is typed, so what is on screen matches
                  // what is chalked on the gate.
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    TextInputFormatter.withFunction(
                      (_, next) => next.copyWith(text: next.text.toUpperCase()),
                    ),
                  ],
                  style: LizmoType.dataMedium.copyWith(
                    fontSize: 26 * scale,
                    letterSpacing: 3,
                    color: LizmoColors.ink,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'PHLZ7K4M',
                    hintStyle: LizmoType.dataMedium.copyWith(
                      fontSize: 26 * scale,
                      letterSpacing: 3,
                      color: LizmoColors.slate,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'See what is free',
                // Disabled rather than hidden: the button is where the eye
                // goes, and a tenant should see what finishing the code gets
                // them.
                onPressed: _looksComplete ? _look : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
