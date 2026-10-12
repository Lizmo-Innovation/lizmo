# lizmo_api.api.AnnouncementsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listMyNotices**](AnnouncementsApi.md#listmynotices) | **GET** /api/v1/me/notices | Announcements where I live
[**listPropertyNotices**](AnnouncementsApi.md#listpropertynotices) | **GET** /api/v1/properties/{propertyId}/notices | Announcements up on a building
[**markNoticeRead**](AnnouncementsApi.md#marknoticeread) | **POST** /api/v1/me/notices/{id}/read | I have read this announcement
[**postNotice**](AnnouncementsApi.md#postnotice) | **POST** /api/v1/properties/{propertyId}/notices | Post an announcement
[**takeDownNotice**](AnnouncementsApi.md#takedownnotice) | **POST** /api/v1/notices/{id}/take-down | Take an announcement down


# **listMyNotices**
> List<MyNoticeResponse> listMyNotices()

Announcements where I live

Everything up in the buildings, and units, I rent in now, newest first.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AnnouncementsApi();

try {
    final result = api_instance.listMyNotices();
    print(result);
} catch (e) {
    print('Exception when calling AnnouncementsApi->listMyNotices: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<MyNoticeResponse>**](MyNoticeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPropertyNotices**
> List<NoticeResponse> listPropertyNotices(propertyId)

Announcements up on a building

Newest first, with how many of the people each is for have opened it. Taken-down ones are not listed.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AnnouncementsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listPropertyNotices(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling AnnouncementsApi->listPropertyNotices: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**List<NoticeResponse>**](NoticeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNoticeRead**
> markNoticeRead(id)

I have read this announcement

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AnnouncementsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.markNoticeRead(id);
} catch (e) {
    print('Exception when calling AnnouncementsApi->markNoticeRead: $e\n');
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

# **postNotice**
> NoticeResponse postNotice(propertyId, postNotice)

Post an announcement

To everybody renting in the building, or in one unit. Those living there now are notified; anybody who moves in while it is up sees it too. Cannot be edited: take it down and post again.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AnnouncementsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final postNotice = PostNotice(); // PostNotice | 

try {
    final result = api_instance.postNotice(propertyId, postNotice);
    print(result);
} catch (e) {
    print('Exception when calling AnnouncementsApi->postNotice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **postNotice** | [**PostNotice**](PostNotice.md)|  | 

### Return type

[**NoticeResponse**](NoticeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **takeDownNotice**
> takeDownNotice(id)

Take an announcement down

Gone from every tenant's screen. Nobody is told.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = AnnouncementsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.takeDownNotice(id);
} catch (e) {
    print('Exception when calling AnnouncementsApi->takeDownNotice: $e\n');
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

