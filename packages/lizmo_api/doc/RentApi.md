# lizmo_api.api.RentApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listLeaseBilling**](RentApi.md#listleasebilling) | **GET** /api/v1/leases/{leaseId}/billing | Rent on this tenancy
[**listMyBilling**](RentApi.md#listmybilling) | **GET** /api/v1/me/leases/{leaseId}/billing | My rent


# **listLeaseBilling**
> List<BillingPeriodResponse> listLeaseBilling(leaseId)

Rent on this tenancy

Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeaseBilling(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listLeaseBilling: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<BillingPeriodResponse>**](BillingPeriodResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyBilling**
> List<BillingPeriodResponse> listMyBilling(leaseId)

My rent

The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listMyBilling(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listMyBilling: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<BillingPeriodResponse>**](BillingPeriodResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

