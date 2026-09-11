# lizmo_api.api.RequestsToAnswerApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptRentalRequest**](RequestsToAnswerApi.md#acceptrentalrequest) | **POST** /api/v1/rental-requests/{id}/accept | Say yes, and create the lease
[**declineRentalRequest**](RequestsToAnswerApi.md#declinerentalrequest) | **POST** /api/v1/rental-requests/{id}/decline | Say no
[**getRentalRequest**](RequestsToAnswerApi.md#getrentalrequest) | **GET** /api/v1/rental-requests/{id} | One request in full
[**listRentalRequestsForProperty**](RequestsToAnswerApi.md#listrentalrequestsforproperty) | **GET** /api/v1/properties/{propertyId}/rental-requests | Who has asked about this property
[**listRentalRequestsToAnswer**](RequestsToAnswerApi.md#listrentalrequeststoanswer) | **GET** /api/v1/rental-requests | Everybody waiting on this landlord, across every property


# **acceptRentalRequest**
> LeaseResponse acceptRentalRequest(id, acceptRequest)

Say yes, and create the lease

Terms are optional and default to the asking rent, today, and the day of the month the tenant moves in. Everyone else still waiting on the same bed or unit is superseded.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RequestsToAnswerApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final acceptRequest = AcceptRequest(); // AcceptRequest | 

try {
    final result = api_instance.acceptRentalRequest(id, acceptRequest);
    print(result);
} catch (e) {
    print('Exception when calling RequestsToAnswerApi->acceptRentalRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **acceptRequest** | [**AcceptRequest**](AcceptRequest.md)|  | [optional] 

### Return type

[**LeaseResponse**](LeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declineRentalRequest**
> RentalRequestForLandlord declineRentalRequest(id)

Say no

Frees nothing, because a request never held anything.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RequestsToAnswerApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.declineRentalRequest(id);
    print(result);
} catch (e) {
    print('Exception when calling RequestsToAnswerApi->declineRentalRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**RentalRequestForLandlord**](RentalRequestForLandlord.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRentalRequest**
> RentalRequestForLandlord getRentalRequest(id)

One request in full

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RequestsToAnswerApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getRentalRequest(id);
    print(result);
} catch (e) {
    print('Exception when calling RequestsToAnswerApi->getRentalRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**RentalRequestForLandlord**](RentalRequestForLandlord.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRentalRequestsForProperty**
> List<RentalRequestForLandlord> listRentalRequestsForProperty(propertyId, pendingOnly)

Who has asked about this property

Pending only by default, oldest first: a queue is answered in the order people joined it.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RequestsToAnswerApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final pendingOnly = true; // bool | 

try {
    final result = api_instance.listRentalRequestsForProperty(propertyId, pendingOnly);
    print(result);
} catch (e) {
    print('Exception when calling RequestsToAnswerApi->listRentalRequestsForProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **pendingOnly** | **bool**|  | [optional] [default to true]

### Return type

[**List<RentalRequestForLandlord>**](RentalRequestForLandlord.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRentalRequestsToAnswer**
> List<RentalRequestForLandlord> listRentalRequestsToAnswer()

Everybody waiting on this landlord, across every property

Pending only, oldest first across every property the caller owns. Empty for an account that owns none.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RequestsToAnswerApi();

try {
    final result = api_instance.listRentalRequestsToAnswer();
    print(result);
} catch (e) {
    print('Exception when calling RequestsToAnswerApi->listRentalRequestsToAnswer: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<RentalRequestForLandlord>**](RentalRequestForLandlord.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

