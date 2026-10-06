import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Session expired or unauthorized'])
      : super(message, 401);
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _authToken;
  final Duration timeoutDuration;

  ApiClient({
    String? baseUrl,
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 10),
  })  : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  static String _defaultBaseUrl() {
    // 10.0.2.2 is Android emulator host loopback, localhost is desktop/web
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.get(uri, headers: _headers()).timeout(timeoutDuration);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Unable to reach backend server. Please check your connection.');
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out while contacting server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeoutDuration);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException('Unable to reach backend server. Please check your connection.');
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out while contacting server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    String errorDetail = 'Server returned status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('detail')) {
        errorDetail = decoded['detail'].toString();
      }
    } catch (_) {}

    throw ApiException(errorDetail, response.statusCode);
  }

  void close() {
    _client.close();
  }
}
