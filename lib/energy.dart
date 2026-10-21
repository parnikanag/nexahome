import 'models.dart';

class EnergyMath {
  static const double defaultTariff = 8.0; // INR per kWh, editable estimate

  static double liveWatts(Iterable<TwinDevice> devices) =>
      devices.where((d) => d.on).fold<double>(0, (sum, d) => sum + d.watts);

  static double dutyFraction(TwinDevice d, String routine) {
    if (d.id == 'fridge') return .33;
    if (d.id == 'fridge_led') return .025;
    if (d.id == 'ac')
      return routine == 'Eco'
          ? .12
          : routine == 'Night'
              ? .32
              : .25;
    if (d.id == 'geyser')
      return routine == 'Eco'
          ? .02
          : routine == 'Morning'
              ? .09
              : .05;
    if (d.id == 'washer') return .035;
    if (d.id.contains('fan')) return routine == 'Night' ? .25 : .17;
    return routine == 'Evening'
        ? .28
        : routine == 'Eco'
            ? .09
            : .15;
  }

  // Daily energy projection assumes active devices run for their routine's
  // expected fraction of a day, not nonstop for 24 hours.
  static double dailyKwh(Iterable<TwinDevice> devices, String routine) =>
      devices.where((d) => d.on).fold<double>(
          0, (sum, d) => sum + d.watts / 1000 * 24 * dutyFraction(d, routine));

  static double monthlyBill(double dailyKwh, double tariff) =>
      dailyKwh * 30 * tariff;

  static double whatIfKwh(double watts, double hoursPerDay) =>
      watts * hoursPerDay / 1000;
}

class HardwareEnergyTracker {
  DateTime? _lastSampleAt;
  Map<String, dynamic> _lastReported = const {};
  Map<String, double> _lastRatings = const {};
  bool _lastOnline = false;
  DateTime? _day;
  double dailyKwh = 0;
  double totalKwh = 0;

  double? estimatedWatts(
    Map<String, dynamic> state, {
    required Map<String, double> ratings,
  }) {
    if (!state.containsKey('lamp') ||
        !state.containsKey('geyser') ||
        !state.containsKey('fridge_led') ||
        AcMode.parse(state['ac_mode']) == null) {
      return null;
    }
    var watts = 0.0;
    if (state['lamp'] == true) watts += ratings['lamp'] ?? 0;
    if (state['geyser'] == true) watts += ratings['geyser'] ?? 0;
    if (state['fridge_led'] == true) watts += ratings['fridge_led'] ?? 0;
    final acMode = AcMode.parse(state['ac_mode']);
    if (acMode != null && acMode != AcMode.off) {
      watts += ratings['ac_${acMode.name}'] ?? 0;
    }
    return watts;
  }

  void update({
    required Map<String, dynamic> reported,
    required bool online,
    required DateTime now,
    required Map<String, double> ratings,
  }) {
    final currentDay = DateTime(now.year, now.month, now.day);
    if (_day != currentDay) {
      _day = currentDay;
      dailyKwh = 0;
      _lastSampleAt = now;
      _lastReported = Map<String, dynamic>.from(reported);
      _lastRatings = Map<String, double>.from(ratings);
      _lastOnline = online;
      return;
    }

    final previousSample = _lastSampleAt;
    if (previousSample != null && _lastOnline) {
      final elapsed = now.difference(previousSample);
      if (!elapsed.isNegative && elapsed <= const Duration(seconds: 30)) {
        final watts = estimatedWatts(_lastReported, ratings: _lastRatings);
        if (watts != null) {
          final energy = watts *
              elapsed.inMicroseconds /
              Duration.microsecondsPerHour /
              1000;
          dailyKwh += energy;
          totalKwh += energy;
        }
      }
    }

    _lastSampleAt = now;
    _lastReported = Map<String, dynamic>.from(reported);
    _lastRatings = Map<String, double>.from(ratings);
    _lastOnline = online;
  }

  void reset() {
    _lastSampleAt = null;
    _lastReported = const {};
    _lastRatings = const {};
    _lastOnline = false;
    _day = null;
    dailyKwh = 0;
    totalKwh = 0;
  }

  static double estimatedBill(double dailyEnergyKwh, double tariff) =>
      dailyEnergyKwh * 30 * tariff;
}
