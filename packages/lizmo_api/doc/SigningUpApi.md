# lizmo_api.api.SigningUpApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeRegistration**](SigningUpApi.md#completeregistration) | **POST** /api/v1/auth/register/complete | Finish signing up
[**startRegistration**](SigningUpApi.md#startregistration) | **POST** /api/v1/auth/register/start | Send me a code


# **completeRegistration**
> AuthResponse completeRegistration(completeRegistrationRequest)

Finish signing up

Spends the code and creates the account. The password needs at least eight characters, with a capital, a small letter, a number and a symbol.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = SigningUpApi();
final completeRegistrationRequest = CompleteRegistrationRequest(); // CompleteRegistrationRequest | 

try {
    final result = api_instance.completeRegistration(completeRegistrationRequest);
    print(result);
} catch (e) {
    print('Exception when calling SigningUpApi->completeRegistration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **completeRegistrationRequest** | [**CompleteRegistrationRequest**](CompleteRegistrationRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startRegistration**
> StartRegistrationResponse startRegistration(startRegistrationRequest)

Send me a code

Emails a six-digit code, good for ten minutes and one use. Asking again replaces any code already sent to that address.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = SigningUpApi();
final startRegistrationRequest = StartRegistrationRequest(); // StartRegistrationRequest | 

try {
    final result = api_instance.startRegistration(startRegistrationRequest);
    print(result);
} catch (e) {
    print('Exception when calling SigningUpApi->startRegistration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startRegistrationRequest** | [**StartRegistrationRequest**](StartRegistrationRequest.md)|  | 

### Return type

[**StartRegistrationResponse**](StartRegistrationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

