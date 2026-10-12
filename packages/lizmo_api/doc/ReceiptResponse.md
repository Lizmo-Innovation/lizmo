# lizmo_api.model.ReceiptResponse

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | [optional] 
**paymentId** | **String** |  | [optional] 
**leaseId** | **String** |  | [optional] 
**number** | **String** | Numbered per landlord, per year, in the order issued | [optional] 
**issuedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**receivedFrom** | **String** |  | [optional] 
**receivedBy** | **String** |  | [optional] 
**propertyName** | **String** |  | [optional] 
**place** | **String** |  | [optional] 
**periodLabel** | **String** |  | [optional] 
**kind** | **String** |  | [optional] 
**amount** | **num** |  | [optional] 
**paymentMethod** | **String** |  | [optional] 
**sentTo** | **String** |  | [optional] 
**paidOn** | [**DateTime**](DateTime.md) |  | [optional] 
**stillOwed** | **num** | What was left of that month, or the deposit, once this was counted. Zero when it settled it. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


