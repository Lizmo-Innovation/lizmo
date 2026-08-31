# lizmo_api.api.LeasesApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**endLease**](LeasesApi.md#endlease) | **POST** /api/v1/leases/{id}/end | End a tenancy
[**listLeasesForProperty**](LeasesApi.md#listleasesforproperty) | **GET** /api/v1/properties/{propertyId}/leases | Who is living here
[**listMyLeases**](LeasesApi.md#listmyleases) | **GET** /api/v1/me/leases | My leases
[**listTenantDocumentsForLease**](LeasesApi.md#listtenantdocumentsforlease) | **GET** /api/v1/leases/{leaseId}/tenant-documents | The ID of the tenant living here


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

