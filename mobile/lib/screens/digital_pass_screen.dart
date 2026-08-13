import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ghazi_models.dart';
import '../theme.dart';

/// The driver's "digital pass" — QR code + queue number shown at the pump.
class DigitalPassScreen extends StatelessWidget {
  final Booking booking;

  const DigitalPassScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تذكرة الحجز')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(booking.stationName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('تم الحجز بنجاح',
                      style: TextStyle(color: GhaziTheme.green, fontSize: 13)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: booking.bookingId,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('رقم دورك',
                      style: TextStyle(color: GhaziTheme.textSecondary)),
                  Text('#${booking.queueNumber}',
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: GhaziTheme.orange)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GhaziTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'يرجى إبراز هذا الرمز للموظف عند الوصول إلى المحطة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: GhaziTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
