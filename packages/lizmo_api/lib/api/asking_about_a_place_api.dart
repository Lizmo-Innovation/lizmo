//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AskingAboutAPlaceApi {
  AskingAboutAPlaceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// End it
  ///
  /// From either side. Asking about the place again reopens it.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> closeInquiryWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries/{id}/close'
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

  /// End it
  ///
  /// From either side. Asking about the place again reopens it.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<InquirySummary?> closeInquiry(String id, { Future<void>? abortTrigger, }) async {
    final response = await closeInquiryWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InquirySummary',) as InquirySummary;
    
    }
    return null;
  }

  /// My conversations
  ///
  /// Both sides: threads I started, and threads about places I let. Most recently spoken in first.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyInquiriesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries';

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

  /// My conversations
  ///
  /// Both sides: threads I started, and threads about places I let. Most recently spoken in first.
  Future<List<InquirySummary>?> listMyInquiries({ Future<void>? abortTrigger, }) async {
    final response = await listMyInquiriesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<InquirySummary>') as List)
        .cast<InquirySummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// Mark it seen
  ///
  /// For a list the reader has been through without opening every thread.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> markInquiryReadWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries/{id}/read'
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

  /// Mark it seen
  ///
  /// For a list the reader has been through without opening every thread.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> markInquiryRead(String id, { Future<void>? abortTrigger, }) async {
    final response = await markInquiryReadWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// One conversation
  ///
  /// Everything said in it. Reading it marks it seen for whoever asked.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> readInquiryWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries/{id}'
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

  /// One conversation
  ///
  /// Everything said in it. Reading it marks it seen for whoever asked.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<InquiryThread?> readInquiry(String id, { Future<void>? abortTrigger, }) async {
    final response = await readInquiryWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InquiryThread',) as InquiryThread;
    
    }
    return null;
  }

  /// Say something
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [NewMessage] newMessage (required):
  Future<Response> sendInquiryMessageWithHttpInfo(String id, NewMessage newMessage, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries/{id}/messages'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = newMessage;

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

  /// Say something
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [NewMessage] newMessage (required):
  Future<InquiryMessageResponse?> sendInquiryMessage(String id, NewMessage newMessage, { Future<void>? abortTrigger, }) async {
    final response = await sendInquiryMessageWithHttpInfo(id, newMessage, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InquiryMessageResponse',) as InquiryMessageResponse;
    
    }
    return null;
  }

  /// Ask about a place
  ///
  /// Starts the conversation, or reopens the one that already exists with this landlord about this property. Needs a contact number, so they can ring back.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StartInquiry] startInquiry (required):
  Future<Response> startInquiryWithHttpInfo(StartInquiry startInquiry, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries';

    // ignore: prefer_final_locals
    Object? postBody = startInquiry;

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

  /// Ask about a place
  ///
  /// Starts the conversation, or reopens the one that already exists with this landlord about this property. Needs a contact number, so they can ring back.
  ///
  /// Parameters:
  ///
  /// * [StartInquiry] startInquiry (required):
  Future<InquiryThread?> startInquiry(StartInquiry startInquiry, { Future<void>? abortTrigger, }) async {
    final response = await startInquiryWithHttpInfo(startInquiry, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InquiryThread',) as InquiryThread;
    
    }
    return null;
  }

  /// Write the tenancy they agreed on
  ///
  /// The landlord, from inside the conversation. The room has to be named here: the tenant was never shown which rooms exist. Everything else defaults to the asking rent, today, and the day of the month they move in.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AcceptRequest] acceptRequest:
  Future<Response> startLeaseFromInquiryWithHttpInfo(String id, { AcceptRequest? acceptRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inquiries/{id}/lease'
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

  /// Write the tenancy they agreed on
  ///
  /// The landlord, from inside the conversation. The room has to be named here: the tenant was never shown which rooms exist. Everything else defaults to the asking rent, today, and the day of the month they move in.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AcceptRequest] acceptRequest:
  Future<LeaseResponse?> startLeaseFromInquiry(String id, { AcceptRequest? acceptRequest, Future<void>? abortTrigger, }) async {
    final response = await startLeaseFromInquiryWithHttpInfo(id, acceptRequest: acceptRequest, abortTrigger: abortTrigger,);
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
}
