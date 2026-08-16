import 'package:flutter/material.dart';
import '../models/ghazi_models.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final GasStation station;

  const WorkerDashboardScreen({
    super.key,
    required this.station,
  });

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  late bool _isOpen;
  late int _queueCount;
  int _currentServingNumber = 14; // رقم الدور الذي تتم خدمته حالياً
  bool _isProcessing = false;
  // QR scanner active flag
  bool _scannerVisible = false;

  // قائمة نموذجية للسيارات المنتظرة في الطابور
  List<Map<String, dynamic>> _waitingQueue = [
    {
      'ticketNumber': 15,
      'driverName': 'سالم باوزير',
      'carPlate': '14520/حضرموت',
      'carModel': 'هايلوكس',
      'quantity': '20 لتر',
      'time': 'منذ 5 د',
    },
    {
      'ticketNumber': 16,
      'driverName': 'أحمد بن علي',
      'carPlate': '8842/حضرموت',
      'carModel': 'كورولا',
      'quantity': 'فل (تعبئة كاملة)',
      'time': 'منذ 8 د',
    },
    {
      'ticketNumber': 17,
      'driverName': 'محمد باحشوان',
      'carPlate': '3021/حضرموت',
      'carModel': 'برادو',
      'quantity': '25 لتر',
      'time': 'منذ 12 د',
    },
    {
      'ticketNumber': 18,
      'driverName': 'سعيد العامري',
      'carPlate': '5519/حضرموت',
      'carModel': 'سنتافي',
      'quantity': '15 لتر',
      'time': 'منذ 15 د',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isOpen = widget.station.isOpen;
    _queueCount = widget.station.currentQueueCount > 0
        ? widget.station.currentQueueCount
        : _waitingQueue.length;
  }

  // تمرير الدور وخدمة السيارة التالية
  Future<void> _serveNextCar() async {
    if (_waitingQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد سيارات إضافية في قائمة الانتظار حالياً'),
          backgroundColor: GhaziTheme.navy,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await ApiService.serveNextCar(widget.station.id);

      if (success && mounted) {
        final servedCar = _waitingQueue.removeAt(0);
        setState(() {
          _currentServingNumber = servedCar['ticketNumber'];
          if (_queueCount > 0) _queueCount--;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استدعاء الدور #${servedCar['ticketNumber']} (${servedCar['driverName']})',
            ),
            backgroundColor: GhaziTheme.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث الدور: $e'),
            backgroundColor: GhaziTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhaziTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'لوحة تحكم مشغّل المحطة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.station.name,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث بيانات الطابور'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة التحكم في حالة المحطة
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor:
                              _isOpen ? GhaziTheme.green : GhaziTheme.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOpen
                              ? 'المحطة تستقبل السيارات'
                              : 'المحطة متوقفة مؤقتاً',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isOpen ? GhaziTheme.navy : GhaziTheme.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOpen,
                      activeColor: GhaziTheme.green,
                      onChanged: (val) {
                        setState(() => _isOpen = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // البطاقة الرئيسية: الدور الحالي وزر النداء
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GhaziTheme.navy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: GhaziTheme.navy.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Replace current serving box with QR scanner toggle
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: Colors.white,
                            foregroundColor: GhaziTheme.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, color: GhaziTheme.navy),
                          label: const Text('فتح ماسح الـ QR'),
                          onPressed: () => setState(() => _scannerVisible = !_scannerVisible),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GhaziTheme.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(120, 52),
                        ),
                        onPressed: _isProcessing ? null : _serveNextCar,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('نداء التالية', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_scannerVisible)
                    SizedBox(
                      height: 360,
                      child: MobileScanner(
                        allowDuplicates: false,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isEmpty) return;
                          final code = barcodes.first.rawValue ?? '';
                          if (code.isEmpty) return;
                          // treat code as booking id
                          setState(() => _scannerVisible = false);
                          final success = await ApiService.completeBooking(code);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إنهاء التذكرة وتحديث الطابور'), backgroundColor: GhaziTheme.green),
                            );
                            // Update local queue
                            if (_queueCount > 0) setState(() => _queueCount--);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشل إنهاء التذكرة'), backgroundColor: GhaziTheme.red),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // عنوان قائمة الطابور الحية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة الانتظار الحية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GhaziTheme.navy,
                  ),
                ),
                Text(
                  '${_waitingQueue.length} سيارة متبقية',
                  style: const TextStyle(
                    fontSize: 13,
                    color: GhaziTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // عرض عناصر الطابور
            if (_waitingQueue.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      color: GhaziTheme.green,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'تم الانتهاء من جميع السيارات في الطابور!',
                      style: TextStyle(
                        color: GhaziTheme.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _waitingQueue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final car = _waitingQueue[index];
                  final isNext = index == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isNext
                            ? GhaziTheme.orange
                            : const Color(0xFFE5E7EB),
                        width: isNext ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isNext
                              ? GhaziTheme.orange.withOpacity(0.12)
                              : GhaziTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#${car['ticketNumber']}',
                          style: TextStyle(
                            color: isNext ? GhaziTheme.orange : GhaziTheme.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        '${car['driverName']} • ${car['carModel']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: GhaziTheme.navy,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'لوحة: ${car['carPlate']} | طلب: ${car['quantity']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: GhaziTheme.textSecondary,
                          ),
                        ),
                      ),
                      trailing: isNext
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GhaziTheme.greenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'التالي',
                                style: TextStyle(
                                  color: GhaziTheme.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              car['time'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: GhaziTheme.textSecondary,
                              ),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
