//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TenantDocumentsApi {
  TenantDocumentsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// My photographs
  ///
  /// Each carries a presigned URL valid for a few minutes. Do not cache it; ask again instead.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyTenantDocumentsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/tenant-profile/documents';

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

  /// My photographs
  ///
  /// Each carries a presigned URL valid for a few minutes. Do not cache it; ask again instead.
  Future<List<TenantDocumentResponse>?> listMyTenantDocuments({ Future<void>? abortTrigger, }) async {
    final response = await listMyTenantDocumentsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<TenantDocumentResponse>') as List)
        .cast<TenantDocumentResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Upload a photograph
  ///
  /// Re-encoded on arrival, so no EXIF or location data is kept. Uploading again replaces what is there.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] docType (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Response> uploadMyTenantDocumentWithHttpInfo(String docType, MultipartFile file, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/tenant-profile/documents';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'docType', docType));

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
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

  /// Upload a photograph
  ///
  /// Re-encoded on arrival, so no EXIF or location data is kept. Uploading again replaces what is there.
  ///
  /// Parameters:
  ///
  /// * [String] docType (required):
  ///
  /// * [MultipartFile] file (required):
  Future<TenantDocumentResponse?> uploadMyTenantDocument(String docType, MultipartFile file, { Future<void>? abortTrigger, }) async {
    final response = await uploadMyTenantDocumentWithHttpInfo(docType, file, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TenantDocumentResponse',) as TenantDocumentResponse;
    
    }
    return null;
  }
}
