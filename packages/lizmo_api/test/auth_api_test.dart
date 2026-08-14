//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:lizmo_api/api.dart';
import 'package:test/test.dart';


/// tests for AuthApi
void main() {
  // final instance = AuthApi();

  group('tests for AuthApi', () {
    // Sign in with email or phone plus password
    //
    //Future<AuthResponse> login(LoginRequest loginRequest) async
    test('test login', () async {
      // TODO
    });

    // Revoke a refresh token
    //
    // Idempotent: unknown or already-revoked tokens still return 204.
    //
    //Future logout(RefreshRequest refreshRequest) async
    test('test logout', () async {
      // TODO
    });

    // Exchange a refresh token for a new pair
    //
    // The presented refresh token is revoked, so each one is usable exactly once.
    //
    //Future<AuthResponse> refresh(RefreshRequest refreshRequest) async
    test('test refresh', () async {
      // TODO
    });

    // Create an account
    //
    // Always creates a tenant profile; adds a landlord profile when asLandlord is true.
    //
    //Future<AuthResponse> register(RegisterRequest registerRequest) async
    test('test register', () async {
      // TODO
    });

  });
}
