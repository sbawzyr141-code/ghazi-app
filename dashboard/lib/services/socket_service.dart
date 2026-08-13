import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';

/// Thin wrapper around socket_io_client so screens can listen to
/// `station_update`, `station_update_global`, and `queue_update` events
/// without reload-based polling.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  IO.Socket connect() {
    _socket ??= IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    if (_socket!.disconnected) {
      _socket!.connect();
    }
    return _socket!;
  }

  void joinStation(String stationId) {
    connect().emit('join_station', stationId);
  }

  void leaveStation(String stationId) {
    _socket?.emit('leave_station', stationId);
  }

  void onStationUpdate(void Function(dynamic data) cb) {
    connect().on('station_update', cb);
  }

  void onGlobalStationUpdate(void Function(dynamic data) cb) {
    connect().on('station_update_global', cb);
  }

  void onQueueUpdate(void Function(dynamic data) cb) {
    connect().on('queue_update', cb);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
