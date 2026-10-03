# lizmo_api.model.PlatformSettings

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**supportEmail** | **String** |  | 
**paymentInstructions** | **String** |  | [optional] 
**minimumAndroidVersion** | **String** | The oldest Android version allowed in. Raising it locks out everybody on an older one, so it is left alone when not sent; blank stops Android being checked. | [optional] 
**minimumIosVersion** | **String** | The same for iOS, separately: releases drift apart. | [optional] 
**androidUpdateUrl** | **String** |  | [optional] 
**iosUpdateUrl** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


