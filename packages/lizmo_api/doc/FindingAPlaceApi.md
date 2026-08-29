# lizmo_api.api.FindingAPlaceApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**findPropertyByCode**](FindingAPlaceApi.md#findpropertybycode) | **GET** /api/v1/properties/lookup | Find a property by its code


# **findPropertyByCode**
> PropertyByCodeResponse findPropertyByCode(code)

Find a property by its code

Case-insensitive. Spaces and dashes in the code are ignored, so a code read aloud and written down still matches.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = FindingAPlaceApi();
final code = code_example; // String | 

try {
    final result = api_instance.findPropertyByCode(code);
    print(result);
} catch (e) {
    print('Exception when calling FindingAPlaceApi->findPropertyByCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 

### Return type

[**PropertyByCodeResponse**](PropertyByCodeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

