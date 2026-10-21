import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_twin/energy.dart';
import 'package:smart_home_twin/models.dart';

void main() {
  test('default home contains required 3 bedrooms and utility spaces', () {
    expect(rooms.where((r) => r.name.startsWith('Bedroom')).length, 3);
    expect(rooms.any((r) => r.id == 'wash'), isTrue);
    expect(rooms.any((r) => r.id == 'kitchen'), isTrue);
    expect(rooms.any((r) => r.id == 'utility'), isTrue);
  });
  test('live load is sum of enabled devices only', () {
    final d = starterDevices();
    for (final item in d) {
      item.on = false;
    }
    d.first.on = true;
    expect(EnergyMath.liveWatts(d), 24);
    d[1].on = true;
    expect(EnergyMath.liveWatts(d), 94);
  });
  test('bill estimate is energy multiplied by tariff and 30 days', () {
    expect(EnergyMath.monthlyBill(2, 8), 480);
  });
  test('eco profile reduces AC daily kWh relative to evening', () {
    final d = starterDevices();
    for (final item in d) {
      item.on = item.id == 'ac';
    }
    expect(EnergyMath.dailyKwh(d, 'Eco'),
        lessThan(EnergyMath.dailyKwh(d, 'Evening')));
  });
  test('what-if 1500 W two hours uses 3 kWh', () {
    expect(EnergyMath.whatIfKwh(1500, 2), 3);
  });
  test('sensor data parses missing fields gracefully', () {
    final read =
        IoTReading.fromJson({'door_open': true, 'temperature_c': 27.5});
    expect(read.doorOpen, isTrue);
    expect(read.temperature, 27.5);
    expect(read.humidity, isNull);
  });
}
