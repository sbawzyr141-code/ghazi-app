class GasStation {
  final String id;
  final String name;
  final String location;
  final bool isOpen;
  final int currentQueueCount;
  final int estimatedWaitMinutes;
  final bool gasAvailable;

  GasStation({
    required this.id,
    required this.name,
    required this.location,
    required this.isOpen,
    required this.currentQueueCount,
    required this.estimatedWaitMinutes,
    required this.gasAvailable,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      isOpen: json['is_open'] ?? true,
      currentQueueCount: json['current_queue'] ?? 0,
      estimatedWaitMinutes: json['estimated_wait_minutes'] ?? 0,
      gasAvailable: json['gas_available'] ?? true,
    );
  }
}

class Booking {
  final String bookingId;
  final String stationName;
  final int queueNumber;
  final int estimatedWaitMinutes;
  final String driverName;
  final String carDetails;
  final String quantity;
  final String formattedDate;
  final String phone;
  String status;

  Booking({
    required this.bookingId,
    required this.stationName,
    required this.queueNumber,
    required this.estimatedWaitMinutes,
    required this.driverName,
    required this.carDetails,
    required this.quantity,
    required this.formattedDate,
    required this.phone,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json, {String? defaultPhone}) {
    return Booking(
      bookingId: json['booking_id'] ?? '',
      stationName: json['station_name'] ?? '',
      queueNumber: json['queue_number'] ?? 1,
      estimatedWaitMinutes: json['estimated_wait_minutes'] ?? 15,
      driverName: json['driver_name'] ?? '',
      carDetails: json['car_details'] ?? '',
      quantity: json['quantity'] ?? '',
      formattedDate: json['date'] ?? '',
      phone: json['phone'] ?? json['driver_phone'] ?? defaultPhone ?? '',
      status: json['status'] ?? 'نشط',
    );
  }
}
