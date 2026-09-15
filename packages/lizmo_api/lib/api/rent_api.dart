//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RentApi {
  RentApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Agree the money arrived
  ///
  /// The only thing that moves a balance for a payment a tenant declared. Answering twice is refused, which is the one way this could quietly invent money.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] paymentId (required):
  Future<Response> confirmPaymentWithHttpInfo(String leaseId, String paymentId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/payments/{paymentId}/confirm'
      .replaceAll('{leaseId}', leaseId)
      .replaceAll('{paymentId}', paymentId);

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

  /// Agree the money arrived
  ///
  /// The only thing that moves a balance for a payment a tenant declared. Answering twice is refused, which is the one way this could quietly invent money.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] paymentId (required):
  Future<PaymentResponse?> confirmPayment(String leaseId, String paymentId, { Future<void>? abortTrigger, }) async {
    final response = await confirmPaymentWithHttpInfo(leaseId, paymentId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentResponse',) as PaymentResponse;
    
    }
    return null;
  }

  /// Say I have paid
  ///
  /// Waits for the landlord to confirm; nothing about the balance moves until they do. A screenshot is optional -- cash is real, and a required field nobody can satisfy becomes one people lie in. Any photograph is re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] billingPeriodId (required):
  ///   Which month this pays for
  ///
  /// * [String] amountPaid (required):
  ///
  /// * [String] paymentDate:
  ///   When the money moved, as YYYY-MM-DD. Defaults to today.
  ///
  /// * [String] paymentMethod:
  ///   Defaults to OTHER
  ///
  /// * [String] remarks:
  ///
  /// * [String] channelId:
  ///   Which of the landlord's payment channels it was sent to
  ///
  /// * [MultipartFile] proof:
  Future<Response> declarePaymentWithHttpInfo(String leaseId, String billingPeriodId, String amountPaid, { String? paymentDate, String? paymentMethod, String? remarks, String? channelId, MultipartFile? proof, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/payments'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (billingPeriodId != null) {
      hasFields = true;
      mp.fields[r'billingPeriodId'] = parameterToString(billingPeriodId);
    }
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
    if (channelId != null) {
      hasFields = true;
      mp.fields[r'channelId'] = parameterToString(channelId);
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

  /// Say I have paid
  ///
  /// Waits for the landlord to confirm; nothing about the balance moves until they do. A screenshot is optional -- cash is real, and a required field nobody can satisfy becomes one people lie in. Any photograph is re-encoded, so no EXIF or location leaves the phone.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] billingPeriodId (required):
  ///   Which month this pays for
  ///
  /// * [String] amountPaid (required):
  ///
  /// * [String] paymentDate:
  ///   When the money moved, as YYYY-MM-DD. Defaults to today.
  ///
  /// * [String] paymentMethod:
  ///   Defaults to OTHER
  ///
  /// * [String] remarks:
  ///
  /// * [String] channelId:
  ///   Which of the landlord's payment channels it was sent to
  ///
  /// * [MultipartFile] proof:
  Future<PaymentResponse?> declarePayment(String leaseId, String billingPeriodId, String amountPaid, { String? paymentDate, String? paymentMethod, String? remarks, String? channelId, MultipartFile? proof, Future<void>? abortTrigger, }) async {
    final response = await declarePaymentWithHttpInfo(leaseId, billingPeriodId, amountPaid, paymentDate: paymentDate, paymentMethod: paymentMethod, remarks: remarks, channelId: channelId, proof: proof, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentResponse',) as PaymentResponse;
    
    }
    return null;
  }

  /// How rent is going
  ///
  /// Due and collected this month, everything still outstanding, and who is behind -- worst first. Asking also brings the schedule up to date, so a tenancy nobody has opened this month is still counted.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getCollectionsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/collections';

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

  /// How rent is going
  ///
  /// Due and collected this month, everything still outstanding, and who is behind -- worst first. Asking also brings the schedule up to date, so a tenancy nobody has opened this month is still counted.
  Future<CollectionsSummary?> getCollections({ Future<void>? abortTrigger, }) async {
    final response = await getCollectionsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CollectionsSummary',) as CollectionsSummary;
    
    }
    return null;
  }

  /// How to pay my landlord
  ///
  /// The channels the landlord behind this lease has switched on, in order, each with its QR when it has one, and their note. Also after moving out.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> getLeasePaymentDetailsWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/payment-details'
      .replaceAll('{leaseId}', leaseId);

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

  /// How to pay my landlord
  ///
  /// The channels the landlord behind this lease has switched on, in order, each with its QR when it has one, and their note. Also after moving out.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<PaymentDetails?> getLeasePaymentDetails(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await getLeasePaymentDetailsWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
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

  /// Every tenancy's rent for one month
  ///
  /// A month's rent belongs to the month it falls due in, as on the dashboard. Tenancies that have since ended still appear for the months they owed. Asking brings live schedules up to date first.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] month:
  ///   As 2026-09. This month when left out.
  Future<Response> getRentRollWithHttpInfo({ String? month, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/rent-roll';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (month != null) {
      queryParams.addAll(_queryParams('', 'month', month));
    }

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

  /// Every tenancy's rent for one month
  ///
  /// A month's rent belongs to the month it falls due in, as on the dashboard. Tenancies that have since ended still appear for the months they owed. Asking brings live schedules up to date first.
  ///
  /// Parameters:
  ///
  /// * [String] month:
  ///   As 2026-09. This month when left out.
  Future<RentRoll?> getRentRoll({ String? month, Future<void>? abortTrigger, }) async {
    final response = await getRentRollWithHttpInfo(month: month, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentRoll',) as RentRoll;
    
    }
    return null;
  }

  /// Rent on this tenancy
  ///
  /// Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listLeaseBillingWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/billing'
      .replaceAll('{leaseId}', leaseId);

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

  /// Rent on this tenancy
  ///
  /// Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<BillingPeriodResponse>?> listLeaseBilling(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listLeaseBillingWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BillingPeriodResponse>') as List)
        .cast<BillingPeriodResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Payments on this tenancy
  ///
  /// Newest first, whatever their state. A rejected payment stays in the list: the disagreement is worth keeping.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listLeasePaymentsWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/payments'
      .replaceAll('{leaseId}', leaseId);

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

  /// Payments on this tenancy
  ///
  /// Newest first, whatever their state. A rejected payment stays in the list: the disagreement is worth keeping.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<PaymentResponse>?> listLeasePayments(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listLeasePaymentsWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PaymentResponse>') as List)
        .cast<PaymentResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// My rent
  ///
  /// The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listMyBillingWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/billing'
      .replaceAll('{leaseId}', leaseId);

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

  /// My rent
  ///
  /// The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<BillingPeriodResponse>?> listMyBilling(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listMyBillingWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BillingPeriodResponse>') as List)
        .cast<BillingPeriodResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// What I have paid
  ///
  /// Including anything still waiting to be confirmed, and anything the landlord refused.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listMyPaymentsWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/payments'
      .replaceAll('{leaseId}', leaseId);

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

  /// What I have paid
  ///
  /// Including anything still waiting to be confirmed, and anything the landlord refused.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<PaymentResponse>?> listMyPayments(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listMyPaymentsWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PaymentResponse>') as List)
        .cast<PaymentResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Record money I received
  ///
  /// Confirmed immediately: the landlord received it, so there is nobody for them to disagree with. The month's balance moves at once and the tenant is told.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [RecordPaymentRequest] recordPaymentRequest (required):
  Future<Response> recordPaymentWithHttpInfo(String leaseId, RecordPaymentRequest recordPaymentRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/payments'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody = recordPaymentRequest;

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

  /// Record money I received
  ///
  /// Confirmed immediately: the landlord received it, so there is nobody for them to disagree with. The month's balance moves at once and the tenant is told.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [RecordPaymentRequest] recordPaymentRequest (required):
  Future<PaymentResponse?> recordPayment(String leaseId, RecordPaymentRequest recordPaymentRequest, { Future<void>? abortTrigger, }) async {
    final response = await recordPaymentWithHttpInfo(leaseId, recordPaymentRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentResponse',) as PaymentResponse;
    
    }
    return null;
  }

  /// Say it did not arrive
  ///
  /// Rejected rather than deleted: a tenant who wrote something down and found it gone would not know whether it was refused or lost. Nothing is credited.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] paymentId (required):
  ///
  /// * [String] remarks:
  Future<Response> rejectPaymentWithHttpInfo(String leaseId, String paymentId, { String? remarks, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/payments/{paymentId}/reject'
      .replaceAll('{leaseId}', leaseId)
      .replaceAll('{paymentId}', paymentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (remarks != null) {
      queryParams.addAll(_queryParams('', 'remarks', remarks));
    }

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

  /// Say it did not arrive
  ///
  /// Rejected rather than deleted: a tenant who wrote something down and found it gone would not know whether it was refused or lost. Nothing is credited.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] paymentId (required):
  ///
  /// * [String] remarks:
  Future<PaymentResponse?> rejectPayment(String leaseId, String paymentId, { String? remarks, Future<void>? abortTrigger, }) async {
    final response = await rejectPaymentWithHttpInfo(leaseId, paymentId, remarks: remarks, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentResponse',) as PaymentResponse;
    
    }
    return null;
  }
}
