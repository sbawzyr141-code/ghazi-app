class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'driver' | 'owner'
  final String? stationId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.stationId,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        phone: j['phone'],
        role: j['role'] ?? 'driver',
        stationId: j['station_id'],
      );
}

class Station {
  final String id;
  final String name;
  final String nameAr;
  final String? address;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final String fuelTypes;
  final bool isAvailable;
  final int queueCount;

  Station({
    required this.id,
    required this.name,
    required this.nameAr,
    this.address,
    this.neighborhood,
    this.lat,
    this.lng,
    required this.fuelTypes,
    required this.isAvailable,
    required this.queueCount,
  });

  factory Station.fromJson(Map<String, dynamic> j) => Station(
        id: j['id'],
        name: j['name'],
        nameAr: j['name_ar'],
        address: j['address'],
        neighborhood: j['neighborhood'],
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        fuelTypes: j['fuel_types'] ?? '',
        isAvailable: (j['is_available'] == 1 || j['is_available'] == true),
        queueCount: j['queue_count'] ?? 0,
      );

  List<String> get fuelTypeList =>
      fuelTypes.split(',').where((e) => e.trim().isNotEmpty).toList();
}

class Booking {
  final String id;
  final String userId;
  final String stationId;
  final int queueNumber;
  final String status;
  final String? fuelType;
  final String createdAt;
  final String? stationNameAr;
  final String? stationAddress;
  final String? driverName;
  final String? driverPhone;

  Booking({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.queueNumber,
    required this.status,
    this.fuelType,
    required this.createdAt,
    this.stationNameAr,
    this.stationAddress,
    this.driverName,
    this.driverPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        userId: j['user_id'],
        stationId: j['station_id'],
        queueNumber: j['queue_number'],
        status: j['status'],
        fuelType: j['fuel_type'],
        createdAt: j['created_at'] ?? '',
        stationNameAr: j['station_name_ar'],
        stationAddress: j['address'],
        driverName: j['driver_name'],
        driverPhone: j['driver_phone'],
      );
}

class AdminStats {
  final int totalDrivers;
  final int totalOwners;
  final int totalStations;
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int totalQueue;

  AdminStats({
    required this.totalDrivers,
    required this.totalOwners,
    required this.totalStations,
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalQueue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalDrivers: j['totalDrivers'] ?? 0,
        totalOwners: j['totalOwners'] ?? 0,
        totalStations: j['totalStations'] ?? 0,
        totalBookings: j['totalBookings'] ?? 0,
        activeBookings: j['activeBookings'] ?? 0,
        completedBookings: j['completedBookings'] ?? 0,
        cancelledBookings: j['cancelledBookings'] ?? 0,
        totalQueue: j['totalQueue'] ?? 0,
      );
}
