import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme.dart';

/// A visual QR verification "simulator" — since a real camera scan isn't
/// needed for this dashboard, the owner types/pastes a booking ID (or scans
/// with an external device that fills this field) and watches an animated
/// laser sweep while the booking is verified against the backend.
class QrScannerScreen extends StatefulWidget {
  final ApiService api;
  final String stationId;

  const QrScannerScreen({super.key, required this.api, required this.stationId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

enum _ScanState { idle, scanning, success, failure }

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final _idCtrl = TextEditingController();
  late final AnimationController _laserCtrl;
  _ScanState _state = _ScanState.idle;
  String? _message;

  @override
  void initState() {
    super.initState();
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final bookingId = _idCtrl.text.trim();
    if (bookingId.isEmpty) return;

    setState(() {
      _state = _ScanState.scanning;
      _message = null;
    });

    // Give the laser animation a moment to "sweep" before hitting the API —
    // purely for visual feedback, mirrors a real scan-then-verify flow.
    await Future.delayed(const Duration(milliseconds: 900));

    try {
      await widget.api.completeBooking(bookingId);
      setState(() {
        _state = _ScanState.success;
        _message = 'تم التحقق من الحجز بنجاح ✅';
      });
    } catch (e) {
      setState(() {
        _state = _ScanState.failure;
        _message = e.toString();
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _message = null;
      _idCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاكي فحص QR')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScannerFrame(state: _state, laserCtrl: _laserCtrl),
                const SizedBox(height: 24),
                TextField(
                  controller: _idCtrl,
                  enabled: _state != _ScanState.scanning,
                  decoration: const InputDecoration(
                    labelText: 'معرف الحجز (من رمز QR)',
                    hintText: 'الصق أو أدخل معرف الحجز هنا',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _state == _ScanState.success ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_state == _ScanState.success || _state == _ScanState.failure)
                  ElevatedButton(onPressed: _reset, child: const Text('فحص حجز آخر'))
                else
                  ElevatedButton(
                    onPressed: _state == _ScanState.scanning ? null : _verify,
                    child: _state == _ScanState.scanning
                        ? const Text('جارٍ الفحص...')
                        : const Text('بدء الفحص'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  final _ScanState state;
  final AnimationController laserCtrl;

  const _ScannerFrame({required this.state, required this.laserCtrl});

  Color get _frameColor {
    switch (state) {
      case _ScanState.success:
        return AppColors.success;
      case _ScanState.failure:
        return AppColors.danger;
      default:
        return AppColors.primaryDeepNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _frameColor, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Corner guides
          ..._corners(),
          Center(
            child: Icon(
              state == _ScanState.success
                  ? Icons.check_circle
                  : state == _ScanState.failure
                      ? Icons.cancel
                      : Icons.qr_code_2_rounded,
              color: Colors.white24,
              size: 100,
            ),
          ),
          if (state == _ScanState.scanning)
            AnimatedBuilder(
              animation: laserCtrl,
              builder: (context, child) {
                return Positioned(
                  top: laserCtrl.value * (size - 4),
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(colors: [
                        AppColors.accentOrange.withOpacity(0),
                        AppColors.accentOrange,
                        AppColors.accentOrange.withOpacity(0),
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOrange.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const len = 28.0;
    const thick = 4.0;
    Widget corner({required Alignment align, required bool top, required bool left}) {
      return Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(color: _frameColor, top: top, left: left, thickness: thick),
            ),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, top: true, left: true),
      corner(align: Alignment.topRight, top: true, left: false),
      corner(align: Alignment.bottomLeft, top: false, left: true),
      corner(align: Alignment.bottomRight, top: false, left: false),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  final double thickness;

  _CornerPainter({required this.color, required this.top, required this.left, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final y = top ? 0.0 : size.height;
    final x = left ? 0.0 : size.width;

    path.moveTo(x, top ? size.height * 0.6 : size.height * 0.4);
    path.lineTo(x, y);
    path.lineTo(left ? size.width * 0.6 : size.width * 0.4, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
