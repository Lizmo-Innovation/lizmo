//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DevicesApi {
  DevicesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Stop pushing to this phone
  ///
  /// On signing out, so a shared phone stops being told the last person's business. Only ever the caller's own.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> forgetDeviceWithHttpInfo(String token, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/devices';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'token', token));

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

  /// Stop pushing to this phone
  ///
  /// On signing out, so a shared phone stops being told the last person's business. Only ever the caller's own.
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<void> forgetDevice(String token, { Future<void>? abortTrigger, }) async {
    final response = await forgetDeviceWithHttpInfo(token, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Push to this phone
  ///
  /// After signing in, and whenever the phone's token changes. The same token twice is one phone; a token another account held moves here.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RegisterDevice] registerDevice (required):
  Future<Response> registerDeviceWithHttpInfo(RegisterDevice registerDevice, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/devices';

    // ignore: prefer_final_locals
    Object? postBody = registerDevice;

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

  /// Push to this phone
  ///
  /// After signing in, and whenever the phone's token changes. The same token twice is one phone; a token another account held moves here.
  ///
  /// Parameters:
  ///
  /// * [RegisterDevice] registerDevice (required):
  Future<void> registerDevice(RegisterDevice registerDevice, { Future<void>? abortTrigger, }) async {
    final response = await registerDeviceWithHttpInfo(registerDevice, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
