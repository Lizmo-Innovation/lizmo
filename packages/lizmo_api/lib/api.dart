//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/admin_api.dart';
part 'api/asking_for_a_room_api.dart';
part 'api/auth_api.dart';
part 'api/finding_a_place_api.dart';
part 'api/leases_api.dart';
part 'api/lizmo_billing_api.dart';
part 'api/maintenance_api.dart';
part 'api/maintenance_to_handle_api.dart';
part 'api/my_account_api.dart';
part 'api/notifications_api.dart';
part 'api/payment_channels_api.dart';
part 'api/properties_api.dart';
part 'api/rent_api.dart';
part 'api/requests_to_answer_api.dart';
part 'api/signing_up_api.dart';
part 'api/tenant_documents_api.dart';
part 'api/tenant_profile_api.dart';
part 'api/units_api.dart';

part 'model/accept_invitation_request.dart';
part 'model/accept_request.dart';
part 'model/admin_property_bed.dart';
part 'model/admin_property_detail.dart';
part 'model/admin_property_summary.dart';
part 'model/admin_property_tenancy.dart';
part 'model/admin_property_unit.dart';
part 'model/api_error.dart';
part 'model/app_version.dart';
part 'model/arrears_row.dart';
part 'model/auth_response.dart';
part 'model/awaiting_row.dart';
part 'model/bed_request.dart';
part 'model/bed_response.dart';
part 'model/billing_period_response.dart';
part 'model/channel_properties.dart';
part 'model/collections_summary.dart';
part 'model/complete_password_reset_request.dart';
part 'model/complete_registration_request.dart';
part 'model/end_lease_request.dart';
part 'model/invitation_details_response.dart';
part 'model/invitation_sent_response.dart';
part 'model/invite_landlord_request.dart';
part 'model/landlord_detail.dart';
part 'model/landlord_summary.dart';
part 'model/lease_document_response.dart';
part 'model/lease_response.dart';
part 'model/login_request.dart';
part 'model/maintenance_note.dart';
part 'model/maintenance_report_response.dart';
part 'model/maintenance_request.dart';
part 'model/notification_response.dart';
part 'model/occupancy_summary.dart';
part 'model/payment_channel_order.dart';
part 'model/payment_channel_request.dart';
part 'model/payment_channel_response.dart';
part 'model/payment_channel_view.dart';
part 'model/payment_details.dart';
part 'model/payment_note.dart';
part 'model/payment_response.dart';
part 'model/pending_invitation.dart';
part 'model/platform_invoice_line.dart';
part 'model/platform_payment_for_admin.dart';
part 'model/platform_payment_rejection.dart';
part 'model/platform_payment_response.dart';
part 'model/platform_settings.dart';
part 'model/platform_statement_response.dart';
part 'model/property_by_code_response.dart';
part 'model/property_request.dart';
part 'model/property_response.dart';
part 'model/record_payment_request.dart';
part 'model/refresh_request.dart';
part 'model/rent_roll.dart';
part 'model/rent_roll_row.dart';
part 'model/rental_request_create.dart';
part 'model/rental_request_for_landlord.dart';
part 'model/rental_request_response.dart';
part 'model/report_problem_request.dart';
part 'model/start_password_reset_request.dart';
part 'model/start_password_reset_response.dart';
part 'model/start_registration_request.dart';
part 'model/start_registration_response.dart';
part 'model/support_contact.dart';
part 'model/tenant_document_response.dart';
part 'model/tenant_for_landlord.dart';
part 'model/tenant_profile_request.dart';
part 'model/tenant_profile_response.dart';
part 'model/unit_request.dart';
part 'model/unit_response.dart';
part 'model/unread_count.dart';
part 'model/utilities_request.dart';
part 'model/utilities_response.dart';
part 'model/utility_request.dart';
part 'model/utility_response.dart';
part 'model/vacancy_floor.dart';
part 'model/vacancy_row.dart';
part 'model/waiting_payment.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
