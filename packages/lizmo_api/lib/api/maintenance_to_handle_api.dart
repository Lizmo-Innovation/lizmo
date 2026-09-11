//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MaintenanceToHandleApi {
  MaintenanceToHandleApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// One report in full
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getMaintenanceReportWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/maintenance/{id}'
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

  /// One report in full
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MaintenanceReportResponse?> getMaintenanceReport(String id, { Future<void>? abortTrigger, }) async {
    final response = await getMaintenanceReportWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MaintenanceReportResponse',) as MaintenanceReportResponse;
    
    }
    return null;
  }

  /// Everything reported on my properties
  ///
  /// Newest first, across every property, whatever became of each.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMaintenanceReportsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/maintenance';

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

  /// Everything reported on my properties
  ///
  /// Newest first, across every property, whatever became of each.
  Future<List<MaintenanceReportResponse>?> listMaintenanceReports({ Future<void>? abortTrigger, }) async {
    final response = await listMaintenanceReportsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<MaintenanceReportResponse>') as List)
        .cast<MaintenanceReportResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Say it is fixed
  ///
  /// The tenant is asked to confirm, or to say it is still broken.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote:
  Future<Response> resolveMaintenanceWithHttpInfo(String id, { MaintenanceNote? maintenanceNote, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/maintenance/{id}/resolve'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = maintenanceNote;

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

  /// Say it is fixed
  ///
  /// The tenant is asked to confirm, or to say it is still broken.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote:
  Future<MaintenanceReportResponse?> resolveMaintenance(String id, { MaintenanceNote? maintenanceNote, Future<void>? abortTrigger, }) async {
    final response = await resolveMaintenanceWithHttpInfo(id, maintenanceNote: maintenanceNote, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MaintenanceReportResponse',) as MaintenanceReportResponse;
    
    }
    return null;
  }

  /// Start on it
  ///
  /// The tenant is told, with the remark if there is one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote:
  Future<Response> startMaintenanceWithHttpInfo(String id, { MaintenanceNote? maintenanceNote, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/maintenance/{id}/start'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = maintenanceNote;

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

  /// Start on it
  ///
  /// The tenant is told, with the remark if there is one.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote:
  Future<MaintenanceReportResponse?> startMaintenance(String id, { MaintenanceNote? maintenanceNote, Future<void>? abortTrigger, }) async {
    final response = await startMaintenanceWithHttpInfo(id, maintenanceNote: maintenanceNote, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MaintenanceReportResponse',) as MaintenanceReportResponse;
    
    }
    return null;
  }
}
