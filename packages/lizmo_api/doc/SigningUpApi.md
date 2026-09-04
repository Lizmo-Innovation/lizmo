# lizmo_api.api.SigningUpApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptInvitation**](SigningUpApi.md#acceptinvitation) | **POST** /api/v1/auth/invitations/accept | Become a landlord
[**completeRegistration**](SigningUpApi.md#completeregistration) | **POST** /api/v1/auth/register/complete | Finish signing up
[**getInvitation**](SigningUpApi.md#getinvitation) | **GET** /api/v1/auth/invitations/{token} | What this invitation is for
[**startRegistration**](SigningUpApi.md#startregistration) | **POST** /api/v1/auth/register/start | Send me a code


# **acceptInvitation**
> AuthResponse acceptInvitation(acceptInvitationRequest)

Become a landlord

Spends the invitation and signs you in. A new account needs a name and a password of its own; an address that already signs in to Lizmo needs that account's password, and keeps its tenant side.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = SigningUpApi();
final acceptInvitationRequest = AcceptInvitationRequest(); // AcceptInvitationRequest | 

try {
    final result = api_instance.acceptInvitation(acceptInvitationRequest);
    print(result);
} catch (e) {
    print('Exception when calling SigningUpApi->acceptInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **acceptInvitationRequest** | [**AcceptInvitationRequest**](AcceptInvitationRequest.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **getInvitation**
> InvitationDetailsResponse getInvitation(token)

What this invitation is for

Says which address was invited and whether it already has a Lizmo account, so the screen knows whether to ask for a new password or the existing one.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = SigningUpApi();
final token = token_example; // String | 

try {
    final result = api_instance.getInvitation(token);
    print(result);
} catch (e) {
    print('Exception when calling SigningUpApi->getInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**InvitationDetailsResponse**](InvitationDetailsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
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

