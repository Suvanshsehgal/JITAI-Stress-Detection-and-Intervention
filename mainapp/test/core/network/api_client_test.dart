import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mainapp/core/network/api_client.dart';

void main() {
  group('ApiClient', () {
    test('successful GET request returns decoded JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/test-endpoint');
        expect(request.method, 'GET');
        return http.Response(jsonEncode({'message': 'hello'}), 200);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final res = await client.get('/test-endpoint');
      expect(res, equals({'message': 'hello'}));
    });

    test('successful POST injects Authorization header when token set', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer secret-jwt-token');
        expect(request.headers['Content-Type'], 'application/json');
        final body = jsonDecode(request.body);
        expect(body['name'], 'Ebb');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );
      client.setAuthToken('secret-jwt-token');

      final res = await client.post('/submit', {'name': 'Ebb'});
      expect(res, equals({'status': 'ok'}));
    });

    test('throws UnauthorizedException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      expect(
        () => client.get('/protected'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ApiException on 400 or 500 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      expect(
        () => client.get('/broken'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
