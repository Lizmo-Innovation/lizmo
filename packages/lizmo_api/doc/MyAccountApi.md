# lizmo_api.api.MyAccountApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**checkAccountDeletable**](MyAccountApi.md#checkaccountdeletable) | **GET** /api/v1/me/deletable | Whether this account can be closed
[**deleteMyAccount**](MyAccountApi.md#deletemyaccount) | **DELETE** /api/v1/me | Close my account


# **checkAccountDeletable**
> checkAccountDeletable()

Whether this account can be closed

204 when it can. Asked before the confirmation screen, so somebody is told why not while they can still act on it rather than after they have typed DELETE.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MyAccountApi();

try {
    api_instance.checkAccountDeletable();
} catch (e) {
    print('Exception when calling MyAccountApi->checkAccountDeletable: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMyAccount**
> deleteMyAccount()

Close my account

Ends every session, deletes the photographs of your ID, and removes your name, phone number and profile details. Leases and the history of what was paid stay, attached to an id that no longer names anybody, because they are your landlord's records as much as yours.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MyAccountApi();

try {
    api_instance.deleteMyAccount();
} catch (e) {
    print('Exception when calling MyAccountApi->deleteMyAccount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

