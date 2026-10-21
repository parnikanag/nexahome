import 'package:flutter/material.dart';

enum AcMode {
  off,
  low,
  medium,
  high;

  String get label => name.toUpperCase();

  static AcMode? parse(Object? value) {
    for (final mode in values) {
      if (mode.label == value) return mode;
    }
    return null;
  }
}

class TwinRoom {
  const TwinRoom(this.id, this.name, this.icon, this.subtitle);
  final String id;
  final String name;
  final IconData icon;
  final String subtitle;
}

class TwinDevice {
  TwinDevice(this.id, this.name, this.roomId, this.watts, this.icon,
      {this.on = false, this.controlledBySensor = false});
  final String id;
  final String name;
  final String roomId;
  final double watts;
  final IconData icon;
  final bool controlledBySensor;
  bool on;
}

const rooms = <TwinRoom>[
  TwinRoom(
      'living', 'Living Room', Icons.weekend_outlined, 'Relax & entertainment'),
  TwinRoom('bed1', 'Bedroom 1', Icons.bed_outlined, 'Primary bedroom'),
  TwinRoom(
      'bed2', 'Bedroom 2', Icons.single_bed_outlined, 'Air conditioning zone'),
  TwinRoom('bed3', 'Bedroom 3', Icons.hotel_outlined, 'Guest / study'),
  TwinRoom('wash', 'Washroom', Icons.shower_outlined, 'Hot water & lighting'),
  TwinRoom(
      'kitchen', 'Kitchen', Icons.kitchen_outlined, 'Refrigeration & cooking'),
  TwinRoom('utility', 'Utility Space', Icons.local_laundry_service_outlined,
      'Laundry equipment'),
];

List<TwinDevice> starterDevices() => [
      TwinDevice(
          'living_lights', 'Ceiling Lights', 'living', 24, Icons.light_outlined,
          on: true),
      TwinDevice('living_fan', 'Fan', 'living', 70, Icons.air_outlined,
          on: true),
      TwinDevice('lamp', 'Lamp LED', 'bed1', 9, Icons.lightbulb_outline,
          on: true),
      TwinDevice('bed1_fan', 'Fan', 'bed1', 70, Icons.air_outlined),
      TwinDevice('ac', 'AC', 'bed2', 1400, Icons.ac_unit_outlined),
      TwinDevice(
          'bed2_lights', 'Ceiling Lights', 'bed2', 18, Icons.light_outlined),
      TwinDevice(
          'bed3_lights', 'Ceiling Lights', 'bed3', 18, Icons.light_outlined),
      TwinDevice('bed3_fan', 'Fan', 'bed3', 70, Icons.air_outlined),
      TwinDevice('geyser', 'Geyser', 'wash', 1800, Icons.water_drop_outlined),
      TwinDevice(
          'wash_lights', 'Ceiling Lights', 'wash', 12, Icons.light_outlined),
      TwinDevice('fridge', 'Fridge', 'kitchen', 150, Icons.kitchen_outlined,
          on: true),
      TwinDevice('fridge_led', 'Fridge Interior LED', 'kitchen', 2,
          Icons.lightbulb_outline,
          controlledBySensor: true),
      TwinDevice('kitchen_lights', 'Ceiling Lights', 'kitchen', 20,
          Icons.light_outlined),
      TwinDevice('washer', 'Washing Machine', 'utility', 500,
          Icons.local_laundry_service_outlined),
      TwinDevice('utility_lights', 'Ceiling Lights', 'utility', 12,
          Icons.light_outlined),
    ];

class TwinEvent {
  TwinEvent(this.message, {DateTime? time}) : time = time ?? DateTime.now();
  final DateTime time;
  final String message;
}

class PowerPointSample {
  const PowerPointSample(this.time, this.watts);
  final DateTime time;
  final double watts;
}

class IoTReading {
  const IoTReading({
    this.temperature,
    this.humidity,
    this.gasRaw,
    this.gasAlert,
    this.doorOpen,
    this.updatedAt,
    this.source,
  });
  final double? temperature;
  final double? humidity;
  final int? gasRaw;
  final bool? gasAlert;
  final bool? doorOpen;
  final DateTime? updatedAt;
  final String? source;

  factory IoTReading.fromJson(dynamic raw) {
    final map = raw is Map ? raw : const <String, dynamic>{};
    double? number(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v');
    DateTime? timestamp;
    final stamp = map['updated_at'];
    if (stamp is String) timestamp = DateTime.tryParse(stamp);
    if (stamp is num)
      timestamp =
          DateTime.fromMillisecondsSinceEpoch(stamp.toInt(), isUtc: true);
    return IoTReading(
      temperature:
          map['temperature_c'] == null ? null : number(map['temperature_c']),
      humidity:
          map['humidity_pct'] == null ? null : number(map['humidity_pct']),
      gasRaw: map['gas_raw'] is num ? (map['gas_raw'] as num).toInt() : null,
      gasAlert: map['gas_alert'] is bool ? map['gas_alert'] as bool : null,
      doorOpen: map['fridge_door_open'] is bool
          ? map['fridge_door_open'] as bool
          : map['door_open'] is bool
              ? map['door_open'] as bool
              : null,
      updatedAt: timestamp,
      source: map['source'] is String ? map['source'] as String : null,
    );
  }
}
