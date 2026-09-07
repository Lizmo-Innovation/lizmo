# lizmo_api.model.EndLeaseRequest

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**terminated** | **bool** |  | [optional] 
**reason** | **String** | Why it ended, for the landlord's own records. Not shown to the tenant -- the deposit settlement is the part that is. | [optional] 
**endDate** | [**DateTime**](DateTime.md) |  | [optional] 
**depositReturned** | **num** | How much of the deposit went back. Null when there was no deposit, or when the landlord has not settled it yet. | [optional] 
**depositSettlement** | **String** | What was withheld and why, in the landlord's own words. Free text rather than itemised deductions: withholding money is where tenancies go wrong, and an explanation somebody actually wrote beats a form nobody fills in honestly. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


