# lizmo_api.model.RegisterRequest

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  | 
**email** | **String** | Required unless phone is given | [optional] 
**phone** | **String** | Required unless email is given | [optional] 
**password** | **String** |  | 
**asLandlord** | **bool** | Create a landlord profile as well as a tenant one | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


