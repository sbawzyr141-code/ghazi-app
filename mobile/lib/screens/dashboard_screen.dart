import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import '../models/ghazi_models.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final GasStation station;

  const WorkerDashboardScreen({Key? key, required this.station})
      : super(key: key);

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  late bool _isOpen;
  late int _queueCount;
  int _currentServingNumber = 0;
  bool _isProcessing = false;
  bool _scannerVisible = false;

  final List<Map<String, dynamic>> _waitingQueue = [];

  @override
  void initState() {
    super.initState();
    _isOpen = widget.station.isOpen;
    _queueCount = widget.station.currentQueueCount;
    // connect to socket for live updates
    try {
      SocketService.instance.connect(ApiService.socketUrl);
      SocketService.instance.joinStation(widget.station.id);
      SocketService.instance.onQueueUpdate.listen((payload) {
        if (!mounted) return;
        final newCount = payload['queue_count'] as int? ?? _queueCount;
        setState(() => _queueCount = newCount);
        // notify operator when 3 cars left
        if (newCount <= 3) {
          NotificationService.showNotification(
              id: 1001,
              title: 'تنبيه الطابور',
              body: 'تبقى $newCount سيارات فقط في الطابور');
        }
      });
      SocketService.instance.onStationUpdate.listen((payload) {
        if (!mounted) return;
        // handle any station metadata updates
      });
    } catch (_) {}
  }

  Future<void> _serveNextCar() async {
    if (_waitingQueue.isEmpty && _queueCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لا توجد سيارات إضافية في قائمة الانتظار حالياً'),
      ));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final success = await ApiService.serveNextCar(widget.station.id);
      if (success && mounted) {
        if (_waitingQueue.isNotEmpty) {
          final served = _waitingQueue.removeAt(0);
          _currentServingNumber =
              served['ticketNumber'] ?? _currentServingNumber;
        }
        if (_queueCount > 0) _queueCount--;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم استدعاء السيارة التالية'),
          backgroundColor: GhaziTheme.green,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ عند نداء السيارة التالية: $e'),
        backgroundColor: GhaziTheme.red,
      ));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _onQrScanned(String code) async {
    setState(() => _scannerVisible = false);
    final success = await ApiService.completeBooking(code);
    if (!mounted) return;
    if (success) {
      if (_queueCount > 0) setState(() => _queueCount--);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إنهاء التذكرة وتحديث الطابور'),
        backgroundColor: GhaziTheme.green,
      ));
      // play local notification to confirm scan
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'تذكرة مكتملة',
        body: 'تم إنهاء التذكرة وتحديث الطابور بنجاح',
      );
      // play a short sound to confirm
      try {
        FlutterRingtonePlayer.playNotification();
      } catch (_) {}
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('فشل إنهاء التذكرة'),
        backgroundColor: GhaziTheme.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhaziTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('لوحة تحكم مشغّل المحطة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.station.name,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث بيانات الطابور')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      CircleAvatar(
                          radius: 6,
                          backgroundColor:
                              _isOpen ? GhaziTheme.green : GhaziTheme.red),
                      const SizedBox(width: 8),
                      Text(
                          _isOpen
                              ? 'المحطة تستقبل السيارات'
                              : 'المحطة متوقفة مؤقتاً',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isOpen ? GhaziTheme.navy : GhaziTheme.red,
                              fontSize: 14)),
                    ]),
                    Switch(
                        value: _isOpen,
                        activeColor: GhaziTheme.green,
                        onChanged: (v) => setState(() => _isOpen = v)),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: GhaziTheme.navy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: GhaziTheme.navy.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Colors.white,
                        foregroundColor: GhaziTheme.navy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.qr_code_scanner,
                        color: GhaziTheme.navy),
                    label: const Text('فتح ماسح الـ QR'),
                    onPressed: () =>
                        setState(() => _scannerVisible = !_scannerVisible),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GhaziTheme.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(120, 52)),
                  onPressed: _isProcessing ? null : _serveNextCar,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('نداء التالية',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 12),
              if (_scannerVisible)
                SizedBox(
                  height: 360,
                  child: kIsWeb
                      ? _WebQrFallback(onSubmit: (code) => _onQrScanned(code))
                      : MobileScanner(
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) return;
                            final code = barcodes.first.rawValue ?? '';
                            if (code.isEmpty) return;
                            _onQrScanned(code);
                          },
                        ),
                ),
            ]),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('قائمة الانتظار الحية',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GhaziTheme.navy)),
            Text('$_queueCount سيارة متبقية',
                style: const TextStyle(
                    fontSize: 13, color: GhaziTheme.textSecondary)),
          ]),
          const SizedBox(height: 12),
          if (_waitingQueue.isEmpty)
            Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  Icon(Icons.done_all_rounded,
                      color: GhaziTheme.green, size: 48),
                  SizedBox(height: 12),
                  Text('تم الانتهاء من جميع السيارات في الطابور!',
                      style: TextStyle(
                          color: GhaziTheme.navy, fontWeight: FontWeight.bold))
                ]))
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
                          width: isNext ? 1.5 : 1)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: isNext
                                ? GhaziTheme.orange.withOpacity(0.12)
                                : GhaziTheme.background,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('#${car['ticketNumber']}',
                            style: TextStyle(
                                color: isNext
                                    ? GhaziTheme.orange
                                    : GhaziTheme.navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),
                    title: Text('${car['driverName']} • ${car['carModel']}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GhaziTheme.navy)),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            'لوحة: ${car['carPlate']} | طلب: ${car['quantity']}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: GhaziTheme.textSecondary))),
                    trailing: isNext
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: GhaziTheme.greenLight,
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('التالي',
                                style: TextStyle(
                                    color: GhaziTheme.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)))
                        : Text(car['time'],
                            style: const TextStyle(
                                fontSize: 11, color: GhaziTheme.textSecondary)),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}

// Simple web fallback widget for entering QR code manually
class _WebQrFallback extends StatefulWidget {
  final void Function(String code) onSubmit;
  const _WebQrFallback({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<_WebQrFallback> createState() => _WebQrFallbackState();
}

class _WebQrFallbackState extends State<_WebQrFallback> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Web: أدخل رمز التذكرة يدوياً للاختبار'),
          const SizedBox(height: 8),
          TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'معرف الحجز')),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () => widget.onSubmit(_controller.text.trim()),
              child: const Text('تأكيد'))
        ],
      ),
    );
  }
}
