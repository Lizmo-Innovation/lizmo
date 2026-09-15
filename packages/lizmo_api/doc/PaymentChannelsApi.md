# lizmo_api.api.PaymentChannelsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addMyPaymentChannel**](PaymentChannelsApi.md#addmypaymentchannel) | **POST** /api/v1/me/payment-channels | Add a way to pay me
[**deleteMyPaymentChannel**](PaymentChannelsApi.md#deletemypaymentchannel) | **DELETE** /api/v1/me/payment-channels/{id} | Delete a way to pay me
[**getMyPaymentNote**](PaymentChannelsApi.md#getmypaymentnote) | **GET** /api/v1/me/payment-note | The note under my channels
[**listMyPaymentChannels**](PaymentChannelsApi.md#listmypaymentchannels) | **GET** /api/v1/me/payment-channels | How my tenants pay me
[**removeMyPaymentChannelQr**](PaymentChannelsApi.md#removemypaymentchannelqr) | **DELETE** /api/v1/me/payment-channels/{id}/qr | Remove a channel's QR
[**reorderMyPaymentChannels**](PaymentChannelsApi.md#reordermypaymentchannels) | **PUT** /api/v1/me/payment-channels/order | Put my channels in order
[**updateMyPaymentChannel**](PaymentChannelsApi.md#updatemypaymentchannel) | **PUT** /api/v1/me/payment-channels/{id} | Change a way to pay me
[**updateMyPaymentNote**](PaymentChannelsApi.md#updatemypaymentnote) | **PUT** /api/v1/me/payment-note | Change the note under my channels
[**uploadMyPaymentChannelQr**](PaymentChannelsApi.md#uploadmypaymentchannelqr) | **POST** /api/v1/me/payment-channels/{id}/qr | Set a channel's QR


# **addMyPaymentChannel**
> PaymentChannelResponse addMyPaymentChannel(paymentChannelRequest)

Add a way to pay me

Added at the bottom, and shown to tenants unless visible is false.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final paymentChannelRequest = PaymentChannelRequest(); // PaymentChannelRequest | 

try {
    final result = api_instance.addMyPaymentChannel(paymentChannelRequest);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->addMyPaymentChannel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentChannelRequest** | [**PaymentChannelRequest**](PaymentChannelRequest.md)|  | 

### Return type

[**PaymentChannelResponse**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMyPaymentChannel**
> deleteMyPaymentChannel(id)

Delete a way to pay me

With its QR. Hide it instead to bring it back later.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteMyPaymentChannel(id);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->deleteMyPaymentChannel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyPaymentNote**
> PaymentNote getMyPaymentNote()

The note under my channels

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();

try {
    final result = api_instance.getMyPaymentNote();
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->getMyPaymentNote: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentNote**](PaymentNote.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyPaymentChannels**
> List<PaymentChannelResponse> listMyPaymentChannels()

How my tenants pay me

Hidden ones included, in the order tenants see them.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();

try {
    final result = api_instance.listMyPaymentChannels();
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->listMyPaymentChannels: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PaymentChannelResponse>**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeMyPaymentChannelQr**
> PaymentChannelResponse removeMyPaymentChannelQr(id)

Remove a channel's QR

The channel stays, with its name and number.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.removeMyPaymentChannelQr(id);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->removeMyPaymentChannelQr: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PaymentChannelResponse**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reorderMyPaymentChannels**
> List<PaymentChannelResponse> reorderMyPaymentChannels(paymentChannelOrder)

Put my channels in order

Every channel exactly once, top to bottom.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final paymentChannelOrder = PaymentChannelOrder(); // PaymentChannelOrder | 

try {
    final result = api_instance.reorderMyPaymentChannels(paymentChannelOrder);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->reorderMyPaymentChannels: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentChannelOrder** | [**PaymentChannelOrder**](PaymentChannelOrder.md)|  | 

### Return type

[**List<PaymentChannelResponse>**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMyPaymentChannel**
> PaymentChannelResponse updateMyPaymentChannel(id, paymentChannelRequest)

Change a way to pay me

Visibility is left as it is when not sent. Past payments keep the details they were sent to.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final paymentChannelRequest = PaymentChannelRequest(); // PaymentChannelRequest | 

try {
    final result = api_instance.updateMyPaymentChannel(id, paymentChannelRequest);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->updateMyPaymentChannel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **paymentChannelRequest** | [**PaymentChannelRequest**](PaymentChannelRequest.md)|  | 

### Return type

[**PaymentChannelResponse**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMyPaymentNote**
> PaymentNote updateMyPaymentNote(paymentNote)

Change the note under my channels

Blank clears it.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final paymentNote = PaymentNote(); // PaymentNote | 

try {
    final result = api_instance.updateMyPaymentNote(paymentNote);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->updateMyPaymentNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentNote** | [**PaymentNote**](PaymentNote.md)|  | 

### Return type

[**PaymentNote**](PaymentNote.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadMyPaymentChannelQr**
> PaymentChannelResponse uploadMyPaymentChannelQr(id, qr)

Set a channel's QR

Replaces any QR it had. Re-encoded, so no EXIF or location is kept.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PaymentChannelsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final qr = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadMyPaymentChannelQr(id, qr);
    print(result);
} catch (e) {
    print('Exception when calling PaymentChannelsApi->uploadMyPaymentChannelQr: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **qr** | **MultipartFile**|  | 

### Return type

[**PaymentChannelResponse**](PaymentChannelResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

