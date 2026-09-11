# lizmo_api.api.AdminApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmPlatformPayment**](AdminApi.md#confirmplatformpayment) | **POST** /api/v1/admin/platform-payments/{id}/confirm | The money arrived
[**getLandlord**](AdminApi.md#getlandlord) | **GET** /api/v1/admin/landlords/{id} | One landlord and their properties
[**getPlatformSettings**](AdminApi.md#getplatformsettings) | **GET** /api/v1/admin/settings | Settings the console owns
[**getSupportContact**](AdminApi.md#getsupportcontact) | **GET** /api/v1/platform/support | Where to write to Lizmo
[**inviteLandlord**](AdminApi.md#invitelandlord) | **POST** /api/v1/admin/landlord-invitations | Invite a landlord
[**listInvitations**](AdminApi.md#listinvitations) | **GET** /api/v1/admin/landlord-invitations | Invitations not yet taken up
[**listLandlordInvoices**](AdminApi.md#listlandlordinvoices) | **GET** /api/v1/admin/landlords/{id}/invoices | One landlord's invoices
[**listLandlords**](AdminApi.md#listlandlords) | **GET** /api/v1/admin/landlords | Every landlord
[**listPlatformPaymentsToReview**](AdminApi.md#listplatformpaymentstoreview) | **GET** /api/v1/admin/platform-payments | Payments waiting to be checked
[**lockProperty**](AdminApi.md#lockproperty) | **POST** /api/v1/admin/properties/{id}/lock | Stop a property being added to
[**rejectPlatformPayment**](AdminApi.md#rejectplatformpayment) | **POST** /api/v1/admin/platform-payments/{id}/reject | It did not arrive
[**revokeInvitation**](AdminApi.md#revokeinvitation) | **DELETE** /api/v1/admin/landlord-invitations/{id} | Withdraw an invitation
[**unlockProperty**](AdminApi.md#unlockproperty) | **POST** /api/v1/admin/properties/{id}/unlock | Let a property be managed again
[**updatePlatformSettings**](AdminApi.md#updateplatformsettings) | **PUT** /api/v1/admin/settings | Change them


# **confirmPlatformPayment**
> PlatformPaymentForAdmin confirmPlatformPayment(id)

The money arrived

Credits the invoice. Paying it in full lifts the lock it caused.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.confirmPlatformPayment(id);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->confirmPlatformPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PlatformPaymentForAdmin**](PlatformPaymentForAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLandlord**
> LandlordDetail getLandlord(id)

One landlord and their properties

Each property carries its own status, because each carries its own invoice.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getLandlord(id);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->getLandlord: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**LandlordDetail**](LandlordDetail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPlatformSettings**
> PlatformSettings getPlatformSettings()

Settings the console owns

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();

try {
    final result = api_instance.getPlatformSettings();
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->getPlatformSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlatformSettings**](PlatformSettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSupportContact**
> SupportContact getSupportContact()

Where to write to Lizmo

Public: the account deletion page shows it, and that page must work for somebody who has already uninstalled the app.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();

try {
    final result = api_instance.getSupportContact();
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->getSupportContact: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SupportContact**](SupportContact.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **listInvitations**
> List<PendingInvitation> listInvitations()

Invitations not yet taken up

Expired ones included: somebody has to notice that a landlord never signed up. Never includes the token.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();

try {
    final result = api_instance.listInvitations();
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->listInvitations: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PendingInvitation>**](PendingInvitation.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLandlordInvoices**
> List<PlatformInvoiceResponse> listLandlordInvoices(id)

One landlord's invoices

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLandlordInvoices(id);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->listLandlordInvoices: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**List<PlatformInvoiceResponse>**](PlatformInvoiceResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLandlords**
> List<LandlordSummary> listLandlords()

Every landlord

With their property count, how many are locked, and how many slots are occupied. Counts only — no tenant is named.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();

try {
    final result = api_instance.listLandlords();
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->listLandlords: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<LandlordSummary>**](LandlordSummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPlatformPaymentsToReview**
> List<PlatformPaymentForAdmin> listPlatformPaymentsToReview()

Payments waiting to be checked

Across every landlord, oldest first.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();

try {
    final result = api_instance.listPlatformPaymentsToReview();
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->listPlatformPaymentsToReview: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PlatformPaymentForAdmin>**](PlatformPaymentForAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **lockProperty**
> AdminPropertySummary lockProperty(id)

Stop a property being added to

Blocks new units, new beds and accepting requests. Never affects the tenants already living there, and never stops the landlord ending a lease or declining a request.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.lockProperty(id);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->lockProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AdminPropertySummary**](AdminPropertySummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectPlatformPayment**
> PlatformPaymentForAdmin rejectPlatformPayment(id, platformPaymentRejection)

It did not arrive

The landlord is told, with the reason.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final platformPaymentRejection = PlatformPaymentRejection(); // PlatformPaymentRejection | 

try {
    final result = api_instance.rejectPlatformPayment(id, platformPaymentRejection);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->rejectPlatformPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **platformPaymentRejection** | [**PlatformPaymentRejection**](PlatformPaymentRejection.md)|  | [optional] 

### Return type

[**PlatformPaymentForAdmin**](PlatformPaymentForAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeInvitation**
> revokeInvitation(id)

Withdraw an invitation

For a wrong address, or somebody who should not have been invited. The link stops working immediately.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.revokeInvitation(id);
} catch (e) {
    print('Exception when calling AdminApi->revokeInvitation: $e\n');
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

# **unlockProperty**
> AdminPropertySummary unlockProperty(id)

Let a property be managed again

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.unlockProperty(id);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->unlockProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AdminPropertySummary**](AdminPropertySummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePlatformSettings**
> PlatformSettings updatePlatformSettings(platformSettings)

Change them

The support address appears on a public page and is what a stranger is told to write to, so it is validated and who changed it is recorded.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AdminApi();
final platformSettings = PlatformSettings(); // PlatformSettings | 

try {
    final result = api_instance.updatePlatformSettings(platformSettings);
    print(result);
} catch (e) {
    print('Exception when calling AdminApi->updatePlatformSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **platformSettings** | [**PlatformSettings**](PlatformSettings.md)|  | 

### Return type

[**PlatformSettings**](PlatformSettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

