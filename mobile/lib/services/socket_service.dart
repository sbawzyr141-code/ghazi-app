import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  IO.Socket? _socket;

  final StreamController<Map<String, dynamic>> _queueController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _stationController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get onQueueUpdate => _queueController.stream;
  Stream<Map<String, dynamic>> get onStationUpdate => _stationController.stream;

  void connect(String url) {
    if (_socket != null && _socket!.connected) return;
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connect', (_) {
      // connected
    });

    _socket!.on('disconnect', (_) {
      // disconnected
    });

    _socket!.on('queue_update', (data) {
      try {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
        _queueController.add(payload);
      } catch (_) {}
    });

    _socket!.on('station_update', (data) {
      try {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
        _stationController.add(payload);
      } catch (_) {}
    });
  }

  void joinStation(String stationId) {
    if (_socket == null) return;
    _socket!.emit('join_station', {'station_id': stationId});
  }

  void leaveStation(String stationId) {
    if (_socket == null) return;
    _socket!.emit('leave_station', {'station_id': stationId});
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket = null;
    } catch (_) {}
    _queueController.close();
    _stationController.close();
  }
}
