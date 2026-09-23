import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Which properties a way to be paid is used for.
///
/// A landlord with one wallet ticks everything and forgets this exists; one
/// who keeps a property's rent in its own account, or manages a property whose
/// owner is paid directly, ticks what belongs. Nothing is ticked for a new
/// account, because rent landing in a wallet nobody chose is the worse
/// mistake.
class ChannelPropertiesSheet extends StatefulWidget {
  const ChannelPropertiesSheet({
    super.key,
    required this.channel,
    required this.properties,
    required this.chosen,
  });

  final String channel;
  final List<PropertyResponse> properties;
  final List<String> chosen;

  /// The chosen property ids, or null when it was closed without saving.
  static Future<List<String>?> show(
    BuildContext context, {
    required String channel,
    required List<PropertyResponse> properties,
    required List<String> chosen,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ChannelPropertiesSheet(
        channel: channel,
        properties: properties,
        chosen: chosen,
      ),
    );
  }

  @override
  State<ChannelPropertiesSheet> createState() => _ChannelPropertiesSheetState();
}

class _ChannelPropertiesSheetState extends State<ChannelPropertiesSheet> {
  late final Set<String> _picked = {...widget.chosen};

  bool get _all =>
      widget.properties.isNotEmpty &&
      widget.properties.every((property) => _picked.contains(property.id));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DEDC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Where do you use ${widget.channel}?',
                style: LizmoType.sectionHeading.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            Text(
              'Only tenants at the properties you tick are shown this account.',
              style: LizmoType.rowSub,
            ),
            const SizedBox(height: 14),
            if (widget.properties.isEmpty)
              const LizmoMessageState(
                tone: LizmoMessageTone.neutral,
                icon: Icons.home_work_outlined,
                title: 'No properties yet',
                detail: 'Add a property first, then say which accounts its '
                    'tenants pay into.',
              )
            else ...[
              // One tap for the common case: the same wallet everywhere.
              InkWell(
                key: const ValueKey('channel-properties-all'),
                onTap: () => setState(() {
                  if (_all) {
                    _picked.clear();
                  } else {
                    _picked.addAll([
                      for (final property in widget.properties) ?property.id,
                    ]);
                  }
                }),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _all ? 'Clear all' : 'All my properties',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final property in widget.properties)
                        if (property.id case final id?)
                          CheckboxListTile(
                            key: ValueKey('channel-property-$id'),
                            value: _picked.contains(id),
                            onChanged: (ticked) => setState(() {
                              if (ticked ?? false) {
                                _picked.add(id);
                              } else {
                                _picked.remove(id);
                              }
                            }),
                            activeColor: LizmoColors.teal900,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(property.name ?? 'Property',
                                style: LizmoType.rowName),
                            subtitle: property.address == null
                                ? null
                                : Text(property.address!, style: LizmoType.rowSub),
                          ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Saying none is allowed: a landlord rearranging their accounts
            // passes through it, and their tenants are told plainly.
            if (_picked.isEmpty && widget.properties.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'With none ticked, no tenant sees this account.',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                ),
              ),
            PrimaryActionButton(
              key: const ValueKey('save-channel-properties'),
              label: 'Save',
              onPressed: widget.properties.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_picked.toList()),
            ),
          ],
        ),
      ),
    );
  }
}
