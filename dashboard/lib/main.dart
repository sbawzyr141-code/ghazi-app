import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'screens/owner_login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const GhaziDashboardApp());
}

class GhaziDashboardApp extends StatelessWidget {
  const GhaziDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'غازي - لوحة صاحب المحطة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const DashboardRoot(),
    );
  }
}

class DashboardRoot extends StatefulWidget {
  const DashboardRoot({super.key});

  @override
  State<DashboardRoot> createState() => _DashboardRootState();
}

class _DashboardRootState extends State<DashboardRoot> {
  final ApiService api = ApiService();
  AppUser? owner;

  void _onAuthenticated(String token, AppUser user) {
    api.setToken(token);
    setState(() => owner = user);
  }

  void _logout() {
    api.setToken(null);
    setState(() => owner = null);
  }

  @override
  Widget build(BuildContext context) {
    if (owner == null || owner!.stationId == null) {
      return OwnerLoginScreen(api: api, onAuthenticated: _onAuthenticated);
    }
    return DashboardScreen(api: api, owner: owner!, onLogout: _logout);
  }
}