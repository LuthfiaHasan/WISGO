import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Model standar pembungkus respon API WISGO
class ApiResponse<T> {
  final bool isSuccess;
  final String status;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ApiResponse.success({
    required String message,
    T? data,
    int statusCode = 200,
  }) {
    return ApiResponse(
      isSuccess: true,
      status: 'success',
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    required String message,
    int statusCode = 400,
    T? data,
  }) {
    return ApiResponse(
      isSuccess: false,
      status: 'error',
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiResponse(status: $status, statusCode: $statusCode, message: $message)';
}

/// Client HTTP Terpadu untuk menangani request, header JWT, timeout, dan decoding JSON
class ApiClient {
  /// Header HTTP standar aplikasi
  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (ApiConfig.authToken != null && ApiConfig.authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ApiConfig.authToken}';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  /// Membentuk URI lengkap beserta query parameters jika ada
  static Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    var fullUrl = '${ApiConfig.baseUrl}$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      fullUrl = '$fullUrl?$queryString';
    }
    return Uri.parse(fullUrl);
  }

  /// Request HTTP GET
  static Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders(headers))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Request HTTP POST
  static Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await http
          .post(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Request HTTP PUT
  static Future<ApiResponse<dynamic>> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await http
          .put(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Request HTTP DELETE
  static Future<ApiResponse<dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await http
          .delete(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Mengurai respon JSON seragam dari backend WISGO
  static ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      if (decoded is Map<String, dynamic>) {
        final status = decoded['status']?.toString() ?? (isSuccess ? 'success' : 'error');
        final message = decoded['message']?.toString() ?? 'Permintaan berhasil diproses';
        final data = decoded['data'];

        return ApiResponse(
          isSuccess: isSuccess,
          status: status,
          message: message,
          data: data,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        isSuccess: isSuccess,
        status: isSuccess ? 'success' : 'error',
        message: isSuccess ? 'Sukses' : 'Gagal',
        data: decoded,
        statusCode: response.statusCode,
      );
    } catch (_) {
      // Jika respon bukan JSON murni (misal HTML error)
      return ApiResponse.error(
        message: 'Respon server tidak valid (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  /// Penanganan error jaringan, offline, timeout, & soket
  static ApiResponse<dynamic> _handleError(dynamic error) {
    if (error is TimeoutException) {
      return ApiResponse.error(
        message: 'Waktu permintaan habis (Request Timeout). Silakan periksa koneksi internet Anda.',
        statusCode: 408,
      );
    }
    if (error is SocketException) {
      return ApiResponse.error(
        message: 'Tidak dapat terhubung ke server backend WISGO. Pastikan server aktif atau periksa koneksi Anda.',
        statusCode: 503,
      );
    }
    return ApiResponse.error(
      message: 'Terjadi kesalahan jaringan: ${error.toString()}',
      statusCode: 500,
    );
  }
}
