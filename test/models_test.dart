import 'package:flutter_test/flutter_test.dart';
import 'package:smartbus_mobile/models/bus_model.dart';
import 'package:smartbus_mobile/models/user_model.dart';
import 'package:smartbus_mobile/models/route_model.dart';
import 'package:smartbus_mobile/models/lost_item_model.dart';

void main() {
  group('BusModel Tests', () {
    test('BusModel fromJson parses correctly with valid data', () {
      final json = {
        'id': '101',
        'busCode': 'GUL-001',
        'routeName': '17-avtobus',
        'driverName': 'Aliyev Vali',
        'speed': 35.5,
        'occupancyPercent': 45,
        'latitude': 40.489,
        'longitude': 68.776,
        'status': 'ok',
        'eta': 4,
      };

      final bus = BusModel.fromJson(json);

      expect(bus.id, '101');
      expect(bus.busCode, 'GUL-001');
      expect(bus.routeName, '17-avtobus');
      expect(bus.driverName, 'Aliyev Vali');
      expect(bus.speed, 35.5);
      expect(bus.occupancyPercent, 45);
      expect(bus.latitude, 40.489);
      expect(bus.longitude, 68.776);
      expect(bus.isSos, false);
      expect(bus.isLate, false);
      expect(bus.eta, 4);
    });

    test('BusModel handles SOS and Late status flags', () {
      const sosBus = BusModel(
        id: '1',
        busCode: 'GUL-001',
        routeName: '17',
        driverName: 'Test',
        latitude: 40.0,
        longitude: 68.0,
        status: 'sos',
      );
      expect(sosBus.isSos, true);
      expect(sosBus.isLate, false);

      const lateBus = BusModel(
        id: '2',
        busCode: 'GUL-002',
        routeName: '5',
        driverName: 'Test',
        latitude: 40.0,
        longitude: 68.0,
        status: 'late',
      );
      expect(lateBus.isSos, false);
      expect(lateBus.isLate, true);
    });

    test('BusModel copyWith updates fields properly', () {
      const bus = BusModel(
        id: '1',
        busCode: 'GUL-001',
        routeName: '17',
        driverName: 'Aliyev',
        latitude: 40.0,
        longitude: 68.0,
      );

      final updated = bus.copyWith(speed: 42.0, status: 'sos');
      expect(updated.id, '1');
      expect(updated.speed, 42.0);
      expect(updated.status, 'sos');
      expect(updated.isSos, true);
    });
  });

  group('UserModel Tests', () {
    test('UserModel role getters work correctly', () {
      const admin = UserModel(id: '1', fullName: 'Admin', role: 'admin');
      expect(admin.isAdmin, true);
      expect(admin.isDriver, false);
      expect(admin.isPassenger, false);

      const driver = UserModel(id: '2', fullName: 'Driver', role: 'driver');
      expect(driver.isAdmin, false);
      expect(driver.isDriver, true);
      expect(driver.isPassenger, false);

      const passenger = UserModel(id: '3', fullName: 'User', role: 'passenger');
      expect(passenger.isAdmin, false);
      expect(passenger.isDriver, false);
      expect(passenger.isPassenger, true);
    });

    test('UserModel JSON serialization roundtrip', () {
      final json = {
        'id': 'usr_1',
        'fullName': 'Suxrob Nazarov',
        'phoneNumber': '+998901234567',
        'role': 'passenger',
        'isOnline': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.fullName, 'Suxrob Nazarov');
      expect(user.phoneNumber, '+998901234567');
      expect(user.isOnline, true);

      final outJson = user.toJson();
      expect(outJson['fullName'], 'Suxrob Nazarov');
    });
  });

  group('RouteModel Tests', () {
    test('RouteModel fromJson parses route details', () {
      final json = {
        'id': '1',
        'routeNumber': '17',
        'name': 'Vokzal — Yangi Bozor — GulDU',
        'startStopName': 'Vokzal',
        'endStopName': 'GulDU',
        'distanceKm': 8.2,
        'estimatedDurationMin': 22,
        'activeBuses': 4,
      };

      final route = RouteModel.fromJson(json);
      expect(route.routeNumber, '17');
      expect(route.distanceKm, 8.2);
      expect(route.activeBuses, 4);
    });
  });

  group('LostItemModel Tests', () {
    test('LostItemModel status and getters', () {
      final item = LostItemModel(
        id: 'lost_1',
        title: 'Hamyon',
        busRoute: '17-avtobus',
        passengerName: 'Dilshod',
        passengerPhone: '+998901112233',
        status: 'yoqolgan',
      );

      expect(item.isFound, false);
      expect(item.title, 'Hamyon');

      final foundItem = LostItemModel(
        id: 'lost_2',
        title: 'Soyabon',
        busRoute: '8-avtobus',
        passengerName: 'Nodira',
        passengerPhone: '+998902223344',
        status: 'topildi',
      );
      expect(foundItem.isFound, true);
    });
  });
}
