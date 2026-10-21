import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'models.dart';

const _floorBackground = Color(0xFF0B1524);
const _floorSurface = Color(0xFF17263A);
const _floorWall = Color(0xFF71859D);
const _floorFurniture = Color(0xFF31465E);
const _floorWindow = Color(0xFF73D8E8);
const _floorMint = Color(0xFF73EAD1);
const _floorMuted = Color(0xFF98ABC4);

class SmartHomeFloorPlan extends StatelessWidget {
  const SmartHomeFloorPlan({super.key, required this.controller});

  final AppController controller;

  static const _zones = <(String, double, double, double, double)>[
    ('bed1', 0, 0, .25, .5),
    ('bed2', .25, 0, .25, .5),
    ('bed3', .5, 0, .25, .5),
    ('wash', .75, 0, .25, .5),
    ('living', 0, .5, .5, .5),
    ('kitchen', .5, .5, .25, .5),
    ('utility', .75, .5, .25, .5),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(920.0, constraints.maxWidth).toDouble();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: 590,
              child: Stack(children: [
                const Positioned.fill(
                    child: CustomPaint(painter: _FloorPlanPainter())),
                for (final zone in _zones)
                  Positioned(
                    left: width * zone.$2 + 8,
                    top: 8 + 8 + zone.$3 * 574,
                    width: width * zone.$4 - 16,
                    height: 574 * zone.$5 - 16,
                    child: _RoomZone(
                      room: rooms.firstWhere((room) => room.id == zone.$1),
                      devices: controller.inRoom(zone.$1),
                      onToggle: controller.toggle,
                      onOpenHardware: zone.$1 == 'bed1'
                          ? () => showDialog<void>(
                                context: context,
                                builder: (_) => _Bedroom1HardwareDialog(
                                  controller: controller,
                                ),
                              )
                          : null,
                    ),
                  ),
              ]),
            ),
          );
        },
      );
}

class _RoomZone extends StatelessWidget {
  const _RoomZone({
    required this.room,
    required this.devices,
    required this.onToggle,
    this.onOpenHardware,
  });

  final TwinRoom room;
  final List<TwinDevice> devices;
  final void Function(String id, bool value) onToggle;
  final VoidCallback? onOpenHardware;

  @override
  Widget build(BuildContext context) {
    final active = devices.where((device) => device.on).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 6),
      decoration: BoxDecoration(
        color: _floorSurface.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF344A62).withValues(alpha: .8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(room.icon, color: _floorWindow, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$active/${devices.length}',
              style: const TextStyle(
                  color: _floorMint, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ]),
          const Divider(height: 13, color: Color(0xFF344A62)),
          if (onOpenHardware != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                'SIMULATED APPLIANCES',
                style: TextStyle(
                    color: _floorMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5),
              ),
            ),
          for (final device in devices)
            Expanded(
              child: _ApplianceControl(device: device, onToggle: onToggle),
            ),
          if (onOpenHardware != null)
            SizedBox(
              height: 27,
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenHardware,
                icon: const Icon(Icons.memory_rounded, size: 13),
                label: const Text(
                  'ESP32 HARDWARE · 11',
                  style: TextStyle(fontSize: 9),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _floorMint,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplianceControl extends StatelessWidget {
  const _ApplianceControl({required this.device, required this.onToggle});

  final TwinDevice device;
  final void Function(String id, bool value) onToggle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(device.icon,
              color: device.on ? _floorMint : _floorMuted, size: 16),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600),
                ),
                Text(
                  device.controlledBySensor
                      ? 'DOOR SENSOR'
                      : '${device.watts.toStringAsFixed(0)} W',
                  maxLines: 1,
                  style: const TextStyle(color: _floorMuted, fontSize: 8),
                ),
              ],
            ),
          ),
          if (device.controlledBySensor)
            Tooltip(
              message:
                  'This appliance follows the simulated fridge door sensor',
              child: Icon(
                device.on ? Icons.sensors : Icons.sensors_off,
                color: device.on ? _floorMint : _floorMuted,
                size: 16,
              ),
            )
          else
            SizedBox(
              width: 43,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Switch.adaptive(
                  value: device.on,
                  activeThumbColor: _floorMint,
                  onChanged: (value) => onToggle(device.id, value),
                ),
              ),
            ),
        ],
      );
}

class _Bedroom1HardwareDialog extends StatelessWidget {
  const _Bedroom1HardwareDialog({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF111E32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                child: Row(children: [
                  const Icon(Icons.memory_rounded, color: _floorMint),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BEDROOM 1 · PHYSICAL ESP32 HARDWARE',
                            style: TextStyle(
                                color: _floorMint,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        Text(
                            'Requested commands and ESP32-reported states are separate.',
                            style: TextStyle(color: _floorMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  _OnlineBadge(controller: controller),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFF29364B)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Section(
                        title: 'APPLIANCE CONTROLS',
                        icon: Icons.power_settings_new,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SwitchCard(
                              controller: controller,
                              title: 'Lamp LED',
                              pin: 'GPIO5',
                              icon: Icons.lightbulb_outline,
                              keyName: 'lamp',
                            ),
                            _AcCard(controller: controller),
                            _SwitchCard(
                              controller: controller,
                              title: 'Geyser LED',
                              pin: 'GPIO23',
                              icon: Icons.water_drop_outlined,
                              keyName: 'geyser',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'DOOR CONTROLS',
                        icon: Icons.door_front_door_outlined,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MainDoorCard(controller: controller),
                            _FridgeCard(controller: controller),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'SENSOR READINGS',
                        icon: Icons.sensors_outlined,
                        child: _SensorPanel(controller: controller),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'ESTIMATED ENERGY CONSUMPTION',
                        icon: Icons.bolt_outlined,
                        child: _EnergyPanel(controller: controller),
                      ),
                      if (controller.cloudError != null) ...[
                        const SizedBox(height: 12),
                        _Warning(controller.cloudError!),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1628),
          border: Border.all(color: const Color(0xFF29364B)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _floorMint, size: 17),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: _floorMint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7)),
          ]),
          const SizedBox(height: 11),
          child,
        ]),
      );
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final mock = controller.reading.source == 'mock';
    final online = controller.hardwareOnline;
    final label = online
        ? 'ESP32 ONLINE'
        : mock
            ? 'MOCK DEVICE'
            : 'ESP32 OFFLINE';
    final color = online ? _floorMint : _floorMuted;
    return Tooltip(
      message: mock
          ? 'Mock reports are not physical ESP32 telemetry'
          : 'Online requires fresh telemetry with source=esp32',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _HardwareCard extends StatelessWidget {
  const _HardwareCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: 258,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF17263A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF29364B)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _floorMint, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.controller,
    required this.title,
    required this.pin,
    required this.icon,
    required this.keyName,
  });
  final AppController controller;
  final String title;
  final String pin;
  final IconData icon;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final actual =
        controller.hardwareOnline ? controller.actual(keyName) : null;
    final requested = controller.command(keyName);
    return _HardwareCard(
      title: title,
      icon: icon,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$pin · requested ${requested ? 'ON' : 'OFF'}',
            style: const TextStyle(color: _floorMuted, fontSize: 10)),
        Switch.adaptive(
          value: requested,
          activeThumbColor: _floorMint,
          onChanged: controller.cloud.signedIn
              ? (value) => controller.toggleIoT(keyName, value)
              : null,
        ),
        _Report(
            value: actual == null
                ? null
                : actual
                    ? 'ON'
                    : 'OFF',
            pending: controller.commandPending(keyName)),
      ]),
    );
  }
}

class _AcCard extends StatelessWidget {
  const _AcCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final actual = controller.hardwareOnline ? controller.reportedAcMode : null;
    final requested = controller.requestedAcMode;
    return _HardwareCard(
      title: 'AC MODE',
      icon: Icons.ac_unit_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reported: ${actual?.label ?? 'UNAVAILABLE'}',
            style: const TextStyle(color: _floorMuted, fontSize: 10)),
        const SizedBox(height: 7),
        SegmentedButton<AcMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: AcMode.off, label: Text('OFF')),
            ButtonSegment(value: AcMode.low, label: Text('LOW')),
            ButtonSegment(value: AcMode.medium, label: Text('MED')),
            ButtonSegment(value: AcMode.high, label: Text('HIGH')),
          ],
          selected: {requested ?? actual ?? AcMode.off},
          onSelectionChanged: controller.cloud.signedIn
              ? (selection) => controller.setAcMode(selection.first)
              : null,
        ),
        const SizedBox(height: 7),
        Wrap(spacing: 5, runSpacing: 4, children: [
          _Pin('19 LOW', actual == AcMode.low),
          _Pin('21 MED', actual == AcMode.medium),
          _Pin('22 HIGH', actual == AcMode.high),
        ]),
        _Report(
            value: actual?.label,
            pending: controller.commandPending('ac_mode')),
      ]),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.text, this.active);
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? _floorMint.withValues(alpha: .12)
              : const Color(0xFF0B1628),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: active ? _floorMint : _floorMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      );
}

class _MainDoorCard extends StatelessWidget {
  const _MainDoorCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final actual =
        controller.hardwareOnline ? controller.actual('main_door_open') : null;
    final requested = controller.commandValue('door_open');
    return _HardwareCard(
      title: 'MAIN DOOR · SG90',
      icon: Icons.door_sliding_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Servo signal · GPIO18',
            style: TextStyle(color: _floorMuted, fontSize: 10)),
        const SizedBox(height: 7),
        Wrap(spacing: 7, children: [
          OutlinedButton(
            onPressed: controller.cloud.signedIn
                ? () => controller.sendIoTCommand('door_open', true)
                : null,
            child: const Text('OPEN'),
          ),
          OutlinedButton(
            onPressed: controller.cloud.signedIn
                ? () => controller.sendIoTCommand('door_open', false)
                : null,
            child: const Text('CLOSE'),
          ),
        ]),
        _Report(
          value: actual == null
              ? null
              : actual
                  ? 'OPEN'
                  : 'CLOSED',
          pending: controller.commandPending(
            'door_open',
            reportedKey: 'main_door_open',
          ),
          requested: requested == null
              ? null
              : requested
                  ? 'OPEN'
                  : 'CLOSED',
        ),
      ]),
    );
  }
}

class _FridgeCard extends StatelessWidget {
  const _FridgeCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final door = controller.hardwareOnline ? controller.reading.doorOpen : null;
    final led =
        controller.hardwareOnline ? controller.actual('fridge_led') : null;
    return _HardwareCard(
      title: 'FRIDGE · REED SENSOR',
      icon: Icons.kitchen_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GPIO13 INPUT_PULLUP · LED GPIO14',
            style: TextStyle(color: _floorMuted, fontSize: 10)),
        const SizedBox(height: 7),
        Text(
          door == null
              ? 'Sensor data unavailable'
              : door
                  ? 'DOOR OPEN'
                  : 'DOOR CLOSED',
          style: TextStyle(
            color: door == true
                ? Colors.orangeAccent
                : door == false
                    ? _floorMint
                    : _floorMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
            'Interior LED: ${led == null ? 'unavailable' : led ? 'ESP32 reports ON' : 'ESP32 reports OFF'}',
            style: const TextStyle(color: _floorMuted, fontSize: 10)),
        const SizedBox(height: 4),
        const Text('Automatic control · no manual LED switch',
            style: TextStyle(color: _floorMuted, fontSize: 9)),
      ]),
    );
  }
}

class _SensorPanel extends StatelessWidget {
  const _SensorPanel({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final available = controller.hardwareOnline;
    final reading = controller.reading;
    final gasRaw = available ? reading.gasRaw : null;
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        _Metric(
          title: 'Temperature · GPIO4',
          value: available && reading.temperature != null
              ? '${reading.temperature!.toStringAsFixed(1)} °C'
              : 'Sensor data unavailable',
          icon: Icons.thermostat_outlined,
        ),
        _Metric(
          title: 'Humidity · GPIO4',
          value: available && reading.humidity != null
              ? '${reading.humidity!.toStringAsFixed(1)} %'
              : 'Sensor data unavailable',
          icon: Icons.water_drop_outlined,
        ),
        _Metric(
          title: 'MQ-2 · GPIO34',
          value: gasRaw == null
              ? 'Sensor data unavailable'
              : '$gasRaw ADC · ${gasRaw >= controller.gasWarningThreshold ? 'Prototype warning' : 'Below threshold'}',
          icon: Icons.sensors_outlined,
        ),
        _ThresholdInput(controller: controller),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Raw ADC is not calibrated gas concentration or a safety alarm. Keep GPIO34 input at or below 3.3 V.',
            style: TextStyle(color: _floorMuted, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _ThresholdInput extends StatefulWidget {
  const _ThresholdInput({required this.controller});
  final AppController controller;

  @override
  State<_ThresholdInput> createState() => _ThresholdInputState();
}

class _ThresholdInputState extends State<_ThresholdInput> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.gasWarningThreshold.toString(),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: TextField(
          controller: _text,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'MQ-2 threshold',
            suffixText: 'ADC',
            helperText: '0–4095 · prototype',
          ),
          onSubmitted: (value) {
            final threshold = int.tryParse(value);
            if (threshold == null || threshold < 0 || threshold > 4095) {
              _showMessage(context, 'Enter an ADC threshold from 0 to 4095.');
              return;
            }
            widget.controller.setGasWarningThreshold(threshold);
          },
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 210,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF17263A),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _floorWindow, size: 15),
            const SizedBox(width: 6),
            Expanded(
                child: Text(title,
                    style: const TextStyle(color: _floorMuted, fontSize: 10))),
          ]),
          const SizedBox(height: 7),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _EnergyPanel extends StatelessWidget {
  const _EnergyPanel({required this.controller});
  final AppController controller;

  static const _ratings = <(String, String)>[
    ('lamp', 'Lamp W'),
    ('ac_low', 'AC Low W'),
    ('ac_medium', 'AC Medium W'),
    ('ac_high', 'AC High W'),
    ('geyser', 'Geyser W'),
    ('fridge_led', 'Fridge LED W'),
  ];

  @override
  Widget build(BuildContext context) {
    final energy =
        controller.hardwareOnline ? controller.estimatedHardwareDailyKwh : null;
    final watts = controller.estimatedHardwareWatts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 9, runSpacing: 9, children: [
        _Metric(
          title: 'Estimated current power',
          value: watts == null
              ? 'Sensor data unavailable'
              : '${watts.toStringAsFixed(0)} W',
          icon: Icons.bolt_outlined,
        ),
        _Metric(
          title: 'Estimated energy consumption',
          value: energy == null
              ? 'Sensor data unavailable'
              : '${controller.estimatedHardwareKwh.toStringAsFixed(4)} kWh',
          icon: Icons.electric_meter_outlined,
        ),
        _Metric(
          title: 'Estimated daily usage',
          value: energy == null
              ? 'Sensor data unavailable'
              : '${energy.toStringAsFixed(4)} kWh',
          icon: Icons.bar_chart_rounded,
        ),
        _Metric(
          title: 'Estimated monthly bill',
          value: energy == null
              ? 'Sensor data unavailable'
              : '₹${controller.estimatedHardwareMonthlyBill.toStringAsFixed(2)}',
          icon: Icons.currency_rupee_rounded,
        ),
      ]),
      const SizedBox(height: 10),
      const Text(
        'Estimates use ESP32-reported states and elapsed monitoring time; no power meter is installed. Monthly bill projects today over 30 days.',
        style: TextStyle(color: _floorMuted, fontSize: 10, height: 1.5),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final rating in _ratings)
            _RatingInput(
              keyName: rating.$1,
              label: rating.$2,
              value: controller.hardwarePowerRatings[rating.$1]!,
              enabled: true,
              onSave: (value) {
                try {
                  controller.setHardwarePowerRating(rating.$1, value);
                } on ArgumentError catch (error) {
                  _showMessage(context, error.message.toString());
                }
              },
            ),
          _TariffInput(controller: controller),
        ],
      ),
    ]);
  }
}

class _RatingInput extends StatefulWidget {
  const _RatingInput({
    required this.keyName,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onSave,
  });
  final String keyName;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onSave;

  @override
  State<_RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<_RatingInput> {
  late final TextEditingController _text = TextEditingController(
    text: widget.value.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 112,
        child: TextField(
          controller: _text,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: widget.label, suffixText: 'W'),
          onSubmitted: (value) {
            final watts = double.tryParse(value);
            if (watts == null || !watts.isFinite || watts < 0) {
              _showMessage(context, 'Enter a valid non-negative power rating.');
              return;
            }
            widget.onSave(watts);
          },
        ),
      );
}

class _TariffInput extends StatefulWidget {
  const _TariffInput({required this.controller});
  final AppController controller;

  @override
  State<_TariffInput> createState() => _TariffInputState();
}

class _TariffInputState extends State<_TariffInput> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.tariff.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        child: TextField(
          controller: _text,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Tariff', suffixText: '₹/kWh'),
          onSubmitted: (value) {
            final tariff = double.tryParse(value);
            if (tariff == null || !tariff.isFinite || tariff < 0) {
              _showMessage(context, 'Enter a valid non-negative tariff.');
              return;
            }
            widget.controller.setTariff(tariff);
          },
        ),
      );
}

class _Report extends StatelessWidget {
  const _Report({required this.value, required this.pending, this.requested});
  final String? value;
  final bool pending;
  final String? requested;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: (value == null ? _floorMuted : _floorMint)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value == null ? 'NO HARDWARE REPORT' : 'ESP32 REPORTS $value',
              style: TextStyle(
                  color: value == null ? _floorMuted : _floorMint,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
          if (pending) ...[
            const SizedBox(height: 5),
            Text('PENDING · requested ${requested ?? 'new state'}',
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 9)),
          ],
        ],
      );
}

class _Warning extends StatelessWidget {
  const _Warning(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: .3)),
        ),
        child: Text('Firebase error: $message',
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
      );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final middleY = outer.top + outer.height * .5;
    final firstX = outer.left + outer.width * .25;
    final secondX = outer.left + outer.width * .5;
    final thirdX = outer.left + outer.width * .75;

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(7)),
      Paint()..color = _floorBackground,
    );

    final roomsRects = <Rect>[
      Rect.fromLTRB(outer.left, outer.top, firstX, middleY),
      Rect.fromLTRB(firstX, outer.top, secondX, middleY),
      Rect.fromLTRB(secondX, outer.top, thirdX, middleY),
      Rect.fromLTRB(thirdX, outer.top, outer.right, middleY),
      Rect.fromLTRB(outer.left, middleY, secondX, outer.bottom),
      Rect.fromLTRB(secondX, middleY, thirdX, outer.bottom),
      Rect.fromLTRB(thirdX, middleY, outer.right, outer.bottom),
    ];
    for (final rect in roomsRects) {
      canvas.drawRect(rect, Paint()..color = _floorSurface);
      _drawFloorTiles(canvas, rect);
    }

    _drawFurniture(canvas, roomsRects);
    _drawWalls(canvas, outer, middleY, firstX, secondX, thirdX);
    _drawWindows(canvas, outer, firstX, secondX, thirdX);
  }

  void _drawFloorTiles(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF25374B).withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var x = rect.left + 36; x < rect.right; x += 36) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }
    for (var y = rect.top + 36; y < rect.bottom; y += 36) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawFurniture(Canvas canvas, List<Rect> roomsRects) {
    _drawBed(canvas, roomsRects[0], .60);
    _drawBed(canvas, roomsRects[1], .60);
    _drawBed(canvas, roomsRects[2], .60);
    _drawToilet(canvas, roomsRects[3]);
    _drawSofa(canvas, roomsRects[4]);
    _drawCounter(canvas, roomsRects[5]);
    _drawLaundry(canvas, roomsRects[6]);
  }

  void _drawBed(Canvas canvas, Rect room, double topFactor) {
    final bed = Rect.fromLTWH(
      room.left + room.width * .63,
      room.top + room.height * topFactor,
      room.width * .23,
      room.height * .27,
    );
    _drawFurnitureShape(canvas, bed);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            bed.left + 4, bed.top + 4, bed.width - 8, bed.height * .20),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8FA9C4),
    );
    canvas.drawLine(
      Offset(bed.left, bed.top + bed.height * .28),
      Offset(bed.right, bed.top + bed.height * .28),
      Paint()
        ..color = _floorWall
        ..strokeWidth = 2,
    );
  }

  void _drawToilet(Canvas canvas, Rect room) {
    final x = room.left + room.width * .66;
    final y = room.top + room.height * .61;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 30, 20), const Radius.circular(3)),
      Paint()..color = _floorFurniture,
    );
    canvas.drawOval(
      Rect.fromLTWH(x + 3, y + 15, 24, 31),
      Paint()..color = const Color(0xFF9FB4C8),
    );
    canvas.drawOval(
      Rect.fromLTWH(x + 9, y + 22, 12, 17),
      Paint()..color = _floorSurface,
    );
  }

  void _drawSofa(Canvas canvas, Rect room) {
    final sofa = Rect.fromLTWH(
      room.left + room.width * .66,
      room.top + room.height * .56,
      room.width * .25,
      room.height * .15,
    );
    _drawFurnitureShape(canvas, sofa);
    for (var i = 1; i < 3; i++) {
      final x = sofa.left + sofa.width * i / 3;
      canvas.drawLine(
        Offset(x, sofa.top + 3),
        Offset(x, sofa.bottom - 3),
        Paint()
          ..color = _floorWall
          ..strokeWidth = 1.5,
      );
    }
    _drawFurnitureShape(
      canvas,
      Rect.fromLTWH(sofa.left + 8, sofa.bottom + 9, sofa.width - 16, 17),
    );
  }

  void _drawCounter(Canvas canvas, Rect room) {
    final counter = Rect.fromLTWH(
      room.left + room.width * .62,
      room.top + room.height * .57,
      room.width * .28,
      25,
    );
    _drawFurnitureShape(canvas, counter);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(counter.left + 5, counter.top + 5, 28, 13),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF8197AC),
    );
    canvas.drawCircle(
      Offset(counter.right - 10, counter.center.dy),
      6,
      Paint()..color = const Color(0xFF8197AC),
    );
  }

  void _drawLaundry(Canvas canvas, Rect room) {
    final machine = Rect.fromLTWH(
      room.left + room.width * .67,
      room.top + room.height * .57,
      43,
      43,
    );
    _drawFurnitureShape(canvas, machine);
    canvas.drawCircle(
      machine.center,
      12,
      Paint()
        ..color = const Color(0xFF9FB4C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawFurnitureShape(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = _floorFurniture,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = _floorWall
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawWalls(
    Canvas canvas,
    Rect outer,
    double middleY,
    double firstX,
    double secondX,
    double thirdX,
  ) {
    final wall = Paint()
      ..color = _floorWall
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;
    canvas.drawRect(outer, wall..style = PaintingStyle.stroke);
    wall.style = PaintingStyle.stroke;
    for (final x in [firstX, secondX, thirdX]) {
      canvas.drawLine(Offset(x, outer.top), Offset(x, middleY - 27), wall);
      canvas.drawLine(Offset(x, middleY + 9), Offset(x, middleY), wall);
      _drawDoor(canvas, Offset(x, middleY + 9), 34, math.pi / 2);
    }
    final doorCenters = [
      outer.left + outer.width * .125,
      outer.left + outer.width * .375,
      outer.left + outer.width * .625,
      outer.left + outer.width * .875,
    ];
    var start = outer.left;
    for (final center in doorCenters) {
      canvas.drawLine(
          Offset(start, middleY), Offset(center - 19, middleY), wall);
      _drawDoor(canvas, Offset(center - 19, middleY), 38, 0);
      start = center + 19;
    }
    canvas.drawLine(Offset(start, middleY), Offset(outer.right, middleY), wall);
    canvas.drawLine(
        Offset(secondX, middleY), Offset(secondX, outer.bottom), wall);
    canvas.drawLine(
        Offset(thirdX, middleY), Offset(thirdX, outer.bottom), wall);
  }

  void _drawDoor(Canvas canvas, Offset hinge, double length, double direction) {
    final doorPaint = Paint()
      ..color = const Color(0xFFFFC77A)
      ..strokeWidth = 2;
    final end = Offset(
      hinge.dx + math.cos(direction) * length,
      hinge.dy + math.sin(direction) * length,
    );
    canvas.drawLine(hinge, end, doorPaint);
    canvas.drawArc(
      Rect.fromCircle(center: hinge, radius: length),
      direction - math.pi / 2,
      math.pi / 2,
      false,
      doorPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawWindows(
      Canvas canvas, Rect outer, double firstX, double secondX, double thirdX) {
    final windowPaint = Paint()
      ..color = _floorWindow
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    for (final section in [
      (outer.left + 22, firstX - 22),
      (firstX + 22, secondX - 22),
      (secondX + 22, thirdX - 22),
    ]) {
      final x = (section.$1 + section.$2) / 2;
      canvas.drawLine(
          Offset(x - 24, outer.top), Offset(x + 24, outer.top), windowPaint);
    }
    canvas.drawLine(
      Offset(outer.left, outer.top + outer.height * .72),
      Offset(outer.left, outer.top + outer.height * .86),
      windowPaint,
    );
    canvas.drawLine(
      Offset(outer.right, outer.top + outer.height * .72),
      Offset(outer.right, outer.top + outer.height * .86),
      windowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) => false;
}
