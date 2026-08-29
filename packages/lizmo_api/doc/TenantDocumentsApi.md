# lizmo_api.api.TenantDocumentsApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listMyTenantDocuments**](TenantDocumentsApi.md#listmytenantdocuments) | **GET** /api/v1/me/tenant-profile/documents | My photographs
[**uploadMyTenantDocument**](TenantDocumentsApi.md#uploadmytenantdocument) | **POST** /api/v1/me/tenant-profile/documents | Upload a photograph


# **listMyTenantDocuments**
> List<TenantDocumentResponse> listMyTenantDocuments()

My photographs

Each carries a presigned URL valid for a few minutes. Do not cache it; ask again instead.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = TenantDocumentsApi();

try {
    final result = api_instance.listMyTenantDocuments();
    print(result);
} catch (e) {
    print('Exception when calling TenantDocumentsApi->listMyTenantDocuments: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<TenantDocumentResponse>**](TenantDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadMyTenantDocument**
> TenantDocumentResponse uploadMyTenantDocument(docType, file)

Upload a photograph

Re-encoded on arrival, so no EXIF or location data is kept. Uploading again replaces what is there.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = TenantDocumentsApi();
final docType = docType_example; // String | 
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadMyTenantDocument(docType, file);
    print(result);
} catch (e) {
    print('Exception when calling TenantDocumentsApi->uploadMyTenantDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **docType** | **String**|  | 
 **file** | **MultipartFile**|  | 

### Return type

[**TenantDocumentResponse**](TenantDocumentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

