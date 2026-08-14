# lizmo_api.model.AuthResponse

## Load the model package
```dart
import 'package:lizmo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accessToken** | **String** | Short-lived bearer token | [optional] 
**refreshToken** | **String** | Long-lived token, exchanged for new access tokens | [optional] 
**expiresIn** | **int** | Access token lifetime in seconds | [optional] 
**userId** | **String** |  | [optional] 
**name** | **String** |  | [optional] 
**profiles** | **List<String>** |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


