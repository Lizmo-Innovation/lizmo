# lizmo_api.api.TenantProfileApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyTenantProfile**](TenantProfileApi.md#getmytenantprofile) | **GET** /api/v1/me/tenant-profile | My tenant profile
[**updateMyTenantProfile**](TenantProfileApi.md#updatemytenantprofile) | **PUT** /api/v1/me/tenant-profile | Update my tenant profile


# **getMyTenantProfile**
> TenantProfileResponse getMyTenantProfile()

My tenant profile

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = TenantProfileApi();

try {
    final result = api_instance.getMyTenantProfile();
    print(result);
} catch (e) {
    print('Exception when calling TenantProfileApi->getMyTenantProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TenantProfileResponse**](TenantProfileResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMyTenantProfile**
> TenantProfileResponse updateMyTenantProfile(tenantProfileRequest)

Update my tenant profile

Every field is optional; blank clears it.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = TenantProfileApi();
final tenantProfileRequest = TenantProfileRequest(); // TenantProfileRequest | 

try {
    final result = api_instance.updateMyTenantProfile(tenantProfileRequest);
    print(result);
} catch (e) {
    print('Exception when calling TenantProfileApi->updateMyTenantProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tenantProfileRequest** | [**TenantProfileRequest**](TenantProfileRequest.md)|  | 

### Return type

[**TenantProfileResponse**](TenantProfileResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

