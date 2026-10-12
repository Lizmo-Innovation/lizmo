import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

import 'property_providers.dart';

/// A place's rules, money up front and what comes with it, as its landlord
/// set them. Null when it could not be read -- which is not "nothing said".
final placeDetailsProvider = FutureProvider.autoDispose
    .family<PlaceDetailsDto?, String>((ref, propertyId) async {
  try {
    return await ref.watch(propertiesApiProvider).getPlaceDetails(propertyId);
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Whether a landlord has said anything at all about a place.
bool saysAnything(PlaceDetailsDto details) =>
    details.whoCanRent != null ||
    details.curfew != null ||
    details.visitors != null ||
    details.cooking != null ||
    details.pets != null ||
    details.smoking != null ||
    (details.otherRules ?? '').isNotEmpty ||
    details.depositMonths != null ||
    details.advanceMonths != null ||
    details.amenities.isNotEmpty;

/// "Women only", or null for anyone or not said -- anyone is not news.
String? whoCanRentLabel(String? who) => switch (who) {
      'WOMEN' => 'Women only',
      'MEN' => 'Men only',
      _ => null,
    };

/// "10pm" out of "22:00"; "10:30pm" out of "22:30".
String curfewLabel(String curfew) {
  final parts = curfew.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? parts[1] : '00';
  final twelve = hour % 12 == 0 ? 12 : hour % 12;
  final half = hour < 12 ? 'am' : 'pm';
  return minute == '00' ? '$twelve$half' : '$twelve:$minute$half';
}

/// "2 months", "1 month", "None".
String monthsLabel(int months) => switch (months) {
      0 => 'None',
      1 => '1 month',
      _ => '$months months',
    };

String amenityLabel(String amenity) => switch (amenity) {
      'WIFI' => 'Wi-Fi',
      'AIRCON' => 'Aircon',
      'FURNISHED' => 'Furnished',
      'LAUNDRY' => 'Laundry area',
      'PARKING' => 'Parking',
      'CCTV' => 'CCTV',
      _ => amenity,
    };

IconData amenityIcon(String amenity) => switch (amenity) {
      'WIFI' => Icons.wifi,
      'AIRCON' => Icons.ac_unit,
      'FURNISHED' => Icons.chair_outlined,
      'LAUNDRY' => Icons.local_laundry_service_outlined,
      'PARKING' => Icons.local_parking_outlined,
      'CCTV' => Icons.videocam_outlined,
      _ => Icons.check,
    };

/// The house rules as short lines, each with what it is about. Only what was
/// said: a rule left blank is not a rule.
List<(IconData, String)> ruleLines(PlaceDetailsDto details) => [
      if (details.curfew case final curfew?)
        (Icons.nightlight_outlined, 'Curfew ${curfewLabel(curfew)}'),
      if (details.visitors?.toJson() case final visitors?)
        (
          Icons.people_outline,
          switch (visitors) {
            'ALLOWED' => 'Visitors welcome',
            'DAYTIME' => 'Visitors in the daytime only',
            _ => 'No visitors',
          }
        ),
      if (details.cooking case final cooking?)
        (Icons.soup_kitchen_outlined, cooking ? 'Cooking allowed' : 'No cooking'),
      if (details.pets case final pets?)
        (Icons.pets_outlined, pets ? 'Pets allowed' : 'No pets'),
      if (details.smoking case final smoking?)
        (Icons.smoke_free_outlined, smoking ? 'Smoking allowed outside' : 'No smoking'),
    ];
