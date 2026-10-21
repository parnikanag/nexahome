import 'dart:convert';
import 'package:http/http.dart' as http;

// No service account key or database secret is ever embedded in the app.
// Firebase email/password authentication -> short-lived ID token -> RTDB REST.
class CloudClient {
  CloudClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();
  final http.Client _http;
  String apiKey = '';
  String databaseUrl = '';
  String homeId = 'demo-home';
  String? email;
  String? uid;
  String? _idToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool get signedIn => _idToken != null;
  bool get configured =>
      apiKey.isNotEmpty && databaseUrl.isNotEmpty && homeId.isNotEmpty;

  void configure(
      {required String key, required String url, required String home}) {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
      throw FormatException('Database URL must start with https://');
    }
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(home.trim())) {
      throw FormatException(
          'Home ID can contain only letters, numbers, _ and -');
    }
    apiKey = key.trim();
    databaseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    homeId = home.trim();
    signOut();
  }

  void signOut() {
    _idToken = null;
    _refreshToken = null;
    _expiresAt = null;
    uid = null;
    email = null;
  }

  Future<void> signIn(String loginEmail, String password) async {
    if (!configured) throw StateError('Save Firebase settings first.');
    final uri = Uri.https('identitytoolkit.googleapis.com',
        '/v1/accounts:signInWithPassword', {'key': apiKey});
    final resp = await _http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': loginEmail.trim(),
              'password': password,
              'returnSecureToken': true,
            }))
        .timeout(const Duration(seconds: 15));
    final obj = _decode(resp);
    if (obj is! Map)
      throw FormatException('Unexpected Firebase sign-in response');
    _idToken = obj['idToken'] as String?;
    _refreshToken = obj['refreshToken'] as String?;
    uid = obj['localId'] as String?;
    email = loginEmail.trim();
    final expiresIn = int.tryParse('${obj['expiresIn']}') ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 90));
    if (_idToken == null || _refreshToken == null) {
      throw StateError('Missing authentication token.');
    }
  }

  Future<String> _validToken() async {
    if (!signedIn)
      throw StateError('Sign in to Firebase to control real hardware.');
    if (_expiresAt != null && DateTime.now().isBefore(_expiresAt!))
      return _idToken!;
    final uri =
        Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey});
    final resp = await _http.post(uri, body: {
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken!,
    }).timeout(const Duration(seconds: 15));
    final obj = _decode(resp);
    if (obj is! Map)
      throw FormatException('Unexpected Firebase refresh response');
    _idToken = obj['id_token'] as String?;
    _refreshToken = (obj['refresh_token'] as String?) ?? _refreshToken;
    final expiresIn = int.tryParse('${obj['expires_in']}') ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 90));
    if (_idToken == null) throw StateError('Session expired, sign in again.');
    return _idToken!;
  }

  dynamic _decode(http.Response response) {
    dynamic obj;
    try {
      obj = jsonDecode(response.body);
    } catch (_) {
      obj = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'HTTP ${response.statusCode}';
      if (obj is Map && obj['error'] is Map) {
        detail = '${(obj['error'] as Map)['message'] ?? detail}';
      } else if (obj is Map && obj['error'] != null) {
        detail = '${obj['error']}';
      }
      throw StateError('Firebase request failed: $detail');
    }
    return obj;
  }

  Future<dynamic> _database(String path,
      {dynamic value, bool write = false}) async {
    final token = await _validToken();
    final fullPath = path.isEmpty ? 'homes/$homeId' : 'homes/$homeId/$path';
    final uri = Uri.parse('$databaseUrl/$fullPath.json')
        .replace(queryParameters: {'auth': token});
    final response = write
        ? await _http
            .put(uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(value))
            .timeout(const Duration(seconds: 15))
        : await _http.get(uri).timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<Map<String, dynamic>> fetchHome() async {
    final value = await _database('');
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<void> sendCommand(String key, dynamic value) async {
    const allowed = {'lamp', 'ac_mode', 'geyser', 'door_open'};
    if (!allowed.contains(key)) {
      throw ArgumentError('Unknown hardware command $key');
    }
    if (key == 'ac_mode') {
      if (value is! String ||
          !const {'OFF', 'LOW', 'MEDIUM', 'HIGH'}.contains(value)) {
        throw ArgumentError('AC mode must be OFF, LOW, MEDIUM or HIGH.');
      }
    } else if (value is! bool) {
      throw ArgumentError('$key command must be a boolean.');
    }
    await _database('commands/$key', value: value, write: true);
  }

  void dispose() => _http.close();
}
