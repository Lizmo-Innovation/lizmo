# lizmo_api.model.RecordPaymentRequest

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**billingPeriodId** | **String** | Which month this pays for | 
**amountPaid** | **num** |  | 
**paymentDate** | [**DateTime**](DateTime.md) |  | [optional] 
**paymentMethod** | **String** | Defaults to OTHER | [optional] 
**remarks** | **String** |  | [optional] 
**channelId** | **String** | Which of the landlord's payment channels it was sent to, if any. Kept as the channel read at that moment. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


