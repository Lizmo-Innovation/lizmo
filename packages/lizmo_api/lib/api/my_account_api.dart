//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MyAccountApi {
  MyAccountApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Whether this account can be closed
  ///
  /// 204 when it can. Asked before the confirmation screen, so somebody is told why not while they can still act on it rather than after they have typed DELETE.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> checkAccountDeletableWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/deletable';

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

  /// Whether this account can be closed
  ///
  /// 204 when it can. Asked before the confirmation screen, so somebody is told why not while they can still act on it rather than after they have typed DELETE.
  Future<void> checkAccountDeletable({ Future<void>? abortTrigger, }) async {
    final response = await checkAccountDeletableWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Close my account
  ///
  /// Ends every session, deletes the photographs of your ID, and removes your name, phone number and profile details. Leases and the history of what was paid stay, attached to an id that no longer names anybody, because they are your landlord's records as much as yours.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> deleteMyAccountWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me';

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

  /// Close my account
  ///
  /// Ends every session, deletes the photographs of your ID, and removes your name, phone number and profile details. Leases and the history of what was paid stay, attached to an id that no longer names anybody, because they are your landlord's records as much as yours.
  Future<void> deleteMyAccount({ Future<void>? abortTrigger, }) async {
    final response = await deleteMyAccountWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
