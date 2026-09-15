# lizmo_api.api.LizmoBillingApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPlatformPaymentDetails**](LizmoBillingApi.md#getplatformpaymentdetails) | **GET** /api/v1/me/platform-payment-details | How to pay Lizmo
[**listMyPlatformStatements**](LizmoBillingApi.md#listmyplatformstatements) | **GET** /api/v1/me/platform-statements | My Lizmo statements
[**payPlatformStatement**](LizmoBillingApi.md#payplatformstatement) | **POST** /api/v1/me/platform-statements/{id}/payments | Say I have paid Lizmo


# **getPlatformPaymentDetails**
> PaymentDetails getPlatformPaymentDetails()

How to pay Lizmo

The channels an admin has made visible, in order, each with its QR when it has one, and the note shown under them. Landlords only.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LizmoBillingApi();

try {
    final result = api_instance.getPlatformPaymentDetails();
    print(result);
} catch (e) {
    print('Exception when calling LizmoBillingApi->getPlatformPaymentDetails: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentDetails**](PaymentDetails.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyPlatformStatements**
> List<PlatformStatementResponse> listMyPlatformStatements()

My Lizmo statements

One a month, newest first, itemised by property, with what has been sent against each. A line carries an invoice number once the statement is paid.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LizmoBillingApi();

try {
    final result = api_instance.listMyPlatformStatements();
    print(result);
} catch (e) {
    print('Exception when calling LizmoBillingApi->listMyPlatformStatements: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PlatformStatementResponse>**](PlatformStatementResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **payPlatformStatement**
> PlatformStatementResponse payPlatformStatement(id, amountPaid, paymentDate, paymentMethod, remarks, proof)

Say I have paid Lizmo

Waits for a Lizmo admin to confirm it. Proof is required. The photograph is re-encoded, so no EXIF or location leaves the phone.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LizmoBillingApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final amountPaid = amountPaid_example; // String | 
final paymentDate = paymentDate_example; // String | When the money moved, as YYYY-MM-DD. Defaults to today.
final paymentMethod = paymentMethod_example; // String | 
final remarks = remarks_example; // String | 
final proof = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.payPlatformStatement(id, amountPaid, paymentDate, paymentMethod, remarks, proof);
    print(result);
} catch (e) {
    print('Exception when calling LizmoBillingApi->payPlatformStatement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **amountPaid** | **String**|  | 
 **paymentDate** | **String**| When the money moved, as YYYY-MM-DD. Defaults to today. | [optional] 
 **paymentMethod** | **String**|  | [optional] 
 **remarks** | **String**|  | [optional] 
 **proof** | **MultipartFile**|  | [optional] 

### Return type

[**PlatformStatementResponse**](PlatformStatementResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

