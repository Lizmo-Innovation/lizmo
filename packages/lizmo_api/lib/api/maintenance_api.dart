//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MaintenanceApi {
  MaintenanceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a photo to my report
  ///
  /// Up to three, while nobody has started on it. Re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MultipartFile] photo (required):
  Future<Response> addMaintenancePhotoWithHttpInfo(String id, MultipartFile photo, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance/{id}/photos'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (photo != null) {
      hasFields = true;
      mp.fields[r'photo'] = photo.field;
      mp.files.add(photo);
    }
    if (hasFields) {
      postBody = mp;
    }

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

  /// Add a photo to my report
  ///
  /// Up to three, while nobody has started on it. Re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MultipartFile] photo (required):
  Future<MaintenanceReportResponse?> addMaintenancePhoto(String id, MultipartFile photo, { Future<void>? abortTrigger, }) async {
    final response = await addMaintenancePhotoWithHttpInfo(id, photo, abortTrigger: abortTrigger,);
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

  /// Say it is fixed
  ///
  /// Closes a report the landlord has marked resolved.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> confirmMaintenanceFixedWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance/{id}/fixed'
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

  /// Say it is fixed
  ///
  /// Closes a report the landlord has marked resolved.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MaintenanceReportResponse?> confirmMaintenanceFixed(String id, { Future<void>? abortTrigger, }) async {
    final response = await confirmMaintenanceFixedWithHttpInfo(id, abortTrigger: abortTrigger,);
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

  /// What I have reported
  ///
  /// Newest first, whatever became of each.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyMaintenanceReportsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance';

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

  /// What I have reported
  ///
  /// Newest first, whatever became of each.
  Future<List<MaintenanceReportResponse>?> listMyMaintenanceReports({ Future<void>? abortTrigger, }) async {
    final response = await listMyMaintenanceReportsWithHttpInfo(abortTrigger: abortTrigger,);
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

  /// Say it is still broken
  ///
  /// On a report the landlord has marked resolved. A reason is required: it is the whole of what the landlord needs to hear.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote (required):
  Future<Response> reopenMaintenanceReportWithHttpInfo(String id, MaintenanceNote maintenanceNote, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance/{id}/reopen'
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

  /// Say it is still broken
  ///
  /// On a report the landlord has marked resolved. A reason is required: it is the whole of what the landlord needs to hear.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MaintenanceNote] maintenanceNote (required):
  Future<MaintenanceReportResponse?> reopenMaintenanceReport(String id, MaintenanceNote maintenanceNote, { Future<void>? abortTrigger, }) async {
    final response = await reopenMaintenanceReportWithHttpInfo(id, maintenanceNote, abortTrigger: abortTrigger,);
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

  /// Report something broken
  ///
  /// Against the tenancy the caller is living under now. The landlord is told. Photos are added afterwards, one at a time.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ReportProblemRequest] reportProblemRequest (required):
  Future<Response> reportProblemWithHttpInfo(ReportProblemRequest reportProblemRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance';

    // ignore: prefer_final_locals
    Object? postBody = reportProblemRequest;

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

  /// Report something broken
  ///
  /// Against the tenancy the caller is living under now. The landlord is told. Photos are added afterwards, one at a time.
  ///
  /// Parameters:
  ///
  /// * [ReportProblemRequest] reportProblemRequest (required):
  Future<MaintenanceReportResponse?> reportProblem(ReportProblemRequest reportProblemRequest, { Future<void>? abortTrigger, }) async {
    final response = await reportProblemWithHttpInfo(reportProblemRequest, abortTrigger: abortTrigger,);
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

  /// Take my report back
  ///
  /// Only while nobody has started on it. Kept, not deleted.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> withdrawMaintenanceReportWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/maintenance/{id}/withdraw'
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

  /// Take my report back
  ///
  /// Only while nobody has started on it. Kept, not deleted.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MaintenanceReportResponse?> withdrawMaintenanceReport(String id, { Future<void>? abortTrigger, }) async {
    final response = await withdrawMaintenanceReportWithHttpInfo(id, abortTrigger: abortTrigger,);
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
