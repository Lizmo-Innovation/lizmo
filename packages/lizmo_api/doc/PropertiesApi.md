# lizmo_api.api.PropertiesApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addPropertyPhoto**](PropertiesApi.md#addpropertyphoto) | **POST** /api/v1/properties/{propertyId}/photos | Add a photo
[**createProperty**](PropertiesApi.md#createproperty) | **POST** /api/v1/properties | Create a property
[**createUnit**](PropertiesApi.md#createunit) | **POST** /api/v1/properties/{id}/units | Add a unit to a property
[**deleteProperty**](PropertiesApi.md#deleteproperty) | **DELETE** /api/v1/properties/{id} | Delete a property
[**deletePropertyPhoto**](PropertiesApi.md#deletepropertyphoto) | **DELETE** /api/v1/properties/{propertyId}/photos/{photoId} | Remove a photo
[**getOccupancy**](PropertiesApi.md#getoccupancy) | **GET** /api/v1/me/occupancy | What is let and what is empty
[**getPlaceDetails**](PropertiesApi.md#getplacedetails) | **GET** /api/v1/properties/{id}/details | A place's rules, money up front and what comes with it
[**getProperty**](PropertiesApi.md#getproperty) | **GET** /api/v1/properties/{id} | View one property
[**listProperties**](PropertiesApi.md#listproperties) | **GET** /api/v1/properties | List my properties
[**listPropertyPhotos**](PropertiesApi.md#listpropertyphotos) | **GET** /api/v1/properties/{propertyId}/photos | This property's photos
[**listUnits**](PropertiesApi.md#listunits) | **GET** /api/v1/properties/{id}/units | List a property's units
[**reorderPropertyPhotos**](PropertiesApi.md#reorderpropertyphotos) | **PUT** /api/v1/properties/{propertyId}/photos/order | Put them in order
[**savePlaceDetails**](PropertiesApi.md#saveplacedetails) | **PUT** /api/v1/properties/{id}/details | Set a place's details
[**updateProperty**](PropertiesApi.md#updateproperty) | **PUT** /api/v1/properties/{id} | Update a property


# **addPropertyPhoto**
> PropertyPhoto addPropertyPhoto(propertyId, file)

Add a photo

Up to 8 per property. Re-encoded on the way in, so what is stored carries no EXIF and no GPS.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.addPropertyPhoto(propertyId, file);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->addPropertyPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **file** | **MultipartFile**|  | 

### Return type

[**PropertyPhoto**](PropertyPhoto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **deletePropertyPhoto**
> deletePropertyPhoto(propertyId, photoId)

Remove a photo

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final photoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deletePropertyPhoto(propertyId, photoId);
} catch (e) {
    print('Exception when calling PropertiesApi->deletePropertyPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **photoId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOccupancy**
> OccupancySummary getOccupancy()

What is let and what is empty

Counted in lettable slots rather than units: a four-bed room with one tenant is one let and three empty. Beds taken off the market are counted apart from vacancies, because a refurbishment is not a failure to let.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();

try {
    final result = api_instance.getOccupancy();
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->getOccupancy: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**OccupancySummary**](OccupancySummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPlaceDetails**
> PlaceDetailsDto getPlaceDetails(id)

A place's rules, money up front and what comes with it

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPlaceDetails(id);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->getPlaceDetails: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PlaceDetailsDto**](PlaceDetailsDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

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

# **listPropertyPhotos**
> List<PropertyPhoto> listPropertyPhotos(propertyId)

This property's photos

In order. The first is the one that represents the place.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listPropertyPhotos(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->listPropertyPhotos: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**List<PropertyPhoto>**](PropertyPhoto.md)

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

# **reorderPropertyPhotos**
> List<PropertyPhoto> reorderPropertyPhotos(propertyId, photoOrder)

Put them in order

Every id once. Whichever is first is the one a tenant sees against the place.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final photoOrder = PhotoOrder(); // PhotoOrder | 

try {
    final result = api_instance.reorderPropertyPhotos(propertyId, photoOrder);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->reorderPropertyPhotos: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **photoOrder** | [**PhotoOrder**](PhotoOrder.md)|  | 

### Return type

[**List<PropertyPhoto>**](PropertyPhoto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **savePlaceDetails**
> PlaceDetailsDto savePlaceDetails(id, placeDetailsDto)

Set a place's details

Replaced whole: a field left out is cleared. Shown on the page anybody sees after scanning the property code.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = PropertiesApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final placeDetailsDto = PlaceDetailsDto(); // PlaceDetailsDto | 

try {
    final result = api_instance.savePlaceDetails(id, placeDetailsDto);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->savePlaceDetails: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **placeDetailsDto** | [**PlaceDetailsDto**](PlaceDetailsDto.md)|  | 

### Return type

[**PlaceDetailsDto**](PlaceDetailsDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
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

