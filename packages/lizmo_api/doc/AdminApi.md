# lizmo_api.api.AdminApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**inviteLandlord**](AdminApi.md#invitelandlord) | **POST** /api/v1/admin/landlord-invitations | Invite a landlord


# **inviteLandlord**
> InvitationSentResponse inviteLandlord(inviteLandlordRequest)

Invite a landlord

Emails a link that lets somebody set up a landlord account. Good for seven days and one use; inviting the same address again replaces the earlier link.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final inviteLandlordRequest = InviteLandlordRequest(); // InviteLandlordRequest | 

try {
    final result = api_instance.inviteLandlord(inviteLandlordRequest);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->inviteLandlord: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **inviteLandlordRequest** | [**InviteLandlordRequest**](InviteLandlordRequest.md)|  | 

### Return type

[**InvitationSentResponse**](InvitationSentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

