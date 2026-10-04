# lizmo_api.api.AskingAboutAPlaceApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**closeInquiry**](AskingAboutAPlaceApi.md#closeinquiry) | **POST** /api/v1/inquiries/{id}/close | End it
[**listMyInquiries**](AskingAboutAPlaceApi.md#listmyinquiries) | **GET** /api/v1/inquiries | My conversations
[**markInquiryRead**](AskingAboutAPlaceApi.md#markinquiryread) | **POST** /api/v1/inquiries/{id}/read | Mark it seen
[**readInquiry**](AskingAboutAPlaceApi.md#readinquiry) | **GET** /api/v1/inquiries/{id} | One conversation
[**sendInquiryMessage**](AskingAboutAPlaceApi.md#sendinquirymessage) | **POST** /api/v1/inquiries/{id}/messages | Say something
[**startInquiry**](AskingAboutAPlaceApi.md#startinquiry) | **POST** /api/v1/inquiries | Ask about a place
[**startLeaseFromInquiry**](AskingAboutAPlaceApi.md#startleasefrominquiry) | **POST** /api/v1/inquiries/{id}/lease | Write the tenancy they agreed on


# **closeInquiry**
> InquirySummary closeInquiry(id)

End it

From either side. Asking about the place again reopens it.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.closeInquiry(id);
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->closeInquiry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**InquirySummary**](InquirySummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyInquiries**
> List<InquirySummary> listMyInquiries()

My conversations

Both sides: threads I started, and threads about places I let. Most recently spoken in first.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();

try {
    final result = api_instance.listMyInquiries();
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->listMyInquiries: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<InquirySummary>**](InquirySummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markInquiryRead**
> markInquiryRead(id)

Mark it seen

For a list the reader has been through without opening every thread.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.markInquiryRead(id);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->markInquiryRead: $e\n');
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
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readInquiry**
> InquiryThread readInquiry(id)

One conversation

Everything said in it. Reading it marks it seen for whoever asked.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.readInquiry(id);
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->readInquiry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**InquiryThread**](InquiryThread.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendInquiryMessage**
> InquiryMessageResponse sendInquiryMessage(id, newMessage)

Say something

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final newMessage = NewMessage(); // NewMessage | 

try {
    final result = api_instance.sendInquiryMessage(id, newMessage);
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->sendInquiryMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **newMessage** | [**NewMessage**](NewMessage.md)|  | 

### Return type

[**InquiryMessageResponse**](InquiryMessageResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startInquiry**
> InquiryThread startInquiry(startInquiry)

Ask about a place

Starts the conversation, or reopens the one that already exists with this landlord about this property. Needs a contact number, so they can ring back.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final startInquiry = StartInquiry(); // StartInquiry | 

try {
    final result = api_instance.startInquiry(startInquiry);
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->startInquiry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startInquiry** | [**StartInquiry**](StartInquiry.md)|  | 

### Return type

[**InquiryThread**](InquiryThread.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startLeaseFromInquiry**
> LeaseResponse startLeaseFromInquiry(id, acceptRequest)

Write the tenancy they agreed on

The landlord, from inside the conversation. The room has to be named here: the tenant was never shown which rooms exist. Everything else defaults to the asking rent, today, and the day of the month they move in.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AskingAboutAPlaceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final acceptRequest = AcceptRequest(); // AcceptRequest | 

try {
    final result = api_instance.startLeaseFromInquiry(id, acceptRequest);
    print(result);
} catch (e) {
    print('Exception when calling AskingAboutAPlaceApi->startLeaseFromInquiry: $e\n');
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

