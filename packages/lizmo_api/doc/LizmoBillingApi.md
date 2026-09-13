# lizmo_api.api.LizmoBillingApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPlatformPaymentInstructions**](LizmoBillingApi.md#getplatformpaymentinstructions) | **GET** /api/v1/me/platform-payment-instructions | How to pay Lizmo
[**listMyPlatformStatements**](LizmoBillingApi.md#listmyplatformstatements) | **GET** /api/v1/me/platform-statements | My Lizmo statements
[**payPlatformStatement**](LizmoBillingApi.md#payplatformstatement) | **POST** /api/v1/me/platform-statements/{id}/payments | Say I have paid Lizmo


# **getPlatformPaymentInstructions**
> PaymentInstructions getPlatformPaymentInstructions()

How to pay Lizmo

As an admin wrote it in the console. Empty until one has.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LizmoBillingApi();

try {
    final result = api_instance.getPlatformPaymentInstructions();
    print(result);
} catch (e) {
    print('Exception when calling LizmoBillingApi->getPlatformPaymentInstructions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentInstructions**](PaymentInstructions.md)

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
> PlatformStatementResponse payPlatformStatement(id, payment, proof)

Say I have paid Lizmo

Waits for a Lizmo admin to confirm it. Proof is required. The photograph is re-encoded, so no EXIF or location leaves the phone.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = LizmoBillingApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final payment = ; // PlatformPaymentRequest | 
final proof = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.payPlatformStatement(id, payment, proof);
    print(result);
} catch (e) {
    print('Exception when calling LizmoBillingApi->payPlatformStatement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **payment** | [**PlatformPaymentRequest**](PlatformPaymentRequest.md)|  | 
 **proof** | **MultipartFile**|  | [optional] 

### Return type

[**PlatformStatementResponse**](PlatformStatementResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

