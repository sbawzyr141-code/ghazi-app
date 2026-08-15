import 'package:flutter/material.dart';
import '../models/ghazi_models.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'ticket_screen.dart';

class BookingScreen extends StatefulWidget {
  final GasStation station;
  final VoidCallback? onBackClick;
  final Function(Booking)? onBookingCreatedSuccess;

  const BookingScreen({
    super.key,
    required this.station,
    this.onBackClick,
    this.onBookingCreatedSuccess,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _carModelController = TextEditingController();
  final _quantityController = TextEditingController(text: '20 لتر');
  bool _isLoading = false;
  String? _gasSystem; // 'original' | 'converted'
  bool _serviceFeeAgreed = false;

  final List<String> _quickQuantities = [
    '15 لتر',
    '20 لتر',
    '25 لتر',
    '30 لتر',
    'فل (تعبئة كاملة)',
  ];

  @override
  void dispose() {
    _driverNameController.dispose();
    _phoneController.dispose();
    _carPlateController.dispose();
    _carModelController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gasSystem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار نوع منظومة الغاز')),
      );
      return;
    }
    if (!_serviceFeeAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يجب الموافقة على رسوم الخدمة (1,000 ريال)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newBooking = await ApiService.createBooking(
        stationId: widget.station.id,
        driverName: _driverNameController.text.trim(),
        phone: _phoneController.text.trim(),
        carPlate: _carPlateController.text.trim(),
        carModel: _carModelController.text.trim(),
        quantity: _quantityController.text.trim(),
        gasSystem: _gasSystem,
        serviceFeeAgreed: _serviceFeeAgreed,
      );

      if (!mounted) return;

      // إذا تم تمرير callback خارجياً، استخدمه، وإلا افتح شاشة التذكرة
      if (widget.onBookingCreatedSuccess != null) {
        widget.onBookingCreatedSuccess!(newBooking);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TicketScreen(booking: newBooking),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إتمام الحجز: $e'),
          backgroundColor: GhaziTheme.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhaziTheme.background,
      appBar: AppBar(
        title: Text('حجز دور - ${widget.station.name}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBackClick != null) {
              widget.onBackClick!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بطاقة تفاصيل المحطة الحالية
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.station.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GhaziTheme.navy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.station.isOpen
                                  ? GhaziTheme.greenLight
                                  : GhaziTheme.redLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.station.isOpen ? 'مفتوح الآن' : 'مغلق',
                              style: TextStyle(
                                color: widget.station.isOpen
                                    ? GhaziTheme.green
                                    : GhaziTheme.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: GhaziTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.station.location,
                              style: const TextStyle(
                                color: GhaziTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: GhaziTheme.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'الانتظار في الطابور:',
                                style: TextStyle(
                                  color: GhaziTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${widget.station.currentQueueCount} سيارة',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GhaziTheme.orange,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'بيانات السائق والسيارة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GhaziTheme.navy,
                ),
              ),
              const SizedBox(height: 12),

              // حقل اسم السائق
              TextFormField(
                controller: _driverNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم السائق',
                  hintText: 'أدخل الاسم الثلاثي',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال اسم السائق';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // حقل رقم الهاتف
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: 'مثال: 770000000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  if (val.trim().length < 9) {
                    return 'يرجى إدخال رقم هاتف صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // حقول تفاصيل السيارة (الموديل واللوحة)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carModelController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'نوع السيارة',
                        hintText: 'مثال: هايلوكس',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'أدخل النوع';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _carPlateController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'رقم اللوحة',
                        hintText: 'مثال: 14520/حضرموت',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'أدخل اللوحة';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                'نوع منظومة الغاز',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GhaziTheme.navy,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('غاز وكالة'),
                      value: 'original',
                      groupValue: _gasSystem,
                      onChanged: (v) => setState(() => _gasSystem = v),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('غاز محول'),
                      value: 'converted',
                      groupValue: _gasSystem,
                      onChanged: (v) => setState(() => _gasSystem = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                value: _serviceFeeAgreed,
                onChanged: (v) =>
                    setState(() => _serviceFeeAgreed = v ?? false),
                title: const Text(
                    'موافق على رسوم خدمة الحجز عبر التطبيق (1,000 ريال)'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_serviceFeeAgreed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade700),
                  ),
                  child: const Text(
                      '📌 تنبيه: يتم تسليم رسوم الخدمة (1,000 ريال) مباشرة لصاحب المحطة عند الوصول واستلام الغاز.'),
                ),

              // تحديد الكمية
              const Text(
                'كمية الغاز المطلوبة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GhaziTheme.navy,
                ),
              ),
              const SizedBox(height: 8),

              // خيارات سريعة للكميات
              Wrap(
                spacing: 8,
                children: _quickQuantities.map((q) {
                  final isSelected = _quantityController.text == q;
                  return ChoiceChip(
                    label: Text(q),
                    selected: isSelected,
                    selectedColor: GhaziTheme.orange.withOpacity(0.15),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? GhaziTheme.orange : GhaziTheme.navy,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? GhaziTheme.orange
                          : const Color(0xFFE5E7EB),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _quantityController.text = q);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية المحددة',
                  prefixIcon: Icon(Icons.local_gas_station_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى تحديد كمية الغاز';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // زر تأكيد الحجز المربوط بالـ API
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: GhaziTheme.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'تأكيد حجز الدور',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
