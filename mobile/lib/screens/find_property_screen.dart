import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';

/// The code off the gate, typed.
///
/// The scanner is the way most people will arrive, but this is the one that
/// always works: a refused camera permission, a cracked lens, a code read out
/// over the phone, or a photograph of a sign somebody sent in a group chat.
/// Both routes end at the same lookup.
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
                'you. It looks like PHK7M4Q2.',
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
                    hintText: 'PHK7M4Q2',
                    hintStyle: LizmoType.dataMedium.copyWith(
                      fontSize: 26 * scale,
                      letterSpacing: 3,
                      color: LizmoColors.slate,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.pushReplacement(Routes.scanCode),
                  icon: const Icon(Icons.qr_code_scanner,
                      size: 18, color: LizmoColors.teal900),
                  label: Text(
                    'Scan it instead',
                    style: LizmoType.rowName.copyWith(
                      color: LizmoColors.teal900,
                      fontSize: 15 * scale,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
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
