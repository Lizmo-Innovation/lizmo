# lizmo_api.api.NotificationsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**countUnreadNotifications**](NotificationsApi.md#countunreadnotifications) | **GET** /api/v1/me/notifications/unread-count | How many are unread
[**listMyNotifications**](NotificationsApi.md#listmynotifications) | **GET** /api/v1/me/notifications | What is waiting
[**markAllNotificationsRead**](NotificationsApi.md#markallnotificationsread) | **POST** /api/v1/me/notifications/read | Mark everything read
[**markNotificationRead**](NotificationsApi.md#marknotificationread) | **POST** /api/v1/me/notifications/{id}/read | Mark one read


# **countUnreadNotifications**
> UnreadCount countUnreadNotifications()

How many are unread

Its own endpoint so drawing a badge costs one small request rather than the whole list.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = NotificationsApi();

try {
    final result = api_instance.countUnreadNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->countUnreadNotifications: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UnreadCount**](UnreadCount.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyNotifications**
> List<NotificationResponse> listMyNotifications()

What is waiting

Newest first, read and unread together: what happened last week is still the answer to what happened.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = NotificationsApi();

try {
    final result = api_instance.listMyNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->listMyNotifications: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<NotificationResponse>**](NotificationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllNotificationsRead**
> markAllNotificationsRead()

Mark everything read

What the badge invites somebody to do.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = NotificationsApi();

try {
    api_instance.markAllNotificationsRead();
} catch (e) {
    print('Exception when calling NotificationsApi->markAllNotificationsRead: $e\n');
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
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNotificationRead**
> markNotificationRead(id)

Mark one read

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = NotificationsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.markNotificationRead(id);
} catch (e) {
    print('Exception when calling NotificationsApi->markNotificationRead: $e\n');
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

