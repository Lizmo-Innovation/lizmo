# lizmo_api.api.AuthApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**login**](AuthApi.md#login) | **POST** /api/v1/auth/login | Sign in with email or phone plus password
[**logout**](AuthApi.md#logout) | **POST** /api/v1/auth/logout | Revoke a refresh token
[**refresh**](AuthApi.md#refresh) | **POST** /api/v1/auth/refresh | Exchange a refresh token for a new pair
[**register**](AuthApi.md#register) | **POST** /api/v1/auth/register | Create an account


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

# **register**
> AuthResponse register(registerRequest)

Create an account

Always creates a tenant profile; adds a landlord profile when asLandlord is true.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AuthApi();
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.register(registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->register: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

