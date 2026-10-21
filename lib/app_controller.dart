import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_client.dart';
import 'energy.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({CloudClient? cloudClient})
      : cloud = cloudClient ?? CloudClient() {
    _simulationTimer =
        Timer.periodic(const Duration(seconds: 12), (_) => _sample());
    _sample(notify: false);
  }

  final CloudClient cloud;
  final List<TwinDevice> devices = starterDevices();
  final List<TwinEvent> events = [];
  final List<PowerPointSample> samples = [];
  final HardwareEnergyTracker hardwareEnergy = HardwareEnergyTracker();
  final Map<String, double> hardwarePowerRatings = {
    'lamp': 9,
    'ac_low': 500,
    'ac_medium': 900,
    'ac_high': 1400,
    'geyser': 1800,
    'fridge_led': 2,
  };
  SharedPreferences? _prefs;
  Timer? _simulationTimer;
  Timer? _cloudTimer;
  bool _polling = false;
  bool busy = false;
  bool cloudBusy = false;
  String? cloudError;
  String routine = 'Evening';
  double tariff = EnergyMath.defaultTariff;
  double simulateTemp = 27;
  double simulateHumidity = 54;
  double overloadLimitW = 3000;
  int gasWarningThreshold = 1800;
  double whatIfHours = 4;
  String whatIfDeviceId = 'ac';
  bool fridgeDoorOpen = false;
  DateTime? lastCloudFetch;
  IoTReading reading = const IoTReading();
  Map<String, dynamic> commands = {};
  Map<String, dynamic> reported = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    for (final d in devices) {
      d.on = _prefs?.getBool('sim_${d.id}') ?? d.on;
    }
    fridgeDoorOpen = _prefs?.getBool('sim_door_open') ?? false;
    _syncFridgeLight();
    routine = _prefs?.getString('routine') ?? routine;
    tariff = _prefs?.getDouble('tariff') ?? tariff;
    overloadLimitW = _prefs?.getDouble('overload_limit') ?? overloadLimitW;
    gasWarningThreshold =
        _prefs?.getInt('hardware_gas_threshold') ?? gasWarningThreshold;
    for (final key in hardwarePowerRatings.keys.toList()) {
      hardwarePowerRatings[key] = _prefs?.getDouble('hardware_watts_$key') ??
          hardwarePowerRatings[key]!;
    }
    simulateTemp = _prefs?.getDouble('sim_temp') ?? simulateTemp;
    simulateHumidity = _prefs?.getDouble('sim_humidity') ?? simulateHumidity;
    final api = _prefs?.getString('firebase_api') ?? '';
    final url = _prefs?.getString('firebase_url') ?? '';
    final home = _prefs?.getString('firebase_home') ?? 'demo-home';
    if (api.isNotEmpty && url.isNotEmpty) {
      try {
        cloud.configure(key: api, url: url, home: home);
      } catch (_) {/* Edit in settings. */}
    }
    _log('Digital twin simulation ready');
    notifyListeners();
  }

  TwinDevice device(String id) => devices.firstWhere((d) => d.id == id);
  List<TwinDevice> inRoom(String roomId) =>
      devices.where((d) => d.roomId == roomId).toList();
  int get onCount => devices.where((d) => d.on).length;
  double get liveWatts => EnergyMath.liveWatts(devices);
  double get dailyKwh => EnergyMath.dailyKwh(devices, routine);
  double get monthlyBill => EnergyMath.monthlyBill(dailyKwh, tariff);
  double get whatIfKwh =>
      EnergyMath.whatIfKwh(device(whatIfDeviceId).watts, whatIfHours);
  double get whatIfCost => whatIfKwh * 30 * tariff;
  bool get overload => liveWatts > overloadLimitW;
  bool get highTemperature => simulateTemp >= 42;
  bool get hasSimulationAlert => overload || highTemperature;
  bool get realStale {
    final updatedAt = reading.updatedAt;
    if (updatedAt == null) return true;
    final age = DateTime.now().difference(updatedAt);
    return age.isNegative || age > const Duration(seconds: 30);
  }

  bool get hardwareOnline =>
      reading.source?.toLowerCase() == 'esp32' && !realStale;
  double? get estimatedHardwareWatts => hardwareOnline
      ? hardwareEnergy.estimatedWatts(reported, ratings: hardwarePowerRatings)
      : null;
  double get estimatedHardwareDailyKwh => hardwareEnergy.dailyKwh;
  double get estimatedHardwareKwh => hardwareEnergy.totalKwh;
  double get estimatedHardwareMonthlyBill =>
      HardwareEnergyTracker.estimatedBill(
        estimatedHardwareDailyKwh,
        tariff,
      );

  void toggle(String id, bool value) {
    final d = device(id);
    if (d.controlledBySensor) return;
    d.on = value;
    if (id == 'fridge' && !value) _syncFridgeLight();
    if (id == 'fridge' && value) _syncFridgeLight();
    _prefs?.setBool('sim_$id', value);
    _log('${d.name} ${value ? 'ON' : 'OFF'} (simulation)');
    _sample(notify: false);
    notifyListeners();
  }

  void setDoorOpen(bool open) {
    fridgeDoorOpen = open;
    _prefs?.setBool('sim_door_open', open);
    _syncFridgeLight();
    _log('Simulated fridge door ${open ? 'OPEN' : 'CLOSED'}');
    notifyListeners();
  }

  void _syncFridgeLight() {
    device('fridge_led').on = fridgeDoorOpen && device('fridge').on;
  }

  void setRoutine(String value) {
    routine = value;
    _prefs?.setString('routine', value);
    _log('$value energy profile selected');
    notifyListeners();
  }

  void setTariff(double value) {
    tariff = value;
    _prefs?.setDouble('tariff', value);
    notifyListeners();
  }

  void setHardwarePowerRating(String key, double watts) {
    if (!hardwarePowerRatings.containsKey(key) ||
        !watts.isFinite ||
        watts < 0) {
      throw ArgumentError('Enter a valid non-negative appliance power rating.');
    }
    hardwarePowerRatings[key] = watts;
    _prefs?.setDouble('hardware_watts_$key', watts);
    notifyListeners();
  }

  void setGasWarningThreshold(int value) {
    if (value < 0 || value > 4095) {
      throw ArgumentError('MQ-2 threshold must be between 0 and 4095 ADC.');
    }
    gasWarningThreshold = value;
    _prefs?.setInt('hardware_gas_threshold', value);
    notifyListeners();
  }

  void setOverloadLimit(double value) {
    overloadLimitW = value;
    _prefs?.setDouble('overload_limit', value);
    notifyListeners();
  }

  void setTemperature(double value) {
    simulateTemp = value;
    _prefs?.setDouble('sim_temp', value);
    notifyListeners();
  }

  void setHumidity(double value) {
    simulateHumidity = value;
    _prefs?.setDouble('sim_humidity', value);
    notifyListeners();
  }

  void setWhatIfDevice(String id) {
    whatIfDeviceId = id;
    notifyListeners();
  }

  void setWhatIfHours(double hours) {
    whatIfHours = hours;
    notifyListeners();
  }

  void _sample({bool notify = true}) {
    final watts = liveWatts;
    samples.add(PowerPointSample(DateTime.now(), watts));
    if (samples.length > 42) samples.removeAt(0);
    if (notify) notifyListeners();
  }

  void _log(String message) {
    events.insert(0, TwinEvent(message));
    if (events.length > 35) events.removeLast();
  }

  Future<void> saveCloudSettings(
      {required String key, required String url, required String home}) async {
    cloud.configure(key: key, url: url, home: home);
    _cloudTimer?.cancel();
    commands = {};
    reported = {};
    reading = const IoTReading();
    hardwareEnergy.reset();
    lastCloudFetch = null;
    cloudError = null;
    await _prefs?.setString('firebase_api', cloud.apiKey);
    await _prefs?.setString('firebase_url', cloud.databaseUrl);
    await _prefs?.setString('firebase_home', cloud.homeId);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    busy = true;
    cloudError = null;
    notifyListeners();
    try {
      await cloud.signIn(email, password);
      _log('Firebase signed in: ${cloud.email}');
      await refreshIoT();
      _cloudTimer?.cancel();
      _cloudTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => refreshIoT());
    } catch (e) {
      cloudError = e.toString().replaceFirst('Bad state: ', '');
      cloud.signOut();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void signOut() {
    cloud.signOut();
    _cloudTimer?.cancel();
    commands = {};
    reported = {};
    reading = const IoTReading();
    hardwareEnergy.reset();
    lastCloudFetch = null;
    cloudError = null;
    notifyListeners();
  }

  Future<void> refreshIoT() async {
    if (!cloud.signedIn || _polling) return;
    _polling = true;
    cloudBusy = true;
    notifyListeners();
    try {
      final home = await cloud.fetchHome();
      commands = home['commands'] is Map
          ? Map<String, dynamic>.from(home['commands'] as Map)
          : {};
      reported = home['reported'] is Map
          ? Map<String, dynamic>.from(home['reported'] as Map)
          : {};
      reading = IoTReading.fromJson(home['telemetry']);
      lastCloudFetch = DateTime.now();
      hardwareEnergy.update(
        reported: reported,
        online: hardwareOnline,
        now: lastCloudFetch!,
        ratings: hardwarePowerRatings,
      );
      cloudError = null;
    } catch (e) {
      cloudError = e.toString().replaceFirst('Bad state: ', '');
    } finally {
      _polling = false;
      cloudBusy = false;
      notifyListeners();
    }
  }

  bool command(String key) => commands[key] == true;
  bool? actual(String key) =>
      reported[key] is bool ? reported[key] as bool : null;
  dynamic commandValue(String key) => commands[key];
  dynamic reportedValue(String key) => reported[key];

  bool commandPending(String commandKey, {String? reportedKey}) {
    final requested = commands[commandKey];
    return requested != null &&
        requested != reported[reportedKey ?? commandKey];
  }

  AcMode? get reportedAcMode => AcMode.parse(reported['ac_mode']);
  AcMode? get requestedAcMode => AcMode.parse(commands['ac_mode']);

  Future<void> toggleIoT(String key, bool value) async {
    await sendIoTCommand(key, value);
  }

  Future<void> setAcMode(AcMode mode) async {
    await sendIoTCommand('ac_mode', mode.label);
  }

  Future<void> sendIoTCommand(String key, dynamic value) async {
    if (!cloud.signedIn) return;
    // Command is a REQUEST. Never mark the physical device as ON until
    // ESP32 independently writes its actual GPIO state to /reported.
    final old = commands[key];
    commands[key] = value;
    cloudError = null;
    notifyListeners();
    try {
      await cloud.sendCommand(key, value);
      _log('IoT request sent: $key $value');
    } catch (e) {
      if (old == null) {
        commands.remove(key);
      } else {
        commands[key] = old;
      }
      cloudError = e.toString().replaceFirst('Bad state: ', '');
    }
    notifyListeners();
  }

  String get efficiencyTip {
    if (overload) return 'Simulated load is above your configured threshold.';
    if (device('ac').on && routine != 'Eco') {
      return 'Try Eco mode to lower the AC daily runtime assumption.';
    }
    if (device('geyser').on) {
      return 'Turning off the simulated geyser when not needed reduces the bill estimate.';
    }
    return 'Your simulated home is within the configured power limit.';
  }

  List<double> get forecastBars => List.generate(12, (i) {
        final cycle = .58 + .42 * math.sin((i + 1) * math.pi / 12).abs();
        return liveWatts * cycle;
      });

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _cloudTimer?.cancel();
    cloud.dispose();
    super.dispose();
  }
}
