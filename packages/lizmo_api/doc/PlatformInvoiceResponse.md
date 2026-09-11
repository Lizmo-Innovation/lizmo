# lizmo_api.model.PlatformInvoiceResponse

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | [optional] 
**propertyId** | **String** |  | [optional] 
**propertyName** | **String** |  | [optional] 
**label** | **String** |  | [optional] 
**billingDate** | [**DateTime**](DateTime.md) |  | [optional] 
**dueDate** | [**DateTime**](DateTime.md) |  | [optional] 
**occupiedUnits** | **int** |  | [optional] 
**occupiedBeds** | **int** |  | [optional] 
**unitRate** | **num** |  | [optional] 
**bedRate** | **num** |  | [optional] 
**amountDue** | **num** |  | [optional] 
**amountPaid** | **num** |  | [optional] 
**outstanding** | **num** |  | [optional] 
**status** | **String** |  | [optional] 
**overdue** | **bool** |  | [optional] 
**locksOn** | [**DateTime**](DateTime.md) |  | [optional] 
**lockedByThis** | **bool** |  | [optional] 
**payments** | [**List<PlatformPaymentResponse>**](PlatformPaymentResponse.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


