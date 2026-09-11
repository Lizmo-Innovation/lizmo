# lizmo_api.api.MaintenanceToHandleApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMaintenanceReport**](MaintenanceToHandleApi.md#getmaintenancereport) | **GET** /api/v1/maintenance/{id} | One report in full
[**listMaintenanceReports**](MaintenanceToHandleApi.md#listmaintenancereports) | **GET** /api/v1/maintenance | Everything reported on my properties
[**resolveMaintenance**](MaintenanceToHandleApi.md#resolvemaintenance) | **POST** /api/v1/maintenance/{id}/resolve | Say it is fixed
[**startMaintenance**](MaintenanceToHandleApi.md#startmaintenance) | **POST** /api/v1/maintenance/{id}/start | Start on it


# **getMaintenanceReport**
> MaintenanceReportResponse getMaintenanceReport(id)

One report in full

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceToHandleApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getMaintenanceReport(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceToHandleApi->getMaintenanceReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMaintenanceReports**
> List<MaintenanceReportResponse> listMaintenanceReports()

Everything reported on my properties

Newest first, across every property, whatever became of each.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceToHandleApi();

try {
    final result = api_instance.listMaintenanceReports();
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceToHandleApi->listMaintenanceReports: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<MaintenanceReportResponse>**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resolveMaintenance**
> MaintenanceReportResponse resolveMaintenance(id, maintenanceNote)

Say it is fixed

The tenant is asked to confirm, or to say it is still broken.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceToHandleApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final maintenanceNote = MaintenanceNote(); // MaintenanceNote | 

try {
    final result = api_instance.resolveMaintenance(id, maintenanceNote);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceToHandleApi->resolveMaintenance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **maintenanceNote** | [**MaintenanceNote**](MaintenanceNote.md)|  | [optional] 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startMaintenance**
> MaintenanceReportResponse startMaintenance(id, maintenanceNote)

Start on it

The tenant is told, with the remark if there is one.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceToHandleApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final maintenanceNote = MaintenanceNote(); // MaintenanceNote | 

try {
    final result = api_instance.startMaintenance(id, maintenanceNote);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceToHandleApi->startMaintenance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **maintenanceNote** | [**MaintenanceNote**](MaintenanceNote.md)|  | [optional] 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

