# lizmo_api.api.AuthApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completePasswordReset**](AuthApi.md#completepasswordreset) | **POST** /api/v1/auth/password-reset/complete | Set a new password
[**login**](AuthApi.md#login) | **POST** /api/v1/auth/login | Sign in with email or phone plus password
[**logout**](AuthApi.md#logout) | **POST** /api/v1/auth/logout | Revoke a refresh token
[**refresh**](AuthApi.md#refresh) | **POST** /api/v1/auth/refresh | Exchange a refresh token for a new pair
[**startPasswordReset**](AuthApi.md#startpasswordreset) | **POST** /api/v1/auth/password-reset | Send me a reset code


# **completePasswordReset**
> AuthResponse completePasswordReset(completePasswordResetRequest)

Set a new password

Spends the code, sets the password, and ends every session the account had -- including whoever's knowledge of the old password prompted the reset. Signs the caller back in.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final completePasswordResetRequest = CompletePasswordResetRequest(); // CompletePasswordResetRequest | 

try {
    final result = api_instance.completePasswordReset(completePasswordResetRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->completePasswordReset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **completePasswordResetRequest** | [**CompletePasswordResetRequest**](CompletePasswordResetRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> AuthResponse login(loginRequest)

Sign in with email or phone plus password

Failed attempts are rate limited per account and per client address.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final loginRequest = LoginRequest(); // LoginRequest | 

try {
    final result = api_instance.login(loginRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout(refreshRequest)

Revoke a refresh token

Idempotent: unknown or already-revoked tokens still return 204.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final refreshRequest = RefreshRequest(); // RefreshRequest | 

try {
    api_instance.logout(refreshRequest);
} catch (e) {
    print('Exception when calling AuthApi->logout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refresh**
> AuthResponse refresh(refreshRequest)

Exchange a refresh token for a new pair

The presented refresh token is revoked, so each one is usable exactly once.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final refreshRequest = RefreshRequest(); // RefreshRequest | 

try {
    final result = api_instance.refresh(refreshRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->refresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startPasswordReset**
> StartPasswordResetResponse startPasswordReset(startPasswordResetRequest)

Send me a reset code

Emails a six-digit code, good for fifteen minutes and one use. The response is the same whether or not the address has an account: saying otherwise would make this a way to ask Lizmo who its users are.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final startPasswordResetRequest = StartPasswordResetRequest(); // StartPasswordResetRequest | 

try {
    final result = api_instance.startPasswordReset(startPasswordResetRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->startPasswordReset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startPasswordResetRequest** | [**StartPasswordResetRequest**](StartPasswordResetRequest.md)|  | 

### Return type

[**StartPasswordResetResponse**](StartPasswordResetResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

