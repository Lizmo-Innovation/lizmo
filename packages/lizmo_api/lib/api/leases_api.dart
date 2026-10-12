//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LeasesApi {
  LeasesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Set when a lease ends
  ///
  /// Sets, moves or takes away the last day of a lease. A later date extends it. Both of them are warned as the date nears; passing it ends nothing. The tenant is told of the change.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [LeaseTermRequest] leaseTermRequest (required):
  Future<Response> changeLeaseTermWithHttpInfo(String id, LeaseTermRequest leaseTermRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{id}/term'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = leaseTermRequest;

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

  /// Set when a lease ends
  ///
  /// Sets, moves or takes away the last day of a lease. A later date extends it. Both of them are warned as the date nears; passing it ends nothing. The tenant is told of the change.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [LeaseTermRequest] leaseTermRequest (required):
  Future<LeaseResponse?> changeLeaseTerm(String id, LeaseTermRequest leaseTermRequest, { Future<void>? abortTrigger, }) async {
    final response = await changeLeaseTermWithHttpInfo(id, leaseTermRequest, abortTrigger: abortTrigger,);
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

  /// Remove a document
  ///
  /// Gone for good, file and record together.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] documentId (required):
  Future<Response> deleteLeaseDocumentWithHttpInfo(String leaseId, String documentId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/documents/{documentId}'
      .replaceAll('{leaseId}', leaseId)
      .replaceAll('{documentId}', documentId);

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

  /// Remove a document
  ///
  /// Gone for good, file and record together.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] documentId (required):
  Future<void> deleteLeaseDocument(String leaseId, String documentId, { Future<void>? abortTrigger, }) async {
    final response = await deleteLeaseDocumentWithHttpInfo(leaseId, documentId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// End a tenancy
  ///
  /// Frees the bed or unit back to the vacancy list. Defaults to ended today; pass terminated for a tenancy stopped early.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [EndLeaseRequest] endLeaseRequest:
  Future<Response> endLeaseWithHttpInfo(String id, { EndLeaseRequest? endLeaseRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{id}/end'
      .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = endLeaseRequest;

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

  /// End a tenancy
  ///
  /// Frees the bed or unit back to the vacancy list. Defaults to ended today; pass terminated for a tenancy stopped early.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [EndLeaseRequest] endLeaseRequest:
  Future<LeaseResponse?> endLease(String id, { EndLeaseRequest? endLeaseRequest, Future<void>? abortTrigger, }) async {
    final response = await endLeaseWithHttpInfo(id, endLeaseRequest: endLeaseRequest, abortTrigger: abortTrigger,);
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

  /// Who is living here
  ///
  /// The written half of what unlocks on acceptance: the emergency contact and the ID number, both of which a pending request deliberately withholds. Only while the lease is active.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> getTenantForLeaseWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/tenant'
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

  /// Who is living here
  ///
  /// The written half of what unlocks on acceptance: the emergency contact and the ID number, both of which a pending request deliberately withholds. Only while the lease is active.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<TenantForLandlord?> getTenantForLease(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await getTenantForLeaseWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TenantForLandlord',) as TenantForLandlord;
    
    }
    return null;
  }

  /// Paperwork on this lease
  ///
  /// Newest first. Each carries a presigned URL valid for a few minutes; do not cache it, ask again instead.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listLeaseDocumentsWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/documents'
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

  /// Paperwork on this lease
  ///
  /// Newest first. Each carries a presigned URL valid for a few minutes; do not cache it, ask again instead.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<LeaseDocumentResponse>?> listLeaseDocuments(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listLeaseDocumentsWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseDocumentResponse>') as List)
        .cast<LeaseDocumentResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Who is living here
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> listLeasesForPropertyWithHttpInfo(String propertyId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/properties/{propertyId}/leases'
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

  /// Who is living here
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<List<LeaseResponse>?> listLeasesForProperty(String propertyId, { Future<void>? abortTrigger, }) async {
    final response = await listLeasesForPropertyWithHttpInfo(propertyId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseResponse>') as List)
        .cast<LeaseResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Paperwork my landlord has shared with me
  ///
  /// The signed contract, and anything else the landlord chose to share. Still readable after the tenancy ends: a copy of what you signed is worth having afterwards.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listMyLeaseDocumentsWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases/{leaseId}/documents'
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

  /// Paperwork my landlord has shared with me
  ///
  /// The signed contract, and anything else the landlord chose to share. Still readable after the tenancy ends: a copy of what you signed is worth having afterwards.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<LeaseDocumentResponse>?> listMyLeaseDocuments(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listMyLeaseDocumentsWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseDocumentResponse>') as List)
        .cast<LeaseDocumentResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// My leases
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyLeasesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/leases';

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

  /// My leases
  Future<List<LeaseResponse>?> listMyLeases({ Future<void>? abortTrigger, }) async {
    final response = await listMyLeasesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseResponse>') as List)
        .cast<LeaseResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Everyone renting from me
  ///
  /// Active leases across every property this landlord owns, so the tenant list is one request rather than one per property.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMyTenantsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/tenants';

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

  /// Everyone renting from me
  ///
  /// Active leases across every property this landlord owns, so the tenant list is one request rather than one per property.
  Future<List<LeaseResponse>?> listMyTenants({ Future<void>? abortTrigger, }) async {
    final response = await listMyTenantsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LeaseResponse>') as List)
        .cast<LeaseResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// The ID of the tenant living here
  ///
  /// Only while the lease is active. Each carries a presigned URL valid for a few minutes.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<Response> listTenantDocumentsForLeaseWithHttpInfo(String leaseId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/tenant-documents'
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

  /// The ID of the tenant living here
  ///
  /// Only while the lease is active. Each carries a presigned URL valid for a few minutes.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  Future<List<TenantDocumentResponse>?> listTenantDocumentsForLease(String leaseId, { Future<void>? abortTrigger, }) async {
    final response = await listTenantDocumentsForLeaseWithHttpInfo(leaseId, abortTrigger: abortTrigger,);
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

  /// Rename it, or change who can see it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] documentId (required):
  ///
  /// * [String] label:
  ///
  /// * [bool] sharedWithTenant:
  Future<Response> updateLeaseDocumentWithHttpInfo(String leaseId, String documentId, { String? label, bool? sharedWithTenant, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/documents/{documentId}'
      .replaceAll('{leaseId}', leaseId)
      .replaceAll('{documentId}', documentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (label != null) {
      queryParams.addAll(_queryParams('', 'label', label));
    }
    if (sharedWithTenant != null) {
      queryParams.addAll(_queryParams('', 'sharedWithTenant', sharedWithTenant));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Rename it, or change who can see it
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [String] documentId (required):
  ///
  /// * [String] label:
  ///
  /// * [bool] sharedWithTenant:
  Future<LeaseDocumentResponse?> updateLeaseDocument(String leaseId, String documentId, { String? label, bool? sharedWithTenant, Future<void>? abortTrigger, }) async {
    final response = await updateLeaseDocumentWithHttpInfo(leaseId, documentId, label: label, sharedWithTenant: sharedWithTenant, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDocumentResponse',) as LeaseDocumentResponse;
    
    }
    return null;
  }

  /// Attach a document
  ///
  /// A photograph is re-encoded on arrival so no EXIF or location survives. A PDF is stored as it arrived — there is no equivalent scrub, and rewriting a signed document would change the artefact somebody may later have to rely on. 20MB each, 20 per lease.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [MultipartFile] file (required):
  ///
  /// * [String] docType:
  ///
  /// * [String] label:
  ///
  /// * [bool] sharedWithTenant:
  Future<Response> uploadLeaseDocumentWithHttpInfo(String leaseId, MultipartFile file, { String? docType, String? label, bool? sharedWithTenant, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/leases/{leaseId}/documents'
      .replaceAll('{leaseId}', leaseId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (docType != null) {
      queryParams.addAll(_queryParams('', 'docType', docType));
    }
    if (label != null) {
      queryParams.addAll(_queryParams('', 'label', label));
    }
    if (sharedWithTenant != null) {
      queryParams.addAll(_queryParams('', 'sharedWithTenant', sharedWithTenant));
    }

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

  /// Attach a document
  ///
  /// A photograph is re-encoded on arrival so no EXIF or location survives. A PDF is stored as it arrived — there is no equivalent scrub, and rewriting a signed document would change the artefact somebody may later have to rely on. 20MB each, 20 per lease.
  ///
  /// Parameters:
  ///
  /// * [String] leaseId (required):
  ///
  /// * [MultipartFile] file (required):
  ///
  /// * [String] docType:
  ///
  /// * [String] label:
  ///
  /// * [bool] sharedWithTenant:
  Future<LeaseDocumentResponse?> uploadLeaseDocument(String leaseId, MultipartFile file, { String? docType, String? label, bool? sharedWithTenant, Future<void>? abortTrigger, }) async {
    final response = await uploadLeaseDocumentWithHttpInfo(leaseId, file, docType: docType, label: label, sharedWithTenant: sharedWithTenant, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaseDocumentResponse',) as LeaseDocumentResponse;
    
    }
    return null;
  }
}
