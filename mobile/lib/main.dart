import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/ghazi_models.dart';
import 'services/api_service.dart';
import 'screens/booking_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/ticket_screen.dart';
import 'theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // initialize notifications and other services before starting the app
  await _initApp();
  // load persisted user info and connect socket if owner
  await ApiService.loadPersistedUser();
  runApp(const GhaziFlutterApp());
}

class GhaziFlutterApp extends StatelessWidget {
  const GhaziFlutterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'غازي',
      debugShowCheckedModeBanner: false,
      theme: GhaziTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'YE')],
      locale: const Locale('ar', 'YE'),
      home: const MainNavigationWrapper(),
    );
  }
}

// Initialize notifications on app start
Future<void> _initApp() async {
  await NotificationService.init();
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({Key? key}) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  GasStation? _selectedStation;
  Booking? _selectedBooking;
  String _currentUserPhone = '770000000';
  String? _currentUserRole; // 'driver' | 'station_owner'

  @override
  Widget build(BuildContext context) {
    Widget activeBody;

    switch (_currentIndex) {
      case 0:
        activeBody = HomeScreen(
          onSelectStation: (station) {
            setState(() {
              _selectedStation = station;
              _currentIndex = 4; // الانتقال إلى شاشة تفاصيل الحجز
            });
          },
        );
        break;
      case 1:
        activeBody = MyBookingsScreen(
          userPhone: _currentUserPhone,
          onViewTicket: (booking) {
            setState(() {
              _selectedBooking = booking;
              _currentUserPhone = booking.phone;
              _currentIndex = 5; // الانتقال إلى شاشة التذكرة
            });
          },
        );
        break;
      case 2:
        // Use worker dashboard when stations are available, otherwise show placeholder
        activeBody = ApiService.instance.stations.isNotEmpty
            ? WorkerDashboardScreen(station: ApiService.instance.stations.first)
            : const Scaffold(
                body: Center(child: Text('لا توجد محطات للوحة التحكم')));
        break;
      case 3:
        activeBody = LoginScreen(
          onNavigateToSignup: () {
            setState(() => _currentIndex = 6); // الانتقال إلى شاشة إنشاء الحساب
          },
          onLoginSuccess: () async {
            // detect role and navigate accordingly
            final user = await ApiService.getUser(phone: _currentUserPhone);
            final role = user?['role'] ?? 'driver';
            setState(() {
              _currentUserRole = role;
              if (role == 'station_owner') {
                _currentIndex = 2; // open dashboard for owners
              } else {
                _currentIndex = 0; // normal driver home
              }
            });
          },
        );
        break;
      case 4:
        activeBody = BookingScreen(
          station: _selectedStation!,
          onBackClick: () => setState(() => _currentIndex = 0),
          onBookingCreatedSuccess: (booking) {
            setState(() {
              _selectedBooking = booking;
              _currentUserPhone = booking.phone;
              _currentIndex = 5;
            });
          },
        );
        break;
      case 5:
        activeBody = TicketScreen(
          booking: _selectedBooking!,
          onBackClick: () => setState(() => _currentIndex = 0),
        );
        break;
      case 6:
        activeBody = SignupScreen(
          onNavigateToLogin: () {
            setState(() => _currentIndex = 3); // العودة إلى شاشة تسجيل الدخول
          },
          onSignupSuccess: () => setState(() => _currentIndex = 0),
        );
        break;
      default:
        activeBody = HomeScreen(onSelectStation: (_) {});
    }

    // إظهار الشريط السفلي فقط في الشاشات الرئيسية الأربع الأولى
    final showBottomBar =
        _currentIndex <= 3 && _currentUserRole != 'station_owner';

    return Scaffold(
      body: activeBody,
      bottomNavigationBar: showBottomBar
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: GhaziTheme.orange,
              unselectedItemColor: GhaziTheme.navy,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_gas_station),
                  label: 'المحطات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number),
                  label: 'حجوزاتي',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'لوحة المحطة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'حسابي',
                ),
              ],
            )
          : null,
    );
  }
}
