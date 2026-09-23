//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PaymentChannelsApi {
  PaymentChannelsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a way to pay me
  ///
  /// Added at the bottom, and shown to tenants unless visible is false.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<Response> addMyPaymentChannelWithHttpInfo(PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels';

    // ignore: prefer_final_locals
    Object? postBody = paymentChannelRequest;

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

  /// Add a way to pay me
  ///
  /// Added at the bottom, and shown to tenants unless visible is false.
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<PaymentChannelResponse?> addMyPaymentChannel(PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    final response = await addMyPaymentChannelWithHttpInfo(paymentChannelRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentChannelResponse',) as PaymentChannelResponse;
    
    }
    return null;
  }

  /// Delete a way to pay me
  ///
  /// With its QR. Hide it instead to bring it back later.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteMyPaymentChannelWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/{id}'
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

  /// Delete a way to pay me
  ///
  /// With its QR. Hide it instead to bring it back later.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteMyPaymentChannel(String id, { Future<void>? abortTrigger, }) async {
    final response = await deleteMyPaymentChannelWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// The note under my channels
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMyPaymentNoteWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-note';

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

  /// The note under my channels
  Future<PaymentNote?> getMyPaymentNote({ Future<void>? abortTrigger, }) async {
    final response = await getMyPaymentNoteWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentNote',) as PaymentNote;
    
    }
    return null;
  }

  /// How my tenants pay me
  ///
  /// Hidden ones included, in the order tenants see them.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyPaymentChannelsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels';

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

  /// How my tenants pay me
  ///
  /// Hidden ones included, in the order tenants see them.
  Future<List<PaymentChannelResponse>?> listMyPaymentChannels({ Future<void>? abortTrigger, }) async {
    final response = await listMyPaymentChannelsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PaymentChannelResponse>') as List)
        .cast<PaymentChannelResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Remove a channel's QR
  ///
  /// The channel stays, with its name and number.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> removeMyPaymentChannelQrWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/{id}/qr'
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

  /// Remove a channel's QR
  ///
  /// The channel stays, with its name and number.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<PaymentChannelResponse?> removeMyPaymentChannelQr(String id, { Future<void>? abortTrigger, }) async {
    final response = await removeMyPaymentChannelQrWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentChannelResponse',) as PaymentChannelResponse;
    
    }
    return null;
  }

  /// Put my channels in order
  ///
  /// Every channel exactly once, top to bottom.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelOrder] paymentChannelOrder (required):
  Future<Response> reorderMyPaymentChannelsWithHttpInfo(PaymentChannelOrder paymentChannelOrder, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/order';

    // ignore: prefer_final_locals
    Object? postBody = paymentChannelOrder;

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

  /// Put my channels in order
  ///
  /// Every channel exactly once, top to bottom.
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelOrder] paymentChannelOrder (required):
  Future<List<PaymentChannelResponse>?> reorderMyPaymentChannels(PaymentChannelOrder paymentChannelOrder, { Future<void>? abortTrigger, }) async {
    final response = await reorderMyPaymentChannelsWithHttpInfo(paymentChannelOrder, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PaymentChannelResponse>') as List)
        .cast<PaymentChannelResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Choose which properties a way to pay is for
  ///
  /// The whole list: what is sent replaces what was there. An empty list reaches no tenant, which is allowed -- their Rent tab then says the landlord has not added how to pay yet.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ChannelProperties] channelProperties (required):
  Future<Response> setMyPaymentChannelPropertiesWithHttpInfo(String id, ChannelProperties channelProperties, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/{id}/properties'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = channelProperties;

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

  /// Choose which properties a way to pay is for
  ///
  /// The whole list: what is sent replaces what was there. An empty list reaches no tenant, which is allowed -- their Rent tab then says the landlord has not added how to pay yet.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ChannelProperties] channelProperties (required):
  Future<PaymentChannelResponse?> setMyPaymentChannelProperties(String id, ChannelProperties channelProperties, { Future<void>? abortTrigger, }) async {
    final response = await setMyPaymentChannelPropertiesWithHttpInfo(id, channelProperties, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentChannelResponse',) as PaymentChannelResponse;
    
    }
    return null;
  }

  /// Change a way to pay me
  ///
  /// Visibility is left as it is when not sent. Past payments keep the details they were sent to.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<Response> updateMyPaymentChannelWithHttpInfo(String id, PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/{id}'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = paymentChannelRequest;

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

  /// Change a way to pay me
  ///
  /// Visibility is left as it is when not sent. Past payments keep the details they were sent to.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<PaymentChannelResponse?> updateMyPaymentChannel(String id, PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    final response = await updateMyPaymentChannelWithHttpInfo(id, paymentChannelRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentChannelResponse',) as PaymentChannelResponse;
    
    }
    return null;
  }

  /// Change the note under my channels
  ///
  /// Blank clears it.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PaymentNote] paymentNote (required):
  Future<Response> updateMyPaymentNoteWithHttpInfo(PaymentNote paymentNote, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-note';

    // ignore: prefer_final_locals
    Object? postBody = paymentNote;

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

  /// Change the note under my channels
  ///
  /// Blank clears it.
  ///
  /// Parameters:
  ///
  /// * [PaymentNote] paymentNote (required):
  Future<PaymentNote?> updateMyPaymentNote(PaymentNote paymentNote, { Future<void>? abortTrigger, }) async {
    final response = await updateMyPaymentNoteWithHttpInfo(paymentNote, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentNote',) as PaymentNote;
    
    }
    return null;
  }

  /// Set a channel's QR
  ///
  /// Replaces any QR it had. Re-encoded, so no EXIF or location is kept.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MultipartFile] qr (required):
  Future<Response> uploadMyPaymentChannelQrWithHttpInfo(String id, MultipartFile qr, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/payment-channels/{id}/qr'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (qr != null) {
      hasFields = true;
      mp.fields[r'qr'] = qr.field;
      mp.files.add(qr);
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

  /// Set a channel's QR
  ///
  /// Replaces any QR it had. Re-encoded, so no EXIF or location is kept.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MultipartFile] qr (required):
  Future<PaymentChannelResponse?> uploadMyPaymentChannelQr(String id, MultipartFile qr, { Future<void>? abortTrigger, }) async {
    final response = await uploadMyPaymentChannelQrWithHttpInfo(id, qr, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentChannelResponse',) as PaymentChannelResponse;
    
    }
    return null;
  }
}
