import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Backend base URL for the owner dashboard (Flutter Web).
/// Override at build/run time with:
///   flutter run -d chrome --dart-define=GHAZI_API_BASE_URL=https://ghazi-backend.onrender.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'GHAZI_API_BASE_URL',
    defaultValue: 'https://ghazi-backend.onrender.com',
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
        body['error']?.toString() ?? 'Request failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(_u('/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _decode(res);
  }

  Future<Station> getStation(String id) async {
    final res = await http.get(_u('/api/stations/$id'), headers: _headers);
    final data = _decode(res);
    return Station.fromJson(data['station']);
  }

  Future<Station> toggleStation(String id) async {
    final res =
        await http.patch(_u('/api/stations/$id/toggle'), headers: _headers);
    final data = _decode(res);
    return Station.fromJson(data['station']);
  }

  Future<List<Booking>> getStationQueue(String stationId) async {
    final res = await http.get(_u('/api/bookings/station/$stationId'),
        headers: _headers);
    final data = _decode(res);
    return (data['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> completeBooking(String bookingId) async {
    final res = await http.patch(_u('/api/bookings/$bookingId/complete'),
        headers: _headers);
    _decode(res);
  }

  Future<AdminStats> getAdminStats() async {
    final res = await http.get(_u('/api/admin/stats'), headers: _headers);
    final data = _decode(res);
    return AdminStats.fromJson(data['stats']);
  }
}
