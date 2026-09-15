//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AdminApi {
  AdminApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a payment channel
  ///
  /// Added at the bottom, and shown to landlords unless visible is false.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<Response> addPaymentChannelWithHttpInfo(PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels';

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

  /// Add a payment channel
  ///
  /// Added at the bottom, and shown to landlords unless visible is false.
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<PaymentChannelResponse?> addPaymentChannel(PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    final response = await addPaymentChannelWithHttpInfo(paymentChannelRequest, abortTrigger: abortTrigger,);
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

  /// The money arrived
  ///
  /// Credits the statement. Settling it in full issues an invoice for each property and lifts the locks it caused.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> confirmPlatformPaymentWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payments/{id}/confirm'
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

  /// The money arrived
  ///
  /// Credits the statement. Settling it in full issues an invoice for each property and lifts the locks it caused.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<PlatformPaymentForAdmin?> confirmPlatformPayment(String id, { Future<void>? abortTrigger, }) async {
    final response = await confirmPlatformPaymentWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlatformPaymentForAdmin',) as PlatformPaymentForAdmin;
    
    }
    return null;
  }

  /// Delete a payment channel
  ///
  /// With its QR. Hide it instead to bring it back later.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deletePaymentChannelWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels/{id}'
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

  /// Delete a payment channel
  ///
  /// With its QR. Hide it instead to bring it back later.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deletePaymentChannel(String id, { Future<void>? abortTrigger, }) async {
    final response = await deletePaymentChannelWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// One property, opened up
  ///
  /// Every unit and bed, whether each is leased, vacant or out of service, and the tenancy running on it now with the tenant's name, phone and email. Never their ID or emergency contact, and never a tenant who has moved out.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getAdminPropertyWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/properties/{id}'
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

  /// One property, opened up
  ///
  /// Every unit and bed, whether each is leased, vacant or out of service, and the tenancy running on it now with the tenant's name, phone and email. Never their ID or emergency contact, and never a tenant who has moved out.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<AdminPropertyDetail?> getAdminProperty(String id, { Future<void>? abortTrigger, }) async {
    final response = await getAdminPropertyWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminPropertyDetail',) as AdminPropertyDetail;
    
    }
    return null;
  }

  /// One landlord and their properties
  ///
  /// Each property carries its own status, because each carries its own invoice.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getLandlordWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlords/{id}'
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

  /// One landlord and their properties
  ///
  /// Each property carries its own status, because each carries its own invoice.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<LandlordDetail?> getLandlord(String id, { Future<void>? abortTrigger, }) async {
    final response = await getLandlordWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LandlordDetail',) as LandlordDetail;
    
    }
    return null;
  }

  /// Settings the console owns
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getPlatformSettingsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/settings';

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

  /// Settings the console owns
  Future<PlatformSettings?> getPlatformSettings({ Future<void>? abortTrigger, }) async {
    final response = await getPlatformSettingsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlatformSettings',) as PlatformSettings;
    
    }
    return null;
  }

  /// Where to write to Lizmo
  ///
  /// Public: the account deletion page shows it, and that page must work for somebody who has already uninstalled the app.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getSupportContactWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/platform/support';

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

  /// Where to write to Lizmo
  ///
  /// Public: the account deletion page shows it, and that page must work for somebody who has already uninstalled the app.
  Future<SupportContact?> getSupportContact({ Future<void>? abortTrigger, }) async {
    final response = await getSupportContactWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SupportContact',) as SupportContact;
    
    }
    return null;
  }

  /// Invite a landlord
  ///
  /// Emails a link that lets somebody set up a landlord account. Good for seven days and one use; inviting the same address again replaces the earlier link.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InviteLandlordRequest] inviteLandlordRequest (required):
  Future<Response> inviteLandlordWithHttpInfo(InviteLandlordRequest inviteLandlordRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlord-invitations';

    // ignore: prefer_final_locals
    Object? postBody = inviteLandlordRequest;

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

  /// Invite a landlord
  ///
  /// Emails a link that lets somebody set up a landlord account. Good for seven days and one use; inviting the same address again replaces the earlier link.
  ///
  /// Parameters:
  ///
  /// * [InviteLandlordRequest] inviteLandlordRequest (required):
  Future<InvitationSentResponse?> inviteLandlord(InviteLandlordRequest inviteLandlordRequest, { Future<void>? abortTrigger, }) async {
    final response = await inviteLandlordWithHttpInfo(inviteLandlordRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitationSentResponse',) as InvitationSentResponse;
    
    }
    return null;
  }

  /// Invitations not yet taken up
  ///
  /// Expired ones included: somebody has to notice that a landlord never signed up. Never includes the token.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listInvitationsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlord-invitations';

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

  /// Invitations not yet taken up
  ///
  /// Expired ones included: somebody has to notice that a landlord never signed up. Never includes the token.
  Future<List<PendingInvitation>?> listInvitations({ Future<void>? abortTrigger, }) async {
    final response = await listInvitationsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PendingInvitation>') as List)
        .cast<PendingInvitation>()
        .toList(growable: false);

    }
    return null;
  }

  /// One landlord's statements
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> listLandlordStatementsWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlords/{id}/statements'
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

  /// One landlord's statements
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<List<PlatformStatementResponse>?> listLandlordStatements(String id, { Future<void>? abortTrigger, }) async {
    final response = await listLandlordStatementsWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PlatformStatementResponse>') as List)
        .cast<PlatformStatementResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Every landlord
  ///
  /// With their property count, how many are locked, and how many slots are occupied. Counts only — no tenant is named.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listLandlordsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlords';

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

  /// Every landlord
  ///
  /// With their property count, how many are locked, and how many slots are occupied. Counts only — no tenant is named.
  Future<List<LandlordSummary>?> listLandlords({ Future<void>? abortTrigger, }) async {
    final response = await listLandlordsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LandlordSummary>') as List)
        .cast<LandlordSummary>()
        .toList(growable: false);

    }
    return null;
  }

  /// Every payment channel
  ///
  /// Hidden ones included, in the order landlords see them.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPaymentChannelsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels';

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

  /// Every payment channel
  ///
  /// Hidden ones included, in the order landlords see them.
  Future<List<PaymentChannelResponse>?> listPaymentChannels({ Future<void>? abortTrigger, }) async {
    final response = await listPaymentChannelsWithHttpInfo(abortTrigger: abortTrigger,);
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

  /// Payments waiting to be checked
  ///
  /// Across every landlord, oldest first.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPlatformPaymentsToReviewWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payments';

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

  /// Payments waiting to be checked
  ///
  /// Across every landlord, oldest first.
  Future<List<PlatformPaymentForAdmin>?> listPlatformPaymentsToReview({ Future<void>? abortTrigger, }) async {
    final response = await listPlatformPaymentsToReviewWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PlatformPaymentForAdmin>') as List)
        .cast<PlatformPaymentForAdmin>()
        .toList(growable: false);

    }
    return null;
  }

  /// Stop a property being added to
  ///
  /// Blocks new units, new beds and accepting requests. Never affects the tenants already living there, and never stops the landlord ending a lease or declining a request.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> lockPropertyWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/properties/{id}/lock'
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

  /// Stop a property being added to
  ///
  /// Blocks new units, new beds and accepting requests. Never affects the tenants already living there, and never stops the landlord ending a lease or declining a request.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<AdminPropertySummary?> lockProperty(String id, { Future<void>? abortTrigger, }) async {
    final response = await lockPropertyWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminPropertySummary',) as AdminPropertySummary;
    
    }
    return null;
  }

  /// It did not arrive
  ///
  /// The landlord is told, with the reason.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PlatformPaymentRejection] platformPaymentRejection:
  Future<Response> rejectPlatformPaymentWithHttpInfo(String id, { PlatformPaymentRejection? platformPaymentRejection, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payments/{id}/reject'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = platformPaymentRejection;

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

  /// It did not arrive
  ///
  /// The landlord is told, with the reason.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PlatformPaymentRejection] platformPaymentRejection:
  Future<PlatformPaymentForAdmin?> rejectPlatformPayment(String id, { PlatformPaymentRejection? platformPaymentRejection, Future<void>? abortTrigger, }) async {
    final response = await rejectPlatformPaymentWithHttpInfo(id, platformPaymentRejection: platformPaymentRejection, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlatformPaymentForAdmin',) as PlatformPaymentForAdmin;
    
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
  Future<Response> removePaymentChannelQrWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels/{id}/qr'
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
  Future<PaymentChannelResponse?> removePaymentChannelQr(String id, { Future<void>? abortTrigger, }) async {
    final response = await removePaymentChannelQrWithHttpInfo(id, abortTrigger: abortTrigger,);
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

  /// Put the channels in order
  ///
  /// Every channel exactly once, top to bottom.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelOrder] paymentChannelOrder (required):
  Future<Response> reorderPaymentChannelsWithHttpInfo(PaymentChannelOrder paymentChannelOrder, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels/order';

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

  /// Put the channels in order
  ///
  /// Every channel exactly once, top to bottom.
  ///
  /// Parameters:
  ///
  /// * [PaymentChannelOrder] paymentChannelOrder (required):
  Future<List<PaymentChannelResponse>?> reorderPaymentChannels(PaymentChannelOrder paymentChannelOrder, { Future<void>? abortTrigger, }) async {
    final response = await reorderPaymentChannelsWithHttpInfo(paymentChannelOrder, abortTrigger: abortTrigger,);
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

  /// Withdraw an invitation
  ///
  /// For a wrong address, or somebody who should not have been invited. The link stops working immediately.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> revokeInvitationWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/landlord-invitations/{id}'
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

  /// Withdraw an invitation
  ///
  /// For a wrong address, or somebody who should not have been invited. The link stops working immediately.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> revokeInvitation(String id, { Future<void>? abortTrigger, }) async {
    final response = await revokeInvitationWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Let a property be managed again
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> unlockPropertyWithHttpInfo(String id, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/properties/{id}/unlock'
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

  /// Let a property be managed again
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<AdminPropertySummary?> unlockProperty(String id, { Future<void>? abortTrigger, }) async {
    final response = await unlockPropertyWithHttpInfo(id, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AdminPropertySummary',) as AdminPropertySummary;
    
    }
    return null;
  }

  /// Change a payment channel
  ///
  /// Visibility is left as it is when not sent.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<Response> updatePaymentChannelWithHttpInfo(String id, PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels/{id}'
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

  /// Change a payment channel
  ///
  /// Visibility is left as it is when not sent.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PaymentChannelRequest] paymentChannelRequest (required):
  Future<PaymentChannelResponse?> updatePaymentChannel(String id, PaymentChannelRequest paymentChannelRequest, { Future<void>? abortTrigger, }) async {
    final response = await updatePaymentChannelWithHttpInfo(id, paymentChannelRequest, abortTrigger: abortTrigger,);
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

  /// Change them
  ///
  /// The support address appears on a public page and is what a stranger is told to write to, so it is validated and who changed it is recorded.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PlatformSettings] platformSettings (required):
  Future<Response> updatePlatformSettingsWithHttpInfo(PlatformSettings platformSettings, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/settings';

    // ignore: prefer_final_locals
    Object? postBody = platformSettings;

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

  /// Change them
  ///
  /// The support address appears on a public page and is what a stranger is told to write to, so it is validated and who changed it is recorded.
  ///
  /// Parameters:
  ///
  /// * [PlatformSettings] platformSettings (required):
  Future<PlatformSettings?> updatePlatformSettings(PlatformSettings platformSettings, { Future<void>? abortTrigger, }) async {
    final response = await updatePlatformSettingsWithHttpInfo(platformSettings, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlatformSettings',) as PlatformSettings;
    
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
  Future<Response> uploadPaymentChannelQrWithHttpInfo(String id, MultipartFile qr, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/platform-payment-channels/{id}/qr'
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
  Future<PaymentChannelResponse?> uploadPaymentChannelQr(String id, MultipartFile qr, { Future<void>? abortTrigger, }) async {
    final response = await uploadPaymentChannelQrWithHttpInfo(id, qr, abortTrigger: abortTrigger,);
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
