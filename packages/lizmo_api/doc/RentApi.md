# lizmo_api.api.RentApi

## Load the API package
```dart
import 'package:lizmo_api/api.dart';
```

All URIs are relative to *http://localhost:8082*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmPayment**](RentApi.md#confirmpayment) | **POST** /api/v1/leases/{leaseId}/payments/{paymentId}/confirm | Agree the money arrived
[**declarePayment**](RentApi.md#declarepayment) | **POST** /api/v1/me/leases/{leaseId}/payments | Say I have paid
[**getCollections**](RentApi.md#getcollections) | **GET** /api/v1/me/collections | How rent is going
[**listLeaseBilling**](RentApi.md#listleasebilling) | **GET** /api/v1/leases/{leaseId}/billing | Rent on this tenancy
[**listLeasePayments**](RentApi.md#listleasepayments) | **GET** /api/v1/leases/{leaseId}/payments | Payments on this tenancy
[**listMyBilling**](RentApi.md#listmybilling) | **GET** /api/v1/me/leases/{leaseId}/billing | My rent
[**listMyPayments**](RentApi.md#listmypayments) | **GET** /api/v1/me/leases/{leaseId}/payments | What I have paid
[**recordPayment**](RentApi.md#recordpayment) | **POST** /api/v1/leases/{leaseId}/payments | Record money I received
[**rejectPayment**](RentApi.md#rejectpayment) | **POST** /api/v1/leases/{leaseId}/payments/{paymentId}/reject | Say it did not arrive


# **confirmPayment**
> PaymentResponse confirmPayment(leaseId, paymentId)

Agree the money arrived

The only thing that moves a balance for a payment a tenant declared. Answering twice is refused, which is the one way this could quietly invent money.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.confirmPayment(leaseId, paymentId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->confirmPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **paymentId** | **String**|  | 

### Return type

[**PaymentResponse**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declarePayment**
> PaymentResponse declarePayment(leaseId, payment, proof)

Say I have paid

Waits for the landlord to confirm; nothing about the balance moves until they do. A screenshot is optional -- cash is real, and a required field nobody can satisfy becomes one people lie in. Any photograph is re-encoded, so no EXIF or location leaves the phone.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final payment = ; // RecordPaymentRequest | 
final proof = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.declarePayment(leaseId, payment, proof);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->declarePayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **payment** | [**RecordPaymentRequest**](RecordPaymentRequest.md)|  | 
 **proof** | **MultipartFile**|  | [optional] 

### Return type

[**PaymentResponse**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollections**
> CollectionsSummary getCollections()

How rent is going

Due and collected this month, everything still outstanding, and who is behind -- worst first. Asking also brings the schedule up to date, so a tenancy nobody has opened this month is still counted.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();

try {
    final result = api_instance.getCollections();
    print(result);
} catch (e) {
    print('Exception when calling RentApi->getCollections: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CollectionsSummary**](CollectionsSummary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLeaseBilling**
> List<BillingPeriodResponse> listLeaseBilling(leaseId)

Rent on this tenancy

Oldest month first. Months are created as they begin, so opening this is what brings the schedule up to date.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeaseBilling(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listLeaseBilling: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<BillingPeriodResponse>**](BillingPeriodResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLeasePayments**
> List<PaymentResponse> listLeasePayments(leaseId)

Payments on this tenancy

Newest first, whatever their state. A rejected payment stays in the list: the disagreement is worth keeping.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listLeasePayments(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listLeasePayments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<PaymentResponse>**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyBilling**
> List<BillingPeriodResponse> listMyBilling(leaseId)

My rent

The same months the landlord sees. Readable after the tenancy ends: what you paid is worth having afterwards.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listMyBilling(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listMyBilling: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<BillingPeriodResponse>**](BillingPeriodResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyPayments**
> List<PaymentResponse> listMyPayments(leaseId)

What I have paid

Including anything still waiting to be confirmed, and anything the landlord refused.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listMyPayments(leaseId);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->listMyPayments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 

### Return type

[**List<PaymentResponse>**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recordPayment**
> PaymentResponse recordPayment(leaseId, recordPaymentRequest)

Record money I received

Confirmed immediately: the landlord received it, so there is nobody for them to disagree with. The month's balance moves at once and the tenant is told.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final recordPaymentRequest = RecordPaymentRequest(); // RecordPaymentRequest | 

try {
    final result = api_instance.recordPayment(leaseId, recordPaymentRequest);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->recordPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **recordPaymentRequest** | [**RecordPaymentRequest**](RecordPaymentRequest.md)|  | 

### Return type

[**PaymentResponse**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectPayment**
> PaymentResponse rejectPayment(leaseId, paymentId, remarks)

Say it did not arrive

Rejected rather than deleted: a tenant who wrote something down and found it gone would not know whether it was refused or lost. Nothing is credited.

### Example
```dart
import 'package:lizmo_api/api.dart';

final api_instance = RentApi();
final leaseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final paymentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final remarks = remarks_example; // String | 

try {
    final result = api_instance.rejectPayment(leaseId, paymentId, remarks);
    print(result);
} catch (e) {
    print('Exception when calling RentApi->rejectPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **leaseId** | **String**|  | 
 **paymentId** | **String**|  | 
 **remarks** | **String**|  | [optional] 

### Return type

[**PaymentResponse**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

