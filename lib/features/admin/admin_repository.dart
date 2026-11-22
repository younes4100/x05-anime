import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/environment.dart';

/// An authenticated admin session. The token lives only in memory: nothing is
/// written to disk, and the app's normal Supabase session is never replaced.
class AdminSession {
  const AdminSession({required this.token, required this.email});

  final String token;
  final String email;
}

class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to Supabase Auth/PostgREST directly with the PUBLIC publishable key.
///
/// Authorization is enforced server-side by the `admin_emails` allowlist and
/// the `is_admin()` RPC from `web/admin/schema.sql`; no admin email list and no
/// secret key is bundled in the app.
class AdminRepository {
  AdminRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _tokenUri => Uri.parse(
    '${Environment.supabaseUrl}/auth/v1/token?grant_type=password',
  );

  Uri _rpcUri(String name) => Uri.parse(
    '${Environment.supabaseUrl}/rest/v1/rpc/$name',
  );

  Uri _tableUri(String table, {String query = 'select=*'}) => Uri.parse(
    '${Environment.supabaseUrl}/rest/v1/$table?$query',
  );

  Map<String, String> _headers(String? token) => <String, String>{
    'apikey': Environment.supabaseAnonKey,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<AdminSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _tokenUri,
      headers: _headers(null),
      body: jsonEncode(<String, String>{
        'email': email.trim(),
        'password': password,
      }),
    );
    _check(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AdminException('auth_failed');
    }
    if (!await isAdmin(token)) {
      throw const AdminException('not_admin');
    }
    final user = data['user'] as Map<String, dynamic>?;
    return AdminSession(
      token: token,
      email: (user?['email'] as String?) ?? email.trim(),
    );
  }

  Future<bool> isAdmin(String token) async {
    final response = await _client.post(
      _rpcUri('is_admin'),
      headers: _headers(token),
      body: '{}',
    );
    _check(response);
    return jsonDecode(response.body) == true;
  }

  Future<Map<String, dynamic>> stats(String token) async {
    final response = await _client.post(
      _rpcUri('admin_dashboard_stats'),
      headers: _headers(token),
      body: '{}',
    );
    _check(response);
    final data = jsonDecode(response.body);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> listUsers(String token) =>
      _rpcRows('admin_list_users', token);

  Future<List<Map<String, dynamic>>> select(
    String table,
    String token, {
    String order = 'created_at.desc',
  }) async {
    final response = await _client.get(
      _tableUri(table, query: 'select=*&order=$order'),
      headers: _headers(token),
    );
    _check(response);
    return _rows(jsonDecode(response.body));
  }

  Future<void> insert(
    String table,
    String token,
    Map<String, dynamic> row,
  ) async {
    final response = await _client.post(
      _tableUri(table),
      headers: _headers(token),
      body: jsonEncode(row),
    );
    _check(response);
  }

  Future<void> update(
    String table,
    String token,
    String id,
    Map<String, dynamic> patch, {
    String column = 'id',
  }) async {
    final response = await _client.patch(
      _tableUri(table, query: '$column=eq.$id'),
      headers: _headers(token),
      body: jsonEncode(patch),
    );
    _check(response);
  }

  Future<void> delete(
    String table,
    String token,
    String id, {
    String column = 'id',
  }) async {
    final response = await _client.delete(
      _tableUri(table, query: '$column=eq.$id'),
      headers: _headers(token),
    );
    _check(response);
  }

  Future<List<Map<String, dynamic>>> _rpcRows(String name, String token) async {
    final response = await _client.post(
      _rpcUri(name),
      headers: _headers(token),
      body: '{}',
    );
    _check(response);
    return _rows(jsonDecode(response.body));
  }

  List<Map<String, dynamic>> _rows(dynamic decoded) {
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = 'http_${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        message = (body['msg'] ?? body['message'] ?? body['error_code'] ?? message)
            .toString();
      }
    } catch (_) {
      // Keep the HTTP status as the fallback.
    }
    throw AdminException(message);
  }
}
