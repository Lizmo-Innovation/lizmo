//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SigningUpApi {
  SigningUpApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Become a landlord
  ///
  /// Spends the invitation and signs you in. A new account needs a name and a password of its own; an address that already signs in to Lizmo needs that account's password, and keeps its tenant side.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AcceptInvitationRequest] acceptInvitationRequest (required):
  Future<Response> acceptInvitationWithHttpInfo(AcceptInvitationRequest acceptInvitationRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/invitations/accept';

    // ignore: prefer_final_locals
    Object? postBody = acceptInvitationRequest;

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

  /// Become a landlord
  ///
  /// Spends the invitation and signs you in. A new account needs a name and a password of its own; an address that already signs in to Lizmo needs that account's password, and keeps its tenant side.
  ///
  /// Parameters:
  ///
  /// * [AcceptInvitationRequest] acceptInvitationRequest (required):
  Future<AuthResponse?> acceptInvitation(AcceptInvitationRequest acceptInvitationRequest, { Future<void>? abortTrigger, }) async {
    final response = await acceptInvitationWithHttpInfo(acceptInvitationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthResponse',) as AuthResponse;
    
    }
    return null;
  }

  /// Finish signing up
  ///
  /// Spends the code and creates the account. The password needs at least eight characters, with a capital, a small letter, a number and a symbol.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CompleteRegistrationRequest] completeRegistrationRequest (required):
  Future<Response> completeRegistrationWithHttpInfo(CompleteRegistrationRequest completeRegistrationRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/register/complete';

    // ignore: prefer_final_locals
    Object? postBody = completeRegistrationRequest;

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

  /// Finish signing up
  ///
  /// Spends the code and creates the account. The password needs at least eight characters, with a capital, a small letter, a number and a symbol.
  ///
  /// Parameters:
  ///
  /// * [CompleteRegistrationRequest] completeRegistrationRequest (required):
  Future<AuthResponse?> completeRegistration(CompleteRegistrationRequest completeRegistrationRequest, { Future<void>? abortTrigger, }) async {
    final response = await completeRegistrationWithHttpInfo(completeRegistrationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthResponse',) as AuthResponse;
    
    }
    return null;
  }

  /// What this invitation is for
  ///
  /// Says which address was invited and whether it already has a Lizmo account, so the screen knows whether to ask for a new password or the existing one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> getInvitationWithHttpInfo(String token, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/invitations/{token}'
      .replaceAll('{token}', token);

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

  /// What this invitation is for
  ///
  /// Says which address was invited and whether it already has a Lizmo account, so the screen knows whether to ask for a new password or the existing one.
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<InvitationDetailsResponse?> getInvitation(String token, { Future<void>? abortTrigger, }) async {
    final response = await getInvitationWithHttpInfo(token, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitationDetailsResponse',) as InvitationDetailsResponse;
    
    }
    return null;
  }

  /// Send me a code
  ///
  /// Emails a six-digit code, good for ten minutes and one use. Asking again replaces any code already sent to that address.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StartRegistrationRequest] startRegistrationRequest (required):
  Future<Response> startRegistrationWithHttpInfo(StartRegistrationRequest startRegistrationRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/register/start';

    // ignore: prefer_final_locals
    Object? postBody = startRegistrationRequest;

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

  /// Send me a code
  ///
  /// Emails a six-digit code, good for ten minutes and one use. Asking again replaces any code already sent to that address.
  ///
  /// Parameters:
  ///
  /// * [StartRegistrationRequest] startRegistrationRequest (required):
  Future<StartRegistrationResponse?> startRegistration(StartRegistrationRequest startRegistrationRequest, { Future<void>? abortTrigger, }) async {
    final response = await startRegistrationWithHttpInfo(startRegistrationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'StartRegistrationResponse',) as StartRegistrationResponse;
    
    }
    return null;
  }
}
