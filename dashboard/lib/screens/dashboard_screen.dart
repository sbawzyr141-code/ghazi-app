import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/models.dart';
import '../theme.dart';
import 'qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService api;
  final AppUser owner;
  final VoidCallback onLogout;

  const DashboardScreen(
      {super.key,
      required this.api,
      required this.owner,
      required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SocketService socket = SocketService();
  Station? station;
  List<Booking> queue = [];
  bool _loading = true;
  bool _togglingAvailability = false;
  String? _error;

  String get stationId => widget.owner.stationId!;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadAdminStats();
    socket.joinStation(stationId);
    socket.onStationUpdate((data) {
      if (!mounted) return;
      setState(
          () => station = Station.fromJson(Map<String, dynamic>.from(data)));
    });
    socket.onQueueUpdate((_) {
      if (!mounted) return;
      _loadQueue();
    });
  }

  @override
  void dispose() {
    socket.leaveStation(stationId);
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await widget.api.getStation(stationId);
      final q = await widget.api.getStationQueue(stationId);
      setState(() {
        station = s;
        queue = q;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadQueue() async {
    try {
      final q = await widget.api.getStationQueue(stationId);
      if (mounted) setState(() => queue = q);
    } catch (_) {}
  }

  Future<void> _toggleAvailability() async {
    setState(() => _togglingAvailability = true);
    try {
      final s = await widget.api.toggleStation(stationId);
      setState(() => station = s);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  AdminStats? _adminStats;

  Future<void> _completeBooking(Booking b) async {
    try {
      await widget.api.completeBooking(b.id);
      _loadQueue();
      _loadAdminStats();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadAdminStats() async {
    try {
      final stats = await widget.api.getAdminStats();
      if (mounted) setState(() => _adminStats = stats);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
          body: Center(
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger))));
    }

    final s = station!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.nameAr),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    QrScannerScreen(api: widget.api, stationId: stationId),
              ));
              _loadQueue();
            },
            icon: const Icon(Icons.qr_code_scanner,
                color: AppColors.primaryDeepNavy),
            label: const Text('محاكي فحص QR',
                style: TextStyle(color: AppColors.primaryDeepNavy)),
          ),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: widget.onLogout),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AvailabilityCard(
              isAvailable: s.isAvailable,
              loading: _togglingAvailability,
              onToggle: _toggleAvailability,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'في الطابور الآن',
                    value: '${s.queueCount}',
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.confirmation_number_rounded,
                    label: 'إجمالي الحجوزات النشطة',
                    value: '${queue.length}',
                    color: AppColors.primaryDeepNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('الحجوزات النشطة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_adminStats != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إحصائيات المدير',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        icon: Icons.person,
                        label: 'عدد السائقين',
                        value: '${_adminStats!.totalDrivers}',
                        color: AppColors.primaryDeepNavy,
                      ),
                      _StatCard(
                        icon: Icons.person_outline,
                        label: 'عدد المشغلين',
                        value: '${_adminStats!.totalOwners}',
                        color: AppColors.accentOrange,
                      ),
                      _StatCard(
                        icon: Icons.local_gas_station,
                        label: 'عدد المحطات',
                        value: '${_adminStats!.totalStations}',
                        color: AppColors.success,
                      ),
                      _StatCard(
                        icon: Icons.confirmation_number,
                        label: 'الحجوزات الإجمالية',
                        value: '${_adminStats!.totalBookings}',
                        color: AppColors.primaryDeepNavy,
                      ),
                      _StatCard(
                        icon: Icons.pending,
                        label: 'الحجوزات النشطة',
                        value: '${_adminStats!.activeBookings}',
                        color: AppColors.danger,
                      ),
                      _StatCard(
                        icon: Icons.check_circle,
                        label: 'الطلبات المكتملة',
                        value: '${_adminStats!.completedBookings}',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              )
            else if (!_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('جارٍ تحميل الإحصائيات...',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            if (queue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: Text('لا توجد حجوزات حالياً',
                        style: TextStyle(color: AppColors.textMuted))),
              )
            else
              ...queue.map((b) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.accentOrange.withOpacity(0.12),
                        child: Text('#${b.queueNumber}',
                            style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(b.driverName ?? 'سائق'),
                      subtitle: Text(b.driverPhone ?? ''),
                      trailing: ElevatedButton(
                        onPressed: () => _completeBooking(b),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        child: const Text('إتمام'),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final bool loading;
  final VoidCallback onToggle;

  const _AvailabilityCard(
      {required this.isAvailable,
      required this.loading,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.success : AppColors.danger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.local_gas_station, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAvailable ? 'الوقود متوفر' : 'الوقود غير متوفر',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                      isAvailable
                          ? 'محطتك ظاهرة للسائقين للحجز'
                          : 'محطتك مخفية عن قائمة الحجز',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: isAvailable,
                    activeColor: AppColors.success,
                    onChanged: (_) => onToggle(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
