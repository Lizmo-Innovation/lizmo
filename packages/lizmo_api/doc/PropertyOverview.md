# lizmo_api.model.PropertyOverview

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**occupied** | **int** | Spaces let: beds, and whole units counted as one | [optional] 
**rentable** | **int** | Spaces that can be let: out of service ones are not | [optional] 
**vacant** | **int** |  | [optional] 
**overdueTotal** | **num** | What is owed late across every tenancy here | [optional] 
**units** | [**List<UnitOverview>**](UnitOverview.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


