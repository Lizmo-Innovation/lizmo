# lizmo_api.api.DevicesApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forgetDevice**](DevicesApi.md#forgetdevice) | **DELETE** /api/v1/me/devices | Stop pushing to this phone
[**registerDevice**](DevicesApi.md#registerdevice) | **PUT** /api/v1/me/devices | Push to this phone


# **forgetDevice**
> forgetDevice(token)

Stop pushing to this phone

On signing out, so a shared phone stops being told the last person's business. Only ever the caller's own.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = DevicesApi();
final token = token_example; // String | 

try {
    api_instance.forgetDevice(token);
} catch (e) {
    print('Exception when calling DevicesApi->forgetDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerDevice**
> registerDevice(registerDevice)

Push to this phone

After signing in, and whenever the phone's token changes. The same token twice is one phone; a token another account held moves here.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = DevicesApi();
final registerDevice = RegisterDevice(); // RegisterDevice | 

try {
    api_instance.registerDevice(registerDevice);
} catch (e) {
    print('Exception when calling DevicesApi->registerDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDevice** | [**RegisterDevice**](RegisterDevice.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

