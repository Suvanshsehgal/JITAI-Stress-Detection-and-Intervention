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
  String baseUrl;
  final List<String> _candidateUrls;
  final http.Client _client;
  String? _authToken;
  final Duration timeoutDuration;

  ApiClient({
    String? baseUrl,
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 8),
  })  : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _candidateUrls = _buildCandidateUrls(baseUrl),
        _client = client ?? http.Client();

  static List<String> _buildCandidateUrls(String? customUrl) {
    if (customUrl != null && customUrl.isNotEmpty) {
      return [customUrl];
    }
    if (Platform.isAndroid) {
      // 127.0.0.1:8000 works on physical Android with adb reverse
      // 10.0.2.2:8000 works on Android Emulator host loopback
      // localhost:8000 fallback
      return [
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
        'http://localhost:8000',
      ];
    }
    return [
      'http://127.0.0.1:8000',
      'http://localhost:8000',
    ];
  }

  static String _defaultBaseUrl() {
    return _buildCandidateUrls(null).first;
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
    // Try current baseUrl, if it fails try alternate candidates
    final urlsToTry = [baseUrl, ..._candidateUrls.where((u) => u != baseUrl)];
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final currentCandidate = urlsToTry[i];
      final uri = Uri.parse('$currentCandidate$endpoint');
      try {
        final response = await _client.get(uri, headers: _headers()).timeout(timeoutDuration);
        baseUrl = currentCandidate; // Lock into working candidate
        return _handleResponse(response);
      } on SocketException catch (_) {
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Unable to reach backend server. Please verify backend is running on port 8000.');
        }
      } on TimeoutException catch (_) {
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Request timed out while contacting server.');
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Network error: $e');
        }
      }
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final urlsToTry = [baseUrl, ..._candidateUrls.where((u) => u != baseUrl)];

    for (int i = 0; i < urlsToTry.length; i++) {
      final currentCandidate = urlsToTry[i];
      final uri = Uri.parse('$currentCandidate$endpoint');
      try {
        final response = await _client
            .post(uri, headers: _headers(), body: jsonEncode(body))
            .timeout(timeoutDuration);
        baseUrl = currentCandidate; // Lock into working candidate
        return _handleResponse(response);
      } on SocketException catch (_) {
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Unable to reach backend server. Please verify backend is running on port 8000.');
        }
      } on TimeoutException catch (_) {
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Request timed out while contacting server.');
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        if (i == urlsToTry.length - 1) {
          throw NetworkException('Network error: $e');
        }
      }
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
