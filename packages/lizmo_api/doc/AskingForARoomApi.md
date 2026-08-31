# lizmo_api.api.AskingForARoomApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listMyRentalRequests**](AskingForARoomApi.md#listmyrentalrequests) | **GET** /api/v1/me/rental-requests | What I have asked for
[**sendRentalRequest**](AskingForARoomApi.md#sendrentalrequest) | **POST** /api/v1/me/rental-requests | Ask for a bed or a unit
[**withdrawRentalRequest**](AskingForARoomApi.md#withdrawrentalrequest) | **POST** /api/v1/me/rental-requests/{id}/withdraw | Change my mind


# **listMyRentalRequests**
> List<RentalRequestResponse> listMyRentalRequests()

What I have asked for

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingForARoomApi();

try {
    final result = api_instance.listMyRentalRequests();
    print(result);
} catch (e) {
    print('Exception when calling AskingForARoomApi->listMyRentalRequests: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<RentalRequestResponse>**](RentalRequestResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendRentalRequest**
> RentalRequestResponse sendRentalRequest(rentalRequestCreate)

Ask for a bed or a unit

Needs a complete tenant profile. Omit bedId to ask for the whole unit.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingForARoomApi();
final rentalRequestCreate = RentalRequestCreate(); // RentalRequestCreate | 

try {
    final result = api_instance.sendRentalRequest(rentalRequestCreate);
    print(result);
} catch (e) {
    print('Exception when calling AskingForARoomApi->sendRentalRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentalRequestCreate** | [**RentalRequestCreate**](RentalRequestCreate.md)|  | 

### Return type

[**RentalRequestResponse**](RentalRequestResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **withdrawRentalRequest**
> RentalRequestResponse withdrawRentalRequest(id)

Change my mind

Only while it is still waiting on the landlord.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingForARoomApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.withdrawRentalRequest(id);
    print(result);
} catch (e) {
    print('Exception when calling AskingForARoomApi->withdrawRentalRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**RentalRequestResponse**](RentalRequestResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

