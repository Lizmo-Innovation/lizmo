# lizmo_api.model.AcceptRequest

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**unitId** | **String** | Which room to give them. Required when the request is about the property rather than one room, and ignored when it names one. | [optional] 
**bedId** | **String** | Which bed, when that unit is let bed by bed | [optional] 
**rentAmount** | **num** | Defaults to the asking rent | [optional] 
**dueDateDay** | **int** | Defaults to the start date's day | [optional] 
**startDate** | [**DateTime**](DateTime.md) | Defaults to today | [optional] 
**depositAmount** | **num** | Held against damage, and mostly given back. Not rent. Null means none was recorded, which is not the same as none being taken. | [optional] 
**advanceAmount** | **num** | Rent paid before moving in, which pays for the first month. Kept apart from the deposit because it is money the landlord has earned rather than money they are holding. | [optional] 
**endsOn** | [**DateTime**](DateTime.md) | The last day of the lease, if it was agreed for a term. Null for month to month, which is the usual case. Both of them are warned as it nears; passing it ends nothing. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


