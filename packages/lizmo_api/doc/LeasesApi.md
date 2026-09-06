# lizmo_api.api.LeasesApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteLeaseDocument**](LeasesApi.md#deleteleasedocument) | **DELETE** /api/v1/leases/{leaseId}/documents/{documentId} | Remove a document
[**endLease**](LeasesApi.md#endlease) | **POST** /api/v1/leases/{id}/end | End a tenancy
[**getTenantForLease**](LeasesApi.md#gettenantforlease) | **GET** /api/v1/leases/{leaseId}/tenant | Who is living here
[**listLeaseDocuments**](LeasesApi.md#listleasedocuments) | **GET** /api/v1/leases/{leaseId}/documents | Paperwork on this lease
[**listLeasesForProperty**](LeasesApi.md#listleasesforproperty) | **GET** /api/v1/properties/{propertyId}/leases | Who is living here
[**listMyLeaseDocuments**](LeasesApi.md#listmyleasedocuments) | **GET** /api/v1/me/leases/{leaseId}/documents | Paperwork my landlord has shared with me
[**listMyLeases**](LeasesApi.md#listmyleases) | **GET** /api/v1/me/leases | My leases
[**listMyTenants**](LeasesApi.md#listmytenants) | **GET** /api/v1/me/tenants | Everyone renting from me
[**listTenantDocumentsForLease**](LeasesApi.md#listtenantdocumentsforlease) | **GET** /api/v1/leases/{leaseId}/tenant-documents | The ID of the tenant living here
[**updateLeaseDocument**](LeasesApi.md#updateleasedocument) | **PATCH** /api/v1/leases/{leaseId}/documents/{documentId} | Rename it, or change who can see it
[**uploadLeaseDocument**](LeasesApi.md#uploadleasedocument) | **POST** /api/v1/leases/{leaseId}/documents | Attach a document


# **deleteLeaseDocument**
> deleteLeaseDocument(leaseId, documentId)

Remove a document

Gone for good, file and record together.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final documentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteLeaseDocument(leaseId, documentId);
} catch (e) {
    print('Exception when calling LeasesApi->deleteLeaseDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **documentId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **endLease**
> LeaseResponse endLease(id, endLeaseRequest)

End a tenancy

Frees the bed or unit back to the vacancy list. Defaults to ended today; pass terminated for a tenancy stopped early.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final endLeaseRequest = EndLeaseRequest(); // EndLeaseRequest | 

try {
    final result = api_instance.endLease(id, endLeaseRequest);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->endLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **endLeaseRequest** | [**EndLeaseRequest**](EndLeaseRequest.md)|  | [optional] 

### Return type

[**LeaseResponse**](LeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTenantForLease**
> TenantForLandlord getTenantForLease(leaseId)

Who is living here

The written half of what unlocks on acceptance: the emergency contact and the ID number, both of which a pending request deliberately withholds. Only while the lease is active.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getTenantForLease(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->getTenantForLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**TenantForLandlord**](TenantForLandlord.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLeaseDocuments**
> List<LeaseDocumentResponse> listLeaseDocuments(leaseId)

Paperwork on this lease

Newest first. Each carries a presigned URL valid for a few minutes; do not cache it, ask again instead.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeaseDocuments(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listLeaseDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<LeaseDocumentResponse>**](LeaseDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLeasesForProperty**
> List<LeaseResponse> listLeasesForProperty(propertyId)

Who is living here

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeasesForProperty(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listLeasesForProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**List<LeaseResponse>**](LeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyLeaseDocuments**
> List<LeaseDocumentResponse> listMyLeaseDocuments(leaseId)

Paperwork my landlord has shared with me

The signed contract, and anything else the landlord chose to share. Still readable after the tenancy ends: a copy of what you signed is worth having afterwards.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listMyLeaseDocuments(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listMyLeaseDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<LeaseDocumentResponse>**](LeaseDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyLeases**
> List<LeaseResponse> listMyLeases()

My leases

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();

try {
    final result = api_instance.listMyLeases();
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listMyLeases: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<LeaseResponse>**](LeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyTenants**
> List<LeaseResponse> listMyTenants()

Everyone renting from me

Active leases across every property this landlord owns, so the tenant list is one request rather than one per property.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();

try {
    final result = api_instance.listMyTenants();
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listMyTenants: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<LeaseResponse>**](LeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTenantDocumentsForLease**
> List<TenantDocumentResponse> listTenantDocumentsForLease(leaseId)

The ID of the tenant living here

Only while the lease is active. Each carries a presigned URL valid for a few minutes.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listTenantDocumentsForLease(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->listTenantDocumentsForLease: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<TenantDocumentResponse>**](TenantDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateLeaseDocument**
> LeaseDocumentResponse updateLeaseDocument(leaseId, documentId, label, sharedWithTenant)

Rename it, or change who can see it

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final documentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final label = label_example; // String | 
final sharedWithTenant = true; // bool | 

try {
    final result = api_instance.updateLeaseDocument(leaseId, documentId, label, sharedWithTenant);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->updateLeaseDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **documentId** | **String**|  | 
 **label** | **String**|  | [optional] 
 **sharedWithTenant** | **bool**|  | [optional] 

### Return type

[**LeaseDocumentResponse**](LeaseDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadLeaseDocument**
> LeaseDocumentResponse uploadLeaseDocument(leaseId, file, docType, label, sharedWithTenant)

Attach a document

A photograph is re-encoded on arrival so no EXIF or location survives. A PDF is stored as it arrived — there is no equivalent scrub, and rewriting a signed document would change the artefact somebody may later have to rely on. 20MB each, 20 per lease.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LeasesApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = BINARY_DATA_HERE; // MultipartFile | 
final docType = docType_example; // String | 
final label = label_example; // String | 
final sharedWithTenant = true; // bool | 

try {
    final result = api_instance.uploadLeaseDocument(leaseId, file, docType, label, sharedWithTenant);
    print(result);
} catch (e) {
    print('Exception when calling LeasesApi->uploadLeaseDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **file** | **MultipartFile**|  | 
 **docType** | **String**|  | [optional] [default to 'LEASE_CONTRACT']
 **label** | **String**|  | [optional] 
 **sharedWithTenant** | **bool**|  | [optional] [default to true]

### Return type

[**LeaseDocumentResponse**](LeaseDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

