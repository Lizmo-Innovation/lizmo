# lizmo_api.api.MaintenanceApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addMaintenancePhoto**](MaintenanceApi.md#addmaintenancephoto) | **POST** /api/v1/me/maintenance/{id}/photos | Add a photo to my report
[**confirmMaintenanceFixed**](MaintenanceApi.md#confirmmaintenancefixed) | **POST** /api/v1/me/maintenance/{id}/fixed | Say it is fixed
[**listMyMaintenanceReports**](MaintenanceApi.md#listmymaintenancereports) | **GET** /api/v1/me/maintenance | What I have reported
[**reopenMaintenanceReport**](MaintenanceApi.md#reopenmaintenancereport) | **POST** /api/v1/me/maintenance/{id}/reopen | Say it is still broken
[**reportProblem**](MaintenanceApi.md#reportproblem) | **POST** /api/v1/me/maintenance | Report something broken
[**withdrawMaintenanceReport**](MaintenanceApi.md#withdrawmaintenancereport) | **POST** /api/v1/me/maintenance/{id}/withdraw | Take my report back


# **addMaintenancePhoto**
> MaintenanceReportResponse addMaintenancePhoto(id, photo)

Add a photo to my report

Up to three, while nobody has started on it. Re-encoded, so no EXIF or location leaves the phone.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final photo = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.addMaintenancePhoto(id, photo);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->addMaintenancePhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **photo** | **MultipartFile**|  | 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **confirmMaintenanceFixed**
> MaintenanceReportResponse confirmMaintenanceFixed(id)

Say it is fixed

Closes a report the landlord has marked resolved.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.confirmMaintenanceFixed(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->confirmMaintenanceFixed: $e\n');
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

# **listMyMaintenanceReports**
> List<MaintenanceReportResponse> listMyMaintenanceReports()

What I have reported

Newest first, whatever became of each.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();

try {
    final result = api_instance.listMyMaintenanceReports();
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->listMyMaintenanceReports: $e\n');
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

# **reopenMaintenanceReport**
> MaintenanceReportResponse reopenMaintenanceReport(id, maintenanceNote)

Say it is still broken

On a report the landlord has marked resolved. A reason is required: it is the whole of what the landlord needs to hear.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final maintenanceNote = MaintenanceNote(); // MaintenanceNote | 

try {
    final result = api_instance.reopenMaintenanceReport(id, maintenanceNote);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->reopenMaintenanceReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **maintenanceNote** | [**MaintenanceNote**](MaintenanceNote.md)|  | 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportProblem**
> MaintenanceReportResponse reportProblem(reportProblemRequest)

Report something broken

Against the tenancy the caller is living under now. The landlord is told. Photos are added afterwards, one at a time.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();
final reportProblemRequest = ReportProblemRequest(); // ReportProblemRequest | 

try {
    final result = api_instance.reportProblem(reportProblemRequest);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->reportProblem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reportProblemRequest** | [**ReportProblemRequest**](ReportProblemRequest.md)|  | 

### Return type

[**MaintenanceReportResponse**](MaintenanceReportResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **withdrawMaintenanceReport**
> MaintenanceReportResponse withdrawMaintenanceReport(id)

Take my report back

Only while nobody has started on it. Kept, not deleted.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = MaintenanceApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.withdrawMaintenanceReport(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceApi->withdrawMaintenanceReport: $e\n');
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

