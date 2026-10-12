# lizmo_api.model.NoticeResponse

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
**unitId** | **String** | Set when it went to one unit only | [optional] 
**unitNumber** | **String** |  | [optional] 
**title** | **String** |  | [optional] 
**message** | **String** |  | [optional] 
**postedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**until** | [**DateTime**](DateTime.md) | The last day it is shown, if it has one | [optional] 
**live** | **bool** | False once past its last day | [optional] 
**seenBy** | **int** | How many of the people it is for have opened it | [optional] 
**audience** | **int** | How many people it is for: everybody renting there now | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


