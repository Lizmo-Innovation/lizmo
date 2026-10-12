//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AnnouncementsApi {
  AnnouncementsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Announcements where I live
  ///
  /// Everything up in the buildings, and units, I rent in now, newest first.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyNoticesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/notices';

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

  /// Announcements where I live
  ///
  /// Everything up in the buildings, and units, I rent in now, newest first.
  Future<List<MyNoticeResponse>?> listMyNotices({ Future<void>? abortTrigger, }) async {
    final response = await listMyNoticesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<MyNoticeResponse>') as List)
        .cast<MyNoticeResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Announcements up on a building
  ///
  /// Newest first, with how many of the people each is for have opened it. Taken-down ones are not listed.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> listPropertyNoticesWithHttpInfo(String propertyId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/properties/{propertyId}/notices'
      .replaceAll('{propertyId}', propertyId);

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

  /// Announcements up on a building
  ///
  /// Newest first, with how many of the people each is for have opened it. Taken-down ones are not listed.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<List<NoticeResponse>?> listPropertyNotices(String propertyId, { Future<void>? abortTrigger, }) async {
    final response = await listPropertyNoticesWithHttpInfo(propertyId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NoticeResponse>') as List)
        .cast<NoticeResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// I have read this announcement
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> markNoticeReadWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/notices/{id}/read'
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

  /// I have read this announcement
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> markNoticeRead(String id, { Future<void>? abortTrigger, }) async {
    final response = await markNoticeReadWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Post an announcement
  ///
  /// To everybody renting in the building, or in one unit. Those living there now are notified; anybody who moves in while it is up sees it too. Cannot be edited: take it down and post again.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [PostNotice] postNotice (required):
  Future<Response> postNoticeWithHttpInfo(String propertyId, PostNotice postNotice, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/properties/{propertyId}/notices'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody = postNotice;

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

  /// Post an announcement
  ///
  /// To everybody renting in the building, or in one unit. Those living there now are notified; anybody who moves in while it is up sees it too. Cannot be edited: take it down and post again.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [PostNotice] postNotice (required):
  Future<NoticeResponse?> postNotice(String propertyId, PostNotice postNotice, { Future<void>? abortTrigger, }) async {
    final response = await postNoticeWithHttpInfo(propertyId, postNotice, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NoticeResponse',) as NoticeResponse;
    
    }
    return null;
  }

  /// Take an announcement down
  ///
  /// Gone from every tenant's screen. Nobody is told.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> takeDownNoticeWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/notices/{id}/take-down'
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

  /// Take an announcement down
  ///
  /// Gone from every tenant's screen. Nobody is told.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> takeDownNotice(String id, { Future<void>? abortTrigger, }) async {
    final response = await takeDownNoticeWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
