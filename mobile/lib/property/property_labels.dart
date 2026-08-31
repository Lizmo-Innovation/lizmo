import 'package:lizmo_api/api.dart';

/// How a property's type and usage are written for a person.
///
/// Shared rather than duplicated per screen: the enum is the API's vocabulary,
/// and turning BOARDING_HOUSE into something a landlord would say is a decision
/// that should have one answer everywhere.

/// "Boarding House", from BOARDING_HOUSE.
///
/// Every word capitalised, not just the first: these read as the name of a kind
/// of place rather than as a sentence about one, and they sit beside proper
/// nouns like the property's own name.
String propertyTypeLabel(PropertyResponseTypeEnum? type) => _titleCase(type);

/// The same, for the enum the create form works in.
///
/// Two enums, one algorithm. The form used to carry a hand-written map of every
/// type, which is a second list to remember whenever the API grows one.
String propertyRequestTypeLabel(PropertyRequestTypeEnum? type) =>
    _titleCase(type);

String _titleCase(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return '';
  return raw
      .toLowerCase()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// "Boarding House", or "Commercial · Office".
///
/// Residential is the overwhelming majority, so naming it on every row of a
/// list would be noise. Commercial is the exception, and worth marking.
String propertyKindLabel(PropertyResponse property) {
  final type = propertyTypeLabel(property.type);
  return property.usage == PropertyResponseUsageEnum.COMMERCIAL
      ? 'Commercial · $type'
      : type;
}

/// "Residential · Boarding House" — both halves, always.
///
/// Unlike [propertyKindLabel], this names residential too. It is used where a
/// property is being introduced to somebody who has never seen it, rather than
/// labelled in a list of the landlord's own: there, saying what the place is
/// for sets expectations before anyone scans the code.
///
/// Usage leads, which is the broader fact — whether you could live here at all
/// comes before what shape the building is, and it matches the order
/// [propertyKindLabel] already uses in "Commercial · Office".
String propertyKindAndUsageLabel(PropertyResponse property) {
  final type = propertyTypeLabel(property.type);
  final usage = property.usage == PropertyResponseUsageEnum.COMMERCIAL
      ? 'Commercial'
      : 'Residential';
  return type.isEmpty ? usage : '$usage · $type';
}
