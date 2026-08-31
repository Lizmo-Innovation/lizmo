//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AskingForARoomApi {
  AskingForARoomApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// What I have asked for
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyRentalRequestsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/rental-requests';

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

  /// What I have asked for
  Future<List<RentalRequestResponse>?> listMyRentalRequests({ Future<void>? abortTrigger, }) async {
    final response = await listMyRentalRequestsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<RentalRequestResponse>') as List)
        .cast<RentalRequestResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Ask for a bed or a unit
  ///
  /// Needs a complete tenant profile. Omit bedId to ask for the whole unit.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RentalRequestCreate] rentalRequestCreate (required):
  Future<Response> sendRentalRequestWithHttpInfo(RentalRequestCreate rentalRequestCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/rental-requests';

    // ignore: prefer_final_locals
    Object? postBody = rentalRequestCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Ask for a bed or a unit
  ///
  /// Needs a complete tenant profile. Omit bedId to ask for the whole unit.
  ///
  /// Parameters:
  ///
  /// * [RentalRequestCreate] rentalRequestCreate (required):
  Future<RentalRequestResponse?> sendRentalRequest(RentalRequestCreate rentalRequestCreate, { Future<void>? abortTrigger, }) async {
    final response = await sendRentalRequestWithHttpInfo(rentalRequestCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentalRequestResponse',) as RentalRequestResponse;
    
    }
    return null;
  }

  /// Change my mind
  ///
  /// Only while it is still waiting on the landlord.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> withdrawRentalRequestWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/rental-requests/{id}/withdraw'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Change my mind
  ///
  /// Only while it is still waiting on the landlord.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<RentalRequestResponse?> withdrawRentalRequest(String id, { Future<void>? abortTrigger, }) async {
    final response = await withdrawRentalRequestWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentalRequestResponse',) as RentalRequestResponse;
    
    }
    return null;
  }
}
