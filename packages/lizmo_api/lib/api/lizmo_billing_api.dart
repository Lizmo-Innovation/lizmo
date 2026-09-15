//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LizmoBillingApi {
  LizmoBillingApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// How to pay Lizmo
  ///
  /// The channels an admin has made visible, in order, each with its QR when it has one, and the note shown under them. Landlords only.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getPlatformPaymentDetailsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/platform-payment-details';

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

  /// How to pay Lizmo
  ///
  /// The channels an admin has made visible, in order, each with its QR when it has one, and the note shown under them. Landlords only.
  Future<PaymentDetails?> getPlatformPaymentDetails({ Future<void>? abortTrigger, }) async {
    final response = await getPlatformPaymentDetailsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentDetails',) as PaymentDetails;
    
    }
    return null;
  }

  /// My Lizmo statements
  ///
  /// One a month, newest first, itemised by property, with what has been sent against each. A line carries an invoice number once the statement is paid.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyPlatformStatementsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/platform-statements';

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

  /// My Lizmo statements
  ///
  /// One a month, newest first, itemised by property, with what has been sent against each. A line carries an invoice number once the statement is paid.
  Future<List<PlatformStatementResponse>?> listMyPlatformStatements({ Future<void>? abortTrigger, }) async {
    final response = await listMyPlatformStatementsWithHttpInfo(abortTrigger: abortTrigger,);
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

  /// Say I have paid Lizmo
  ///
  /// Waits for a Lizmo admin to confirm it. Proof is required. The photograph is re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] amountPaid (required):
  ///
  /// * [String] paymentDate:
  ///   When the money moved, as YYYY-MM-DD. Defaults to today.
  ///
  /// * [String] paymentMethod:
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] proof:
  Future<Response> payPlatformStatementWithHttpInfo(String id, String amountPaid, { String? paymentDate, String? paymentMethod, String? remarks, MultipartFile? proof, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/platform-statements/{id}/payments'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (amountPaid != null) {
      hasFields = true;
      mp.fields[r'amountPaid'] = parameterToString(amountPaid);
    }
    if (paymentDate != null) {
      hasFields = true;
      mp.fields[r'paymentDate'] = parameterToString(paymentDate);
    }
    if (paymentMethod != null) {
      hasFields = true;
      mp.fields[r'paymentMethod'] = parameterToString(paymentMethod);
    }
    if (remarks != null) {
      hasFields = true;
      mp.fields[r'remarks'] = parameterToString(remarks);
    }
    if (proof != null) {
      hasFields = true;
      mp.fields[r'proof'] = proof.field;
      mp.files.add(proof);
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

  /// Say I have paid Lizmo
  ///
  /// Waits for a Lizmo admin to confirm it. Proof is required. The photograph is re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] amountPaid (required):
  ///
  /// * [String] paymentDate:
  ///   When the money moved, as YYYY-MM-DD. Defaults to today.
  ///
  /// * [String] paymentMethod:
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] proof:
  Future<PlatformStatementResponse?> payPlatformStatement(String id, String amountPaid, { String? paymentDate, String? paymentMethod, String? remarks, MultipartFile? proof, Future<void>? abortTrigger, }) async {
    final response = await payPlatformStatementWithHttpInfo(id, amountPaid, paymentDate: paymentDate, paymentMethod: paymentMethod, remarks: remarks, proof: proof, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlatformStatementResponse',) as PlatformStatementResponse;
    
    }
    return null;
  }
}
