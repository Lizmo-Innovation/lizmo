# lizmo_api.api.UnitsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createBed**](UnitsApi.md#createbed) | **POST** /api/v1/units/{id}/beds | Add a bed
[**deleteBed**](UnitsApi.md#deletebed) | **DELETE** /api/v1/beds/{id} | Remove a bed
[**deleteUnit**](UnitsApi.md#deleteunit) | **DELETE** /api/v1/units/{id} | Delete a unit
[**getUnit**](UnitsApi.md#getunit) | **GET** /api/v1/units/{id} | View one unit
[**listBeds**](UnitsApi.md#listbeds) | **GET** /api/v1/units/{id}/beds | List a unit's beds
[**listUtilities**](UnitsApi.md#listutilities) | **GET** /api/v1/units/{id}/utilities | A unit's fixed monthly utilities
[**setBedMaintenance**](UnitsApi.md#setbedmaintenance) | **PUT** /api/v1/beds/{id}/maintenance | Take a bed out of service, or put it back
[**setUnitMaintenance**](UnitsApi.md#setunitmaintenance) | **PUT** /api/v1/units/{id}/maintenance | Take a unit out of service, or put it back
[**setUtilities**](UnitsApi.md#setutilities) | **PUT** /api/v1/units/{id}/utilities | Set a unit's fixed monthly utilities
[**updateBed**](UnitsApi.md#updatebed) | **PUT** /api/v1/beds/{id} | Rename a bed
[**updateUnit**](UnitsApi.md#updateunit) | **PUT** /api/v1/units/{id} | Update a unit


# **createBed**
> BedResponse createBed(id, bedRequest)

Add a bed

Bedspace units only, and never beyond the unit's capacity.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bedRequest = BedRequest(); // BedRequest | 

try {
    final result = api_instance.createBed(id, bedRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->createBed: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **bedRequest** | [**BedRequest**](BedRequest.md)|  | 

### Return type

[**BedResponse**](BedResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteBed**
> deleteBed(id)

Remove a bed

Refused while the bed is occupied.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteBed(id);
} catch (e) {
    print('Exception when calling UnitsApi->deleteBed: $e\n');
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

# **deleteUnit**
> deleteUnit(id)

Delete a unit

Refused while the unit still has beds.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteUnit(id);
} catch (e) {
    print('Exception when calling UnitsApi->deleteUnit: $e\n');
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

# **getUnit**
> UnitResponse getUnit(id)

View one unit

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getUnit(id);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->getUnit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**UnitResponse**](UnitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBeds**
> List<BedResponse> listBeds(id)

List a unit's beds

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listBeds(id);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->listBeds: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**List<BedResponse>**](BedResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUtilities**
> UtilitiesResponse listUtilities(id)

A unit's fixed monthly utilities

Always returns every kind, including ones never set up.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listUtilities(id);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->listUtilities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**UtilitiesResponse**](UtilitiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setBedMaintenance**
> BedResponse setBedMaintenance(id, maintenanceRequest)

Take a bed out of service, or put it back

Refused while the bed is occupied.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final maintenanceRequest = MaintenanceRequest(); // MaintenanceRequest | 

try {
    final result = api_instance.setBedMaintenance(id, maintenanceRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->setBedMaintenance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **maintenanceRequest** | [**MaintenanceRequest**](MaintenanceRequest.md)|  | 

### Return type

[**BedResponse**](BedResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setUnitMaintenance**
> UnitResponse setUnitMaintenance(id, maintenanceRequest)

Take a unit out of service, or put it back

Refused while the unit is occupied.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final maintenanceRequest = MaintenanceRequest(); // MaintenanceRequest | 

try {
    final result = api_instance.setUnitMaintenance(id, maintenanceRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->setUnitMaintenance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **maintenanceRequest** | [**MaintenanceRequest**](MaintenanceRequest.md)|  | 

### Return type

[**UnitResponse**](UnitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setUtilities**
> UtilitiesResponse setUtilities(id, utilitiesRequest)

Set a unit's fixed monthly utilities

Only the kinds sent are changed; the others are left alone.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final utilitiesRequest = UtilitiesRequest(); // UtilitiesRequest | 

try {
    final result = api_instance.setUtilities(id, utilitiesRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->setUtilities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **utilitiesRequest** | [**UtilitiesRequest**](UtilitiesRequest.md)|  | 

### Return type

[**UtilitiesResponse**](UtilitiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateBed**
> BedResponse updateBed(id, bedRequest)

Rename a bed

Labels must be unique within the unit, case-insensitively.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bedRequest = BedRequest(); // BedRequest | 

try {
    final result = api_instance.updateBed(id, bedRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->updateBed: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **bedRequest** | [**BedRequest**](BedRequest.md)|  | 

### Return type

[**BedResponse**](BedResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUnit**
> UnitResponse updateUnit(id, unitRequest)

Update a unit

Rental mode cannot change, and capacity cannot drop below the beds already defined.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = UnitsApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final unitRequest = UnitRequest(); // UnitRequest | 

try {
    final result = api_instance.updateUnit(id, unitRequest);
    print(result);
} catch (e) {
    print('Exception when calling UnitsApi->updateUnit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **unitRequest** | [**UnitRequest**](UnitRequest.md)|  | 

### Return type

[**UnitResponse**](UnitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

