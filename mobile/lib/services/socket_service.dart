import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService instance = SocketService._internal();

  SocketService._internal();

  IO.Socket? _socket;
  final _queueUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _stationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onQueueUpdate =>
      _queueUpdateController.stream;
  Stream<Map<String, dynamic>> get onStationUpdate =>
      _stationUpdateController.stream;

  void connect(String url) {
    try {
      if (_socket != null) return;
      _socket = IO.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.on('connect', (_) {
        // connected
      });

      _socket!.on('disconnect', (_) {
        // disconnected
      });

      _socket!.on('queue_update', (data) {
        if (data is Map<String, dynamic>) _queueUpdateController.add(data);
      });

      _socket!.on('station_update', (data) {
        if (data is Map<String, dynamic>) _stationUpdateController.add(data);
      });

      _socket!.connect();
    } catch (_) {}
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket = null;
    } catch (_) {}
  }

  void joinStation(String stationId) {
    if (_socket == null) return;
    _socket!.emit('join_station', stationId);
  }

  void leaveStation(String stationId) {
    if (_socket == null) return;
    _socket!.emit('leave_station', stationId);
  }

  void dispose() {
    _queueUpdateController.close();
    _stationUpdateController.close();
    disconnect();
  }
}
