import 'package:flutter/material.dart';
import '../models/ghazi_models.dart';
import '../screens/digital_pass_screen.dart';
import '../theme.dart';
import '../services/api_service.dart';

class TicketScreen extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onBackClick;

  const TicketScreen({
    super.key,
    required this.booking,
    this.onBackClick,
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  late Booking _currentBooking;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء حجز الدور الحالي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GhaziTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    final success = await ApiService.cancelBooking(_currentBooking.bookingId);

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الحجز بنجاح'),
          backgroundColor: GhaziTheme.orange,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhaziTheme.background,
      appBar: AppBar(
        title: const Text('تذكرة حجز الدور'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (widget.onBackClick != null) {
                widget.onBackClick!();
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // بطاقة التذكرة الرقمية بتصميم مميز
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // الجزء العلوي: المحطة والحالة
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: GhaziTheme.navy,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _currentBooking.stationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: GhaziTheme.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: GhaziTheme.orange, width: 1),
                          ),
                          child: Text(
                            'حالة التذكرة: ${_currentBooking.status}',
                            style: const TextStyle(
                              color: GhaziTheme.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // عرض رقم الدور
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Text(
                          'رقم دورك في الطابور',
                          style: TextStyle(
                            color: GhaziTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '#${_currentBooking.queueNumber}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: GhaziTheme.orange,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 18, color: GhaziTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'الانتظار التقديري: ~${_currentBooking.estimatedWaitMinutes} دقيقة',
                              style: const TextStyle(
                                fontSize: 13,
                                color: GhaziTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // خط فاصل مقصوص ليعطي شكل التذكرة
                  Row(
                    children: [
                      Container(
                        height: 20,
                        width: 10,
                        decoration: const BoxDecoration(
                          color: GhaziTheme.background,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(10)),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.constrainWidth() / 10).floor(),
                                (_) => const SizedBox(
                                  width: 5,
                                  height: 1.5,
                                  child: DecoratedBox(
                                    decoration:
                                        BoxDecoration(color: Color(0xFFE5E7EB)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 10,
                        decoration: const BoxDecoration(
                          color: GhaziTheme.background,
                          borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(10)),
                        ),
                      ),
                    ],
                  ),

                  // تفاصيل بيانات الحجز
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTicketRow(
                            'معرف الحجز', _currentBooking.bookingId),
                        const SizedBox(height: 10),
                        _buildTicketRow(
                            'اسم السائق', _currentBooking.driverName),
                        const SizedBox(height: 10),
                        _buildTicketRow(
                            'بيانات المركبة', _currentBooking.carDetails),
                        const SizedBox(height: 10),
                        _buildTicketRow(
                            'الكمية المطلوبة', _currentBooking.quantity),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // زر عرض رمز QR
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text('عرض رمز QR'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: GhaziTheme.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DigitalPassScreen(booking: _currentBooking),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // زر العودة للرئيسية
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: GhaziTheme.navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // زر إلغاء الحجز
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: GhaziTheme.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isCancelling ? null : _cancelBooking,
              child: _isCancelling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GhaziTheme.red),
                    )
                  : const Text(
                      'إلغاء الحجز',
                      style: TextStyle(
                          color: GhaziTheme.red, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: GhaziTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: GhaziTheme.navy,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
