# lizmo_api.model.UnitOverview

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | [optional] 
**unitNumber** | **String** |  | [optional] 
**floor** | **String** |  | [optional] 
**rentalMode** | **String** |  | [optional] 
**status** | **String** |  | [optional] 
**rent** | **num** | Per bed for a bedspace room, for the unit otherwise | [optional] 
**beds** | [**List<BedState>**](BedState.md) | Each rentable bed, let or not. Empty for a whole unit | [optional] [default to const []]
**tenantName** | **String** | Who a whole unit is let to, when it is | [optional] 
**readyFrom** | [**DateTime**](DateTime.md) | When its vacant space is ready, if not now | [optional] 
**overdueTenancies** | **int** | Tenancies in it with rent owed late | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


