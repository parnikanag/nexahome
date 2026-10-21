import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home_twin/app_controller.dart';
import 'package:smart_home_twin/cloud_client.dart';
import 'package:smart_home_twin/energy.dart';
import 'package:smart_home_twin/models.dart';
import 'package:smart_home_twin/pages.dart';

void main() {
  testWidgets('NexaHome brand is shown in main navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController();

    await tester.pumpWidget(
      MaterialApp(home: TwinShell(controller: controller)),
    );
    expect(find.text('NEXAHOME'), findsOneWidget);

    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Bedroom 1 hardware model', () {
    test('AC mode values are exclusive named requests', () {
      expect(AcMode.values.map((mode) => mode.label),
          ['OFF', 'LOW', 'MEDIUM', 'HIGH']);
      expect(AcMode.parse('MEDIUM'), AcMode.medium);
      expect(AcMode.parse('unknown'), isNull);
    });

    test('fridge LED cannot be manually commanded and AC mode is validated',
        () async {
      final cloud = CloudClient(httpClient: _FirebaseMemoryClient());
      addTearDown(cloud.dispose);
      await expectLater(
        cloud.sendCommand('fridge_led', true),
        throwsArgumentError,
      );
      await expectLater(
        cloud.sendCommand('ac_mode', 'TURBO'),
        throwsArgumentError,
      );
    });

    test('simulation switches remain separate from bedroom hardware requests',
        () async {
      final controller = AppController();
      addTearDown(controller.dispose);

      final bed1Simulation = controller.device('lamp');
      expect(bed1Simulation.roomId, 'bed1');
      controller.toggle('lamp', false);

      expect(bed1Simulation.on, isFalse);
      expect(controller.commands, isEmpty);
      expect(controller.device('living_lights').on, isTrue);
    });

    test('fridge reed telemetry and LED report are read-only hardware state',
        () {
      final reading = IoTReading.fromJson({
        'fridge_door_open': true,
        'source': 'esp32',
      });
      expect(reading.doorOpen, isTrue);

      final legacyReading = IoTReading.fromJson({'door_open': false});
      expect(legacyReading.doorOpen, isFalse);
      expect(
        IoTReading.fromJson({'fridge_door_open': false}).doorOpen,
        isFalse,
      );
    });

    testWidgets('Bedroom 1 opens physical controls without leaving Home Layout',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final backend = _FirebaseMemoryClient();
      final cloud = CloudClient(httpClient: backend)
        ..configure(
          key: 'test-web-key',
          url: 'https://example-default-rtdb.firebaseio.com',
          home: 'demo-home',
        );
      final controller = AppController(cloudClient: cloud);
      await controller.signIn('app@example.test', 'unused-test-password');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LayoutPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      final hardwareButton = find.text('ESP32 HARDWARE · 11');
      await tester.ensureVisible(hardwareButton);
      await tester.tap(hardwareButton);
      await tester.pumpAndSettle();

      expect(find.text('BEDROOM 1 · PHYSICAL ESP32 HARDWARE'), findsOneWidget);
      expect(find.text('Temperature · GPIO4'), findsOneWidget);
      expect(find.text('Humidity · GPIO4'), findsOneWidget);
      expect(find.text('MQ-2 · GPIO34'), findsOneWidget);
      expect(find.text('MAIN DOOR · SG90'), findsOneWidget);
      expect(find.text('Interactive smart-home layout'), findsOneWidget);

      await tester.tap(find.text('HIGH').last);
      await tester.pumpAndSettle();
      expect(controller.commandValue('ac_mode'), 'HIGH');
      controller.dispose();
    });

    test(
        'energy uses fresh reported modes and counts each elapsed interval once',
        () {
      final tracker = HardwareEnergyTracker();
      const ratings = {
        'lamp': 9.0,
        'ac_low': 500.0,
        'ac_medium': 900.0,
        'ac_high': 1400.0,
        'geyser': 1800.0,
        'fridge_led': 2.0,
      };
      final start = DateTime(2026, 10, 21, 10);
      final lowState = {
        'lamp': true,
        'ac_mode': 'LOW',
        'geyser': false,
        'fridge_led': false,
      };
      tracker.update(
        reported: lowState,
        online: true,
        now: start,
        ratings: ratings,
      );
      expect(tracker.estimatedWatts(lowState, ratings: ratings), 509);
      expect(
        tracker.estimatedWatts(
          {...lowState, 'ac_mode': 'MEDIUM'},
          ratings: ratings,
        ),
        909,
      );

      tracker.update(
        reported: lowState,
        online: true,
        now: start.add(const Duration(seconds: 10)),
        ratings: ratings,
      );
      tracker.update(
        reported: {...lowState, 'ac_mode': 'HIGH'},
        online: true,
        now: start.add(const Duration(seconds: 10)),
        ratings: ratings,
      );
      expect(tracker.dailyKwh, closeTo(509 * 10 / 3600000, 1e-9));

      tracker.update(
        reported: {...lowState, 'ac_mode': 'HIGH'},
        online: true,
        now: start.add(const Duration(seconds: 20)),
        ratings: ratings,
      );
      expect(
        tracker.dailyKwh,
        closeTo((509 * 10 + 1409 * 10) / 3600000, 1e-9),
      );
      expect(tracker.totalKwh, tracker.dailyKwh);
      expect(HardwareEnergyTracker.estimatedBill(tracker.dailyKwh, 8),
          closeTo(tracker.dailyKwh * 240, 1e-9));
    });
  });

  test(
      'Firebase commands stay pending until shared reported state confirms them',
      () async {
    final backend = _FirebaseMemoryClient();
    final cloud = CloudClient(httpClient: backend)
      ..configure(
        key: 'test-web-key',
        url: 'https://example-default-rtdb.firebaseio.com',
        home: 'demo-home',
      );
    final controller = AppController(cloudClient: cloud);
    addTearDown(controller.dispose);

    await controller.signIn('app@example.test', 'unused-test-password');
    expect(cloud.signedIn, isTrue);
    expect(controller.hardwareOnline, isTrue);

    await controller.toggleIoT('lamp', true);
    expect(backend.commands['lamp'], isTrue);
    expect(controller.actual('lamp'), isFalse);
    expect(controller.commandPending('lamp'), isTrue);

    backend.reported['lamp'] = true;
    await controller.refreshIoT();
    expect(controller.actual('lamp'), isTrue);
    expect(controller.commandPending('lamp'), isFalse);

    await controller.setAcMode(AcMode.high);
    expect(backend.commands['ac_mode'], 'HIGH');
    expect(controller.reportedAcMode, AcMode.off);
    expect(controller.commandPending('ac_mode'), isTrue);

    backend.reported['ac_mode'] = 'HIGH';
    await controller.refreshIoT();
    expect(controller.reportedAcMode, AcMode.high);
    expect(controller.commandPending('ac_mode'), isFalse);

    await controller.toggleIoT('geyser', true);
    expect(backend.commands['geyser'], isTrue);
    expect(controller.actual('geyser'), isFalse);
    backend.reported['geyser'] = true;
    await controller.refreshIoT();
    expect(controller.actual('geyser'), isTrue);

    await controller.sendIoTCommand('door_open', true);
    expect(backend.commands['door_open'], isTrue);
    expect(controller.actual('main_door_open'), isFalse);
    expect(
        controller.commandPending('door_open', reportedKey: 'main_door_open'),
        isTrue);
    backend.reported['main_door_open'] = true;
    await controller.refreshIoT();
    expect(controller.actual('main_door_open'), isTrue);
    expect(
        controller.commandPending('door_open', reportedKey: 'main_door_open'),
        isFalse);
  });
}

class _FirebaseMemoryClient extends http.BaseClient {
  final commands = <String, dynamic>{
    'lamp': false,
    'ac_mode': 'OFF',
    'geyser': false,
    'door_open': false,
  };
  final reported = <String, dynamic>{
    'lamp': false,
    'ac_mode': 'OFF',
    'geyser': false,
    'fridge_led': false,
    'main_door_open': false,
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    if (uri.host == 'identitytoolkit.googleapis.com') {
      return _response(request, {
        'idToken': 'test-id-token',
        'refreshToken': 'test-refresh-token',
        'localId': 'test-app-user',
        'expiresIn': '3600',
      });
    }
    if (request.method == 'PUT' && uri.path.contains('/commands/')) {
      final key = uri.path.split('/').last.replaceAll('.json', '');
      commands[key] = jsonDecode(await request.finalize().bytesToString());
      return _response(request, commands[key]);
    }
    if (request.method == 'GET' && uri.path.endsWith('/homes/demo-home.json')) {
      return _response(request, {
        'commands': commands,
        'reported': reported,
        'telemetry': {
          'temperature_c': 24.5,
          'humidity_pct': 48.0,
          'fridge_door_open': false,
          'gas_raw': 120,
          'source': 'esp32',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
      });
    }
    return _response(request, {'error': 'unexpected test request'},
        status: 404);
  }

  http.StreamedResponse _response(
    http.BaseRequest request,
    dynamic body, {
    int status = 200,
  }) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
        request: request,
      );
}
