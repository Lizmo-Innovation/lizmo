import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:lizmo/api/authenticated_client.dart';

void main() {
  Request get(String path) => Request('GET', Uri.parse('http://x$path'));

  test('passes a successful response straight through', () async {
    var refreshes = 0;
    final client = AuthenticatedClient(
      inner: MockClient((_) async => Response('{"ok":true}', 200)),
      onUnauthorized: () async {
        refreshes++;
        return 'new';
      },
    );

    final response = await client.send(get('/api/v1/properties'));

    expect(response.statusCode, 200);
    expect(refreshes, 0, reason: 'a 200 must not trigger a refresh');
  });

  test('on 401 it refreshes, replays with the new token, and returns the retry',
      () async {
    final sent = <BaseRequest>[];
    var refreshes = 0;

    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        sent.add(request);
        return sent.length == 1
            ? Response('{"code":"UNAUTHENTICATED"}', 401)
            : Response('{"ok":true}', 200);
      }),
      onUnauthorized: () async {
        refreshes++;
        return 'fresh-token';
      },
    );

    final response = await client.send(
      get('/api/v1/properties')..headers['Authorization'] = 'Bearer stale',
    );

    expect(response.statusCode, 200);
    expect(refreshes, 1);
    expect(sent.length, 2, reason: 'the request should be replayed once');
    expect(sent.last.headers['Authorization'], 'Bearer fresh-token');
  });

  test('replays the body, so a POST is not resent empty', () async {
    final bodies = <String>[];

    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        bodies.add(request.body);
        return bodies.length == 1 ? Response('', 401) : Response('{}', 200);
      }),
      onUnauthorized: () async => 'fresh',
    );

    final post = Request('POST', Uri.parse('http://x/api/v1/payments'))
      ..body = jsonEncode({'amount': 2500});

    await client.send(post);

    expect(bodies.length, 2);
    expect(bodies.last, jsonEncode({'amount': 2500}),
        reason: 'a replayed write must carry its original body');
  });

  test('when refresh fails the original 401 is returned intact', () async {
    final client = AuthenticatedClient(
      inner: MockClient((_) async => Response('{"code":"UNAUTHENTICATED"}', 401)),
      onUnauthorized: () async => null,
    );

    final response = await client.send(get('/api/v1/properties'));

    expect(response.statusCode, 401);
    // The body must survive: ApiFailure parses it to decide what to show.
    expect(await response.stream.bytesToString(), contains('UNAUTHENTICATED'));
  });

  test('does not refresh when an auth endpoint itself returns 401', () async {
    var refreshes = 0;
    final client = AuthenticatedClient(
      inner: MockClient((_) async => Response('{"code":"INVALID_CREDENTIALS"}', 401)),
      onUnauthorized: () async {
        refreshes++;
        return 'fresh';
      },
    );

    final response = await client.send(
      Request('POST', Uri.parse('http://x/api/v1/auth/login')),
    );

    expect(response.statusCode, 401);
    // A wrong password is a real answer, and refreshing on it would recurse.
    expect(refreshes, 0);
  });

  test('concurrent 401s share a single refresh', () async {
    var refreshes = 0;
    var seen = 0;

    final client = AuthenticatedClient(
      inner: MockClient((request) async {
        seen++;
        // The first three calls are the initial requests; later ones are replays.
        return seen <= 3 ? Response('', 401) : Response('{}', 200);
      }),
      onUnauthorized: () async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'fresh';
      },
    );

    await Future.wait([
      client.send(get('/api/v1/a')),
      client.send(get('/api/v1/b')),
      client.send(get('/api/v1/c')),
    ]);

    // Without single-flight each request would rotate the refresh token, and
    // the losers would revoke the winner's session.
    expect(refreshes, 1);
  });
}
