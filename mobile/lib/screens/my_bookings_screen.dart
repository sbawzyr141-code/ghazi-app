import 'package:flutter/material.dart';
import '../models/ghazi_models.dart';
import '../theme.dart';
import '../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  final String userPhone;
  final Function(Booking) onViewTicket;

  const MyBookingsScreen({
    super.key,
    required this.userPhone,
    required this.onViewTicket,
  });

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Booking> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await ApiService.getUserBookings(widget.userPhone);
      if (mounted) {
        setState(() {
          if (bookings.isNotEmpty) {
            _allBookings = bookings;
          } else {
            // إذا لم تعُد الخدمة بأي حجوزات، استخدم البيانات المحلية المؤقتة
            _allBookings = _getMockBookings();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allBookings = _getMockBookings();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Booking> _getMockBookings() {
    return [
      Booking(
        bookingId: 'BK-89341',
        stationName: 'محطة المكلا المركزية للغاز',
        queueNumber: 15,
        estimatedWaitMinutes: 20,
        driverName: 'سالم باوزير',
        carDetails: 'هايلوكس - 14520/حضرموت',
        quantity: '20 لتر',
        formattedDate: 'اليوم، 10:30 ص',
        phone: widget.userPhone,
        status: 'نشط',
      ),
      Booking(
        bookingId: 'BK-77210',
        stationName: 'محطة روكب لغاز السيارات',
        queueNumber: 6,
        estimatedWaitMinutes: 0,
        driverName: 'سالم باوزير',
        carDetails: 'هايلوكس - 14520/حضرموت',
        quantity: '25 لتر',
        formattedDate: 'أمس، 04:15 م',
        phone: widget.userPhone,
        status: 'مكتمل',
      ),
      Booking(
        bookingId: 'BK-65109',
        stationName: 'محطة فوة للغاز الطبيعي',
        queueNumber: 22,
        estimatedWaitMinutes: 0,
        driverName: 'سالم باوزير',
        carDetails: 'هايلوكس - 14520/حضرموت',
        quantity: '15 لتر',
        formattedDate: '3 أغسطس 2026',
        phone: widget.userPhone,
        status: 'ملغي',
      ),
    ];
  }

  List<Booking> get _activeBookings => _allBookings
      .where((b) => b.status == 'نشط' || b.status == 'قيد الانتظار')
      .toList();

  List<Booking> get _pastBookings => _allBookings
      .where((b) => b.status != 'نشط' && b.status != 'قيد الانتظار')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhaziTheme.background,
      appBar: AppBar(
        title: const Text('سجل حجوزاتي'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GhaziTheme.orange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'الحالية (${_activeBookings.length})'),
            Tab(text: 'السابقة (${_pastBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GhaziTheme.orange),
            )
          : RefreshIndicator(
              color: GhaziTheme.orange,
              onRefresh: _loadUserBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(_activeBookings, isActiveTab: true),
                  _buildBookingsList(_pastBookings, isActiveTab: false),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings,
      {required bool isActiveTab}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActiveTab
                  ? Icons.confirmation_number_outlined
                  : Icons.history_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isActiveTab
                  ? 'لا توجد حجوزات نشطة حالياً'
                  : 'لا يوجد سجل حجوزات سابقة',
              style: const TextStyle(
                color: GhaziTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isActiveTab);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, bool isActive) {
    Color statusBgColor;
    Color statusTextColor;

    switch (booking.status) {
      case 'نشط':
      case 'قيد الانتظار':
        statusBgColor = GhaziTheme.orange.withOpacity(0.12);
        statusTextColor = GhaziTheme.orange;
        break;
      case 'مكتمل':
        statusBgColor = GhaziTheme.greenLight;
        statusTextColor = GhaziTheme.green;
        break;
      default:
        statusBgColor = GhaziTheme.redLight;
        statusTextColor = GhaziTheme.red;
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? GhaziTheme.orange.withOpacity(0.4)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          widget.onViewTicket(booking);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان وحالة الحجز
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.stationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: GhaziTheme.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // رقم الدور والوقت
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GhaziTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#${booking.queueNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: GhaziTheme.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.carDetails,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GhaziTheme.navy,
                            ),
                          ),
                          Text(
                            'الكمية: ${booking.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: GhaziTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: GhaziTheme.textSecondary,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),

              // التاريخ والمعرف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: GhaziTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: GhaziTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    booking.bookingId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GhaziTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
