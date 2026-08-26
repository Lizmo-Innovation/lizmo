//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UnitsApi {
  UnitsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a bed
  ///
  /// Bedspace units only, and never beyond the unit's capacity.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [BedRequest] bedRequest (required):
  Future<Response> createBedWithHttpInfo(String id, BedRequest bedRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}/beds'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = bedRequest;

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

  /// Add a bed
  ///
  /// Bedspace units only, and never beyond the unit's capacity.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [BedRequest] bedRequest (required):
  Future<BedResponse?> createBed(String id, BedRequest bedRequest, { Future<void>? abortTrigger, }) async {
    final response = await createBedWithHttpInfo(id, bedRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BedResponse',) as BedResponse;
    
    }
    return null;
  }

  /// Remove a bed
  ///
  /// Refused while the bed is occupied.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteBedWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/beds/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Remove a bed
  ///
  /// Refused while the bed is occupied.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteBed(String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteBedWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Delete a unit
  ///
  /// Refused while the unit still has beds.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteUnitWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Delete a unit
  ///
  /// Refused while the unit still has beds.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteUnit(String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteUnitWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// View one unit
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getUnitWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}'
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

  /// View one unit
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<UnitResponse?> getUnit(String id, { Future<void>? abortTrigger, }) async {
    final response = await getUnitWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UnitResponse',) as UnitResponse;
    
    }
    return null;
  }

  /// List a unit's beds
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> listBedsWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}/beds'
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

  /// List a unit's beds
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<List<BedResponse>?> listBeds(String id, { Future<void>? abortTrigger, }) async {
    final response = await listBedsWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BedResponse>') as List)
        .cast<BedResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Take a bed out of service, or put it back
  ///
  /// Refused while the bed is occupied.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceRequest] maintenanceRequest (required):
  Future<Response> setBedMaintenanceWithHttpInfo(String id, MaintenanceRequest maintenanceRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/beds/{id}/maintenance'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = maintenanceRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Take a bed out of service, or put it back
  ///
  /// Refused while the bed is occupied.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceRequest] maintenanceRequest (required):
  Future<BedResponse?> setBedMaintenance(String id, MaintenanceRequest maintenanceRequest, { Future<void>? abortTrigger, }) async {
    final response = await setBedMaintenanceWithHttpInfo(id, maintenanceRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BedResponse',) as BedResponse;
    
    }
    return null;
  }

  /// Take a unit out of service, or put it back
  ///
  /// Refused while the unit is occupied.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceRequest] maintenanceRequest (required):
  Future<Response> setUnitMaintenanceWithHttpInfo(String id, MaintenanceRequest maintenanceRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}/maintenance'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = maintenanceRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Take a unit out of service, or put it back
  ///
  /// Refused while the unit is occupied.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceRequest] maintenanceRequest (required):
  Future<UnitResponse?> setUnitMaintenance(String id, MaintenanceRequest maintenanceRequest, { Future<void>? abortTrigger, }) async {
    final response = await setUnitMaintenanceWithHttpInfo(id, maintenanceRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UnitResponse',) as UnitResponse;
    
    }
    return null;
  }

  /// Rename a bed
  ///
  /// Labels must be unique within the unit, case-insensitively.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [BedRequest] bedRequest (required):
  Future<Response> updateBedWithHttpInfo(String id, BedRequest bedRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/beds/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = bedRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Rename a bed
  ///
  /// Labels must be unique within the unit, case-insensitively.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [BedRequest] bedRequest (required):
  Future<BedResponse?> updateBed(String id, BedRequest bedRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateBedWithHttpInfo(id, bedRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BedResponse',) as BedResponse;
    
    }
    return null;
  }

  /// Update a unit
  ///
  /// Rental mode cannot change, and capacity cannot drop below the beds already defined.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UnitRequest] unitRequest (required):
  Future<Response> updateUnitWithHttpInfo(String id, UnitRequest unitRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/units/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = unitRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Update a unit
  ///
  /// Rental mode cannot change, and capacity cannot drop below the beds already defined.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UnitRequest] unitRequest (required):
  Future<UnitResponse?> updateUnit(String id, UnitRequest unitRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateUnitWithHttpInfo(id, unitRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UnitResponse',) as UnitResponse;
    
    }
    return null;
  }
}
