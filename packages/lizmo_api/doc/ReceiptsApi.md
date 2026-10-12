# lizmo_api.api.ReceiptsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listLeaseReceipts**](ReceiptsApi.md#listleasereceipts) | **GET** /api/v1/leases/{leaseId}/receipts | Receipts on this tenancy
[**listMyReceipts**](ReceiptsApi.md#listmyreceipts) | **GET** /api/v1/me/leases/{leaseId}/receipts | My receipts


# **listLeaseReceipts**
> List<ReceiptResponse> listLeaseReceipts(leaseId)

Receipts on this tenancy

Everything acknowledged on it, newest first.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = ReceiptsApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeaseReceipts(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling ReceiptsApi->listLeaseReceipts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<ReceiptResponse>**](ReceiptResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyReceipts**
> List<ReceiptResponse> listMyReceipts(leaseId)

My receipts

One for every payment the landlord confirmed or recorded, newest first. Not BIR official receipts.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = ReceiptsApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listMyReceipts(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling ReceiptsApi->listMyReceipts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<ReceiptResponse>**](ReceiptResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

