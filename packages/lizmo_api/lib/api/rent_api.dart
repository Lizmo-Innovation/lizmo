//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RentApi {
  RentApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Rent on this tenancy
  ///
  /// Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listLeaseBillingWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/billing'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Rent on this tenancy
  ///
  /// Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<BillingPeriodResponse>?> listLeaseBilling(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listLeaseBillingWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BillingPeriodResponse>') as List)
        .cast<BillingPeriodResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// My rent
  ///
  /// The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listMyBillingWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/billing'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// My rent
  ///
  /// The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<BillingPeriodResponse>?> listMyBilling(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listMyBillingWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BillingPeriodResponse>') as List)
        .cast<BillingPeriodResponse>()
        .toList(growable: false);

    }
    return null;
  }
}
