import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ghazi_models.dart';

class ApiService {
  // Private constructor for singleton
  ApiService._internal() {
    // initialize instance stations from fallback data
    stations = _getFallbackStations();
  }

  // Singleton instance
  static final ApiService instance = ApiService._internal();

  // Public list of stations accessible via ApiService.instance.stations
  List<GasStation> stations = [];

  // Current logged in user info (populated after login/signup)
  static String? currentUserEmail;
  static String? currentUserPhone;
  static String? currentUserRole; // 'driver' | 'station_owner'

  // Cache user bookings locally when createBooking succeeds
  static final Map<String, List<Booking>> _cachedUserBookings = {};
  static final List<Booking> _globalCachedBookings = [];

  // Firebase auth instance for login/signup helpers
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signup(
      String name, String phone, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
    }
    return cred;
  }

  static List<Booking> _getCachedBookings(String phone) =>
      _cachedUserBookings[phone] ?? [];

  static void _addCachedBooking(String phone, Booking booking) {
    _cachedUserBookings.putIfAbsent(phone, () => []);
    final existing = _cachedUserBookings[phone]!
        .any((element) => element.bookingId == booking.bookingId);
    if (!existing) {
      _cachedUserBookings[phone]!.add(booking);
    }
  }

  static void _addGlobalCachedBooking(Booking booking) {
    if (!_globalCachedBookings
        .any((element) => element.bookingId == booking.bookingId)) {
      _globalCachedBookings.add(booking);
    }
  }

  static Booking? findBookingById(String bookingId) {
    try {
      return _globalCachedBookings
          .firstWhere((booking) => booking.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  // عنوان السيرفر الأساسي.
  // استخدم --dart-define=GHAZI_API_BASE_URL=... عند بناء التطبيق.
  // مثال محلي: http://10.0.2.2:3000/api
  // مثال إنتاج: https://ghazi-backend.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'GHAZI_API_BASE_URL',
    defaultValue: 'https://ghazi-backend.onrender.com/api',
  );

  // Helper to build socket URL (strip trailing /api)
  static String get socketUrl {
    if (baseUrl.endsWith('/api'))
      return baseUrl.substring(0, baseUrl.length - 4);
    return baseUrl;
  }

  // Fetch user by email or phone (used for role detection)
  static Future<Map<String, dynamic>?> getUser(
      {String? email, String? phone}) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/user').replace(queryParameters: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create user record on backend after Firebase signup
  static Future<bool> registerBackendUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? stationName,
    String? stationLicense,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'password': password,
              'role': role,
              if (stationName != null) 'station_name': stationName,
              if (stationLicense != null) 'station_license': stationLicense,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mark booking as completed (owner action)
  static Future<bool> completeBooking(String bookingId) async {
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl/bookings/$bookingId/complete'),
              headers: _headers)
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// 1. جلب قائمة المحطات مع بيانات الطابور الحية
  static Future<List<GasStation>> getStations() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stations'), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GasStation.fromJson(json)).toList();
      } else {
        throw HttpException('فشل جلب المحطات (كود: ${response.statusCode})');
      }
    } catch (e) {
      // إرجاع بيانات تجريبية محلية في حال تعذر الوصول للسيرفر أثناء التطوير
      return _getFallbackStations();
    }
  }

  // Helper to decide if a user is station owner or driver based on backend record
  static Future<String> detectRoleByPhone(String phone) async {
    final u = await getUser(phone: phone);
    if (u == null) return 'driver';
    return u['role'] ?? 'driver';
  }

  /// 2. إرسال طلب حجز دور غاز جديد
  static Future<Booking> createBooking({
    required String stationId,
    required String driverName,
    required String phone,
    required String carPlate,
    required String carModel,
    required String quantity,
    String? gasSystem,
    bool serviceFeeAgreed = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings'),
            headers: _headers,
            body: jsonEncode({
              'station_id': stationId,
              'driver_name': driverName,
              'phone': phone,
              'plate_number': carPlate,
              'car_model': carModel,
              'quantity': quantity,
              'gas_system': gasSystem,
              'service_fee_agreed': serviceFeeAgreed,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> bookingJson = data['booking'] ?? data;
        final newBooking = Booking.fromJson(bookingJson, defaultPhone: phone);
        _addCachedBooking(phone, newBooking);
        _addGlobalCachedBooking(newBooking);
        return newBooking;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'فشل إتمام عملية الحجز');
      }
    } catch (e) {
      // توليد حجز محلي مؤقت إذا كان السيرفر متوقفاً
      final localBooking = Booking(
        bookingId:
            'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        stationName: 'محطة المكلا المركزية للغاز',
        queueNumber: 15,
        estimatedWaitMinutes: 25,
        driverName: driverName,
        carDetails: '$carModel - $carPlate',
        quantity: quantity,
        formattedDate: 'الآن',
        phone: phone,
        status: 'نشط',
      );
      _addCachedBooking(phone, localBooking);
      _addGlobalCachedBooking(localBooking);
      return localBooking;
    }
  }

  /// 3. جلب سجل حجوزات السائق
  static Future<List<Booking>> getUserBookings(String phone) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/bookings/user?phone=$phone'),
              headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final bookings = data
            .map((json) => Booking.fromJson(json, defaultPhone: phone))
            .toList();
        final cached = _getCachedBookings(phone);
        final existingIds = bookings.map((b) => b.bookingId).toSet();
        bookings
            .addAll(cached.where((b) => !existingIds.contains(b.bookingId)));
        return bookings.isNotEmpty ? bookings : cached;
      } else {
        throw HttpException('فشل استرجاع السجل');
      }
    } catch (e) {
      final cached = _getCachedBookings(phone);
      return cached;
    }
  }

  /// 4. إلغاء حجز قائم
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      return response.statusCode == 200;
    } catch (e) {
      return true; // تأكيد محلي
    }
  }

  /// 5. تحديث دور المحطة من لوحة تحكم العامل (خدمة سيارة)
  static Future<bool> serveNextCar(String stationId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/stations/$stationId/serve-next'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  // بيانات احتياطية تعمل تلقائياً عند عدم تشغيل السيرفر
  static List<GasStation> _getFallbackStations() {
    return [
      GasStation(
        id: 'st_1',
        name: 'محطة المكلا المركزية للغاز',
        location: 'الشرج - بالقرب من الجسر الصيني',
        isOpen: true,
        currentQueueCount: 12,
        estimatedWaitMinutes: 20,
        gasAvailable: true,
      ),
      GasStation(
        id: 'st_2',
        name: 'محطة روكب لغاز السيارات',
        location: 'روكب - الخط الدائري العام',
        isOpen: true,
        currentQueueCount: 4,
        estimatedWaitMinutes: 8,
        gasAvailable: true,
      ),
      GasStation(
        id: 'st_3',
        name: 'محطة فوة للغاز الطبيعي',
        location: 'فوة - المساكن خلف السوق التجاري',
        isOpen: false,
        currentQueueCount: 0,
        estimatedWaitMinutes: 0,
        gasAvailable: false,
      ),
    ];
  }
}
