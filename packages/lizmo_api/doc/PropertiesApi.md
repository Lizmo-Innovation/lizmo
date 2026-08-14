# lizmo_api.api.PropertiesApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createProperty**](PropertiesApi.md#createproperty) | **POST** /api/v1/properties | Create a property
[**createUnit**](PropertiesApi.md#createunit) | **POST** /api/v1/properties/{id}/units | Add a unit to a property
[**deleteProperty**](PropertiesApi.md#deleteproperty) | **DELETE** /api/v1/properties/{id} | Delete a property
[**getProperty**](PropertiesApi.md#getproperty) | **GET** /api/v1/properties/{id} | View one property
[**listProperties**](PropertiesApi.md#listproperties) | **GET** /api/v1/properties | List my properties
[**listUnits**](PropertiesApi.md#listunits) | **GET** /api/v1/properties/{id}/units | List a property's units
[**updateProperty**](PropertiesApi.md#updateproperty) | **PUT** /api/v1/properties/{id} | Update a property


# **createProperty**
> PropertyResponse createProperty(propertyRequest)

Create a property

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final propertyRequest = PropertyRequest(); // PropertyRequest | 

try {
    final result = api_instance.createProperty(propertyRequest);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->createProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyRequest** | [**PropertyRequest**](PropertyRequest.md)|  | 

### Return type

[**PropertyResponse**](PropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUnit**
> UnitResponse createUnit(id, unitRequest)

Add a unit to a property

Rental mode is fixed at creation and cannot be changed afterwards.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final unitRequest = UnitRequest(); // UnitRequest | 

try {
    final result = api_instance.createUnit(id, unitRequest);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->createUnit: $e\n');
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

# **deleteProperty**
> deleteProperty(id)

Delete a property

Refused while the property still has units, to protect their billing history.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteProperty(id);
} catch (e) {
    print('Exception when calling PropertiesApi->deleteProperty: $e\n');
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

# **getProperty**
> PropertyResponse getProperty(id)

View one property

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getProperty(id);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->getProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PropertyResponse**](PropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listProperties**
> List<PropertyResponse> listProperties()

List my properties

Only properties owned by the signed-in landlord are ever returned.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();

try {
    final result = api_instance.listProperties();
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->listProperties: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PropertyResponse>**](PropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUnits**
> List<UnitResponse> listUnits(id)

List a property's units

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listUnits(id);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->listUnits: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**List<UnitResponse>**](UnitResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProperty**
> PropertyResponse updateProperty(id, propertyRequest)

Update a property

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final propertyRequest = PropertyRequest(); // PropertyRequest | 

try {
    final result = api_instance.updateProperty(id, propertyRequest);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->updateProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **propertyRequest** | [**PropertyRequest**](PropertyRequest.md)|  | 

### Return type

[**PropertyResponse**](PropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

