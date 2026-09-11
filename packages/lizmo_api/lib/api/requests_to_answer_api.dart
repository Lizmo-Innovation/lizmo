//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RequestsToAnswerApi {
  RequestsToAnswerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Say yes, and create the lease
  ///
  /// Terms are optional and default to the asking rent, today, and the day of the month the tenant moves in. Everyone else still waiting on the same bed or unit is superseded.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AcceptRequest] acceptRequest:
  Future<Response> acceptRentalRequestWithHttpInfo(String id, { AcceptRequest? acceptRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/rental-requests/{id}/accept'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = acceptRequest;

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

  /// Say yes, and create the lease
  ///
  /// Terms are optional and default to the asking rent, today, and the day of the month the tenant moves in. Everyone else still waiting on the same bed or unit is superseded.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AcceptRequest] acceptRequest:
  Future<LeaseResponse?> acceptRentalRequest(String id, { AcceptRequest? acceptRequest, Future<void>? abortTrigger, }) async {
    final response = await acceptRentalRequestWithHttpInfo(id, acceptRequest: acceptRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseResponse',) as LeaseResponse;
    
    }
    return null;
  }

  /// Say no
  ///
  /// Frees nothing, because a request never held anything.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> declineRentalRequestWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/rental-requests/{id}/decline'
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

  /// Say no
  ///
  /// Frees nothing, because a request never held anything.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<RentalRequestForLandlord?> declineRentalRequest(String id, { Future<void>? abortTrigger, }) async {
    final response = await declineRentalRequestWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentalRequestForLandlord',) as RentalRequestForLandlord;
    
    }
    return null;
  }

  /// One request in full
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getRentalRequestWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/rental-requests/{id}'
      .replaceAll('{id}', id);

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

  /// One request in full
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<RentalRequestForLandlord?> getRentalRequest(String id, { Future<void>? abortTrigger, }) async {
    final response = await getRentalRequestWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentalRequestForLandlord',) as RentalRequestForLandlord;
    
    }
    return null;
  }

  /// Who has asked about this property
  ///
  /// Pending only by default, oldest first: a queue is answered in the order people joined it.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [bool] pendingOnly:
  Future<Response> listRentalRequestsForPropertyWithHttpInfo(String propertyId, { bool? pendingOnly, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/properties/{propertyId}/rental-requests'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (pendingOnly != null) {
      queryParams.addAll(_queryParams('', 'pendingOnly', pendingOnly));
    }

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

  /// Who has asked about this property
  ///
  /// Pending only by default, oldest first: a queue is answered in the order people joined it.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [bool] pendingOnly:
  Future<List<RentalRequestForLandlord>?> listRentalRequestsForProperty(String propertyId, { bool? pendingOnly, Future<void>? abortTrigger, }) async {
    final response = await listRentalRequestsForPropertyWithHttpInfo(propertyId, pendingOnly: pendingOnly, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<RentalRequestForLandlord>') as List)
        .cast<RentalRequestForLandlord>()
        .toList(growable: false);

    }
    return null;
  }

  /// Everybody waiting on this landlord, across every property
  ///
  /// Pending only, oldest first across every property the caller owns. Empty for an account that owns none.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listRentalRequestsToAnswerWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/rental-requests';

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

  /// Everybody waiting on this landlord, across every property
  ///
  /// Pending only, oldest first across every property the caller owns. Empty for an account that owns none.
  Future<List<RentalRequestForLandlord>?> listRentalRequestsToAnswer({ Future<void>? abortTrigger, }) async {
    final response = await listRentalRequestsToAnswerWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<RentalRequestForLandlord>') as List)
        .cast<RentalRequestForLandlord>()
        .toList(growable: false);

    }
    return null;
  }
}
