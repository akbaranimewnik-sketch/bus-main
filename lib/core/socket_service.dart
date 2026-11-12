import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'constants.dart';
import 'sound_service.dart';

final socketConnectedProvider = StateProvider<bool>((ref) => false);

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.onConnectionChanged((connected) {
    ref.read(socketConnectedProvider.notifier).state = connected;
  });
  service.connect();
  service.onSosAlert((data) {
    ref.read(sosAlertProvider.notifier).state = Map<String, dynamic>.from(data);
  });
  service.onSosResolved((data) {
    ref.read(sosAlertProvider.notifier).state = null;
  });
  service.onDelayAlert((data) {
    ref.read(delayAlertProvider.notifier).state = Map<String, dynamic>.from(data);
    // User: "agar qanaqadiir masalan tirbandilk yoki nnarsa topilish kesa shu sms ovoz kesin yolovchi ui ga faqat"
    SoundService.playSmsSound();
    ref.read(passengerSmsAlertProvider.notifier).state = {
      'id': data['id'] ?? 'delay_${DateTime.now().millisecondsSinceEpoch}',
      'title': '⚠️ Kechikish & Tirbandlik Ogohlantirishi',
      'message': data['message'] ?? "Yo'lda ta'mirlash sababli kechikish kutilmoqda.",
      'type': 'delay',
      'timestamp': DateTime.now().toIso8601String(),
    };
  });
  service.onDelayResolved(() {
    ref.read(delayAlertProvider.notifier).state = null;
  });
  service.onLostItemFound((data) {
    // User: "agar topildini bosa yolovchiga sms borsin topildi dep"
    SoundService.playSmsSound();
    ref.read(passengerSmsAlertProvider.notifier).state = {
      'id': data['id'] ?? 'found_${DateTime.now().millisecondsSinceEpoch}',
      'title': '🎉 XUSHXABAR: BUYUMINGIZ TOPILDI!',
      'message': data['message'] ?? "Siz qidirgan buyum topildi! Dispetcherlik xonasidan olib ketishingiz mumkin.",
      'type': 'found',
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
      'itemTitle': data['title'],
      'busRoute': data['busRoute'],
    };
  });
  ref.onDispose(() => service.disconnect());
  return service;
});

// Real-time Chat Provider between Driver and Dispatcher
final dispatcherChatProvider = StateNotifierProvider<DispatcherChatNotifier, List<Map<String, dynamic>>>(
  (ref) => DispatcherChatNotifier(ref.watch(socketServiceProvider)),
);

// Live buses state from socket & real-time simulator
final liveBusesProvider = StateNotifierProvider<LiveBusesNotifier, List<Map<String, dynamic>>>(
  (ref) => LiveBusesNotifier(ref.watch(socketServiceProvider)),
);

// SOS alerts stream - initialized to NULL (no SOS until driver clicks SOS)
final sosAlertProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Delay alerts stream - initialized to NULL (only shown when someone reports a delay)
final delayAlertProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// SMS Notification state for Passenger UI (Delay, Found Item, etc.)
final passengerSmsAlertProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Lost & Found Items Provider
final lostItemsProvider = StateNotifierProvider<LostItemsNotifier, List<Map<String, dynamic>>>(
  (ref) => LostItemsNotifier(ref.watch(socketServiceProvider)),
);

// Drivers state
final driversProvider = StateNotifierProvider<DriversNotifier, List<Map<String, dynamic>>>(
  (ref) => DriversNotifier(ref.watch(socketServiceProvider)),
);

class LostItemsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final SocketService _socket;

  LostItemsNotifier(this._socket) : super([
    {
      'id': 'lost_1',
      'title': 'Qora charm hamyon',
      'description': 'Ichida talabalik guvohnomasi va Humo transport kartasi bor',
      'busRoute': '17-avtobus',
      'passengerName': 'Dilshod Raximov',
      'passengerPhone': '+998 90 123 45 67',
      'status': 'yoqolgan',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'foundAt': null,
    },
    {
      'id': 'lost_2',
      'title': "Ko'k soyabon",
      'description': "Orqa o'rindiqda qolib ketgan, yog'och sopli",
      'busRoute': '8-avtobus',
      'passengerName': 'Nodira Salimova',
      'passengerPhone': '+998 91 987 65 43',
      'status': 'topildi',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'foundAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
  ]) {
    _socket.onAllLostItemsUpdate((items) {
      if (items.isNotEmpty) {
        state = List<Map<String, dynamic>>.from(items.map((i) => Map<String, dynamic>.from(i)));
      }
    });

    _socket.onLostItemReported((item) {
      final exists = state.any((i) => i['id'] == item['id']);
      if (!exists) {
        state = [Map<String, dynamic>.from(item), ...state];
      }
    });

    _socket.onLostItemFound((data) {
      state = state.map((item) {
        if (item['id'] == data['id']) {
          final updated = Map<String, dynamic>.from(item);
          updated['status'] = 'topildi';
          updated['foundAt'] = data['timestamp'] ?? DateTime.now().toIso8601String();
          return updated;
        }
        return item;
      }).toList();
    });
  }

  void addReport(Map<String, dynamic> item) {
    state = [item, ...state];
    _socket.reportLostItem(item);
  }

  void markFound(String id) {
    state = state.map((item) {
      if (item['id'] == id) {
        final updated = Map<String, dynamic>.from(item);
        updated['status'] = 'topildi';
        updated['foundAt'] = DateTime.now().toIso8601String();
        return updated;
      }
      return item;
    }).toList();
    _socket.markLostItemFound(id);
  }

  void removeItem(String id) {
    state = state.where((i) => i['id'] != id).toList();
  }
}

class DriversNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final SocketService _socket;

  DriversNotifier(this._socket) : super([
    {
      'id': 'driver_1',
      'fullName': 'Aliyev Vali',
      'phoneNumber': '+998901112233',
      'username': 'haydovchi1',
      'busCode': 'GUL-001',
      'routeName': '17-avtobus',
      'isOnline': true,
    },
    {
      'id': 'driver_2',
      'fullName': 'Karimov Jasur',
      'phoneNumber': '+998902223344',
      'username': 'haydovchi2',
      'busCode': 'GUL-002',
      'routeName': '5-avtobus',
      'isOnline': true,
    },
    {
      'id': 'driver_3',
      'fullName': 'Nazarov Olim',
      'phoneNumber': '+998903334455',
      'username': 'haydovchi3',
      'busCode': 'GUL-003',
      'routeName': '8-avtobus',
      'isOnline': false,
    },
  ]) {
    _socket.onDriverAdded((driver) {
      final exists = state.any((d) => d['username'] == driver['username'] || d['id'] == driver['id']);
      if (!exists) {
        state = [Map<String, dynamic>.from(driver), ...state];
      }
    });

    _socket.onDriverDeleted((data) {
      final id = data['id'];
      state = state.where((d) => d['id'] != id && d['_id'] != id && d['username'] != id).toList();
    });
  }

  void addDriver(Map<String, dynamic> driver) {
    final exists = state.any((d) => d['username'] == driver['username']);
    if (!exists) {
      state = [driver, ...state];
    }
  }

  void removeDriver(String id) {
    state = state.where((d) => d['id'] != id && d['_id'] != id && d['username'] != id).toList();
  }
}

class DispatcherChatNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final SocketService _socket;

  DispatcherChatNotifier(this._socket)
      : super([
          {
            'id': 'msg_init_1',
            'from': 'dispatcher',
            'senderName': 'Dispetcher Markazi',
            'busCode': 'GUL-001',
            'text': "Xavfsiz tezlikka amal qiling. Mustaqillik ko'chasida ta'mirlash ishlari ketmoqda.",
            'time': '15:32',
          },
          {
            'id': 'msg_init_2',
            'from': 'dispatcher',
            'senderName': 'Dispetcher Markazi',
            'busCode': 'GUL-001',
            'text': "Yangi Bozor bekatida ko'p yo'lovchilar kutmoqda.",
            'time': '15:40',
          },
        ]) {
    _socket.onChatMessage((data) {
      final exists = state.any((m) => m['id'] == data['id']);
      if (!exists) {
        state = [...state, Map<String, dynamic>.from(data)];
      }
    });
  }

  void sendMessage({
    required String text,
    required String from,
    required String senderName,
    String busCode = 'GUL-001',
  }) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final msg = {
      'id': 'msg_${now.millisecondsSinceEpoch}',
      'from': from,
      'senderName': senderName,
      'busCode': busCode,
      'text': text,
      'time': timeStr,
      'timestamp': now.toIso8601String(),
    };
    state = [...state, msg];
    _socket.sendChatMessage(msg);
  }
}

class LiveBusesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final SocketService _socket;
  Timer? _simTimer;

  // Initial simulation state for Guliston buses
  List<Map<String, dynamic>> _buses = [
    {
      'id': '1',
      'busCode': 'Dostlik dan vokzalga',
      'routeName': '9-avtobus',
      'driverName': 'Aliyev Vali',
      'speed': 34,
      'occupancyPercent': 42,
      'latitude': 40.4910,
      'longitude': 68.7780,
      'dLat': 0.00025,
      'dLng': 0.00035,
      'status': 'ok',
      'eta': 3,
    },
    {
      'id': '2',
      'busCode': 'Yangi bozordan vokzalga',
      'routeName': '11-avtobus',
      'driverName': 'Karimov Jasur',
      'speed': 28,
      'occupancyPercent': 65,
      'latitude': 40.4950,
      'longitude': 68.7830,
      'dLat': -0.0002,
      'dLng': 0.0003,
      'status': 'ok',
      'eta': 5,
    },
    {
      'id': '3',
      'busCode': 'GUL-003',
      'routeName': '8-avtobus',
      'driverName': 'Nazarov Olim',
      'speed': 38,
      'occupancyPercent': 80,
      'latitude': 40.4870,
      'longitude': 68.7710,
      'dLat': 0.00035,
      'dLng': -0.00025,
      'status': 'late',
      'eta': 8,
    },
    {
      'id': '4',
      'busCode': 'GUL-004',
      'routeName': '22-avtobus',
      'driverName': 'Yusupov Said',
      'speed': 25,
      'occupancyPercent': 55,
      'latitude': 40.4990,
      'longitude': 68.7900,
      'dLat': -0.0003,
      'dLng': -0.0003,
      'status': 'ok',
      'eta': 4,
    },
    {
      'id': '5',
      'busCode': 'GUL-005',
      'routeName': '3-avtobus',
      'driverName': 'Toshmatov Anvar',
      'speed': 18,
      'occupancyPercent': 90,
      'latitude': 40.4830,
      'longitude': 68.7640,
      'dLat': 0.0002,
      'dLng': 0.00045,
      'status': 'ok',
      'eta': 12,
    },
  ];

  LiveBusesNotifier(this._socket) : super([]) {
    state = List<Map<String, dynamic>>.from(_buses);

    // If real backend sends socket updates, use them
    _socket.onBusUpdate((buses) {
      if (buses.isNotEmpty) {
        state = List<Map<String, dynamic>>.from(buses);
      }
    });

    // Continuous Real-Time Motion Simulation (updates every 2 seconds)
    _startRealtimeSimulator();
  }

  void _startRealtimeSimulator() {
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // If socket is actively receiving backend events, skip local simulation
      if (_socket.isConnected) return;

      final updated = _buses.map((bus) {
        final b = Map<String, dynamic>.from(bus);
        double lat = (b['latitude'] as num).toDouble();
        double lng = (b['longitude'] as num).toDouble();
        double dLat = (b['dLat'] as num).toDouble();
        double dLng = (b['dLng'] as num).toDouble();

        lat += dLat;
        lng += dLng;

        // Bounce back smoothly if out of Guliston city limits
        if (lat > 40.5080 || lat < 40.4750) {
          dLat = -dLat;
        }
        if (lng > 68.7980 || lng < 68.7550) {
          dLng = -dLng;
        }

        b['latitude'] = lat;
        b['longitude'] = lng; 
        b['dLat'] = dLat;
        b['dLng'] = dLng;
        b['speed'] = (b['status'] != 'stopped') ? 30 : 0;

        return b;
      }).toList();

      _buses = updated;
      state = List<Map<String, dynamic>>.from(_buses);
    });
  }

  void triggerSos(String busCode) {
    _buses = _buses.map((b) {
      if (b['busCode'] == busCode || b['id'] == busCode) {
        final newB = Map<String, dynamic>.from(b);
        newB['status'] = 'sos';
        return newB;
      }
      return b;
    }).toList();
    state = List<Map<String, dynamic>>.from(_buses);
  }

  void resolveSos(String busCode) {
    _buses = _buses.map((b) {
      if (b['busCode'] == busCode || b['id'] == busCode) {
        final newB = Map<String, dynamic>.from(b);
        newB['status'] = 'ok';
        return newB;
      }
      return b;
    }).toList();
    state = List<Map<String, dynamic>>.from(_buses);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}

class SocketService {
  socket_io.Socket? _socket;
  void Function(bool connected)? _connectionCallback;

  void onConnectionChanged(void Function(bool connected) callback) {
    _connectionCallback = callback;
  }

  void connect() {
    try {
      _socket = socket_io.io(
        AppConstants.socketUrl,
        socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(9999)
          .setTimeout(5000)
          .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ Socket.IO connected!');
        _connectionCallback?.call(true);
        _socket!.emit('join_role', 'ALL');
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket.IO disconnected');
        _connectionCallback?.call(false);
      });

      _socket!.onConnectError((e) {
        debugPrint('Socket connection note: $e');
        _connectionCallback?.call(false);
      });
    } catch (e) {
      debugPrint('Socket init exception: $e');
    }
  }

  void onBusUpdate(void Function(List buses) handler) {
    _socket?.on('bus_location_updated', (data) {
      if (data is List) handler(data);
    });
    _socket?.on('all_buses_update', (data) {
      if (data is List) handler(data);
    });
  }

  void updateBusLocation({
    required String busCode,
    required double latitude,
    required double longitude,
    int speed = 30,
    int occupancyPercent = 45,
    String status = 'ok',
  }) {
    _socket?.emit('update_bus_location', {
      'busCode': busCode,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'occupancyPercent': occupancyPercent,
      'status': status,
    });
  }

  void onChatMessage(void Function(Map data) handler) {
    _socket?.on('chat:message', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void sendChatMessage(Map<String, dynamic> data) {
    _socket?.emit('chat:message', data);
  }

  void onSosAlert(void Function(Map data) handler) {
    _socket?.on('sos_alert_triggered', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onSosResolved(void Function(Map data) handler) {
    _socket?.on('sos_alert_resolved', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onDelayAlert(void Function(Map data) handler) {
    _socket?.on('delay_alert_triggered', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onDelayResolved(void Function() handler) {
    _socket?.on('delay_alert_resolved', (_) {
      handler();
    });
  }

  void onDriverAdded(void Function(Map data) handler) {
    _socket?.on('driver_added', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onDriverDeleted(void Function(Map data) handler) {
    _socket?.on('driver_deleted', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void triggerSos(Map<String, dynamic> data) {
    _socket?.emit('trigger_sos', data);
  }

  void resolveSos(String busCode) {
    _socket?.emit('resolve_sos', {'busCode': busCode});
  }

  void reportDelay(Map<String, dynamic> data) {
    _socket?.emit('report_delay', data);
  }

  void resolveDelay() {
    _socket?.emit('resolve_delay');
  }

  void onLostItemReported(void Function(Map data) handler) {
    _socket?.on('lost_item_reported', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onLostItemFound(void Function(Map data) handler) {
    _socket?.on('lost_item_found', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onAllLostItemsUpdate(void Function(List items) handler) {
    _socket?.on('all_lost_items_update', (data) {
      if (data is List) handler(data);
    });
  }

  void reportLostItem(Map<String, dynamic> data) {
    _socket?.emit('report_lost_item', data);
  }

  void markLostItemFound(String id) {
    _socket?.emit('mark_lost_item_found', {'id': id});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  bool get isConnected => _socket?.connected ?? false;
}

