import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'floor_plan.dart';
import 'models.dart';

const bg = Color(0xFF080D18);
const panel = Color(0xFF101A29);
const border = Color(0xFF263449);
const mint = Color(0xFF65D9C4);
const cyan = Color(0xFF91B9FF);
const muted = Color(0xFFA8B8CB);
const orange = Color(0xFFFFC77A);

const destinations = <(String, IconData)>[
  ('Overview', Icons.dashboard_outlined),
  ('Home Layout', Icons.grid_view_rounded),
  ('Simulation', Icons.science_outlined),
  ('Real IoT Sensors', Icons.sensors_outlined),
  ('Settings', Icons.settings_outlined),
];

class TwinShell extends StatefulWidget {
  const TwinShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<TwinShell> createState() => _TwinShellState();
}

class _TwinShellState extends State<TwinShell> {
  int selected = 0;

  Widget _page(AppController c) => switch (selected) {
        0 => OverviewPage(controller: c),
        1 => LayoutPage(controller: c),
        2 => SimulationPage(controller: c),
        3 => RealIoTPage(
            controller: c, openSettings: () => setState(() => selected = 4)),
        _ => SettingsPage(controller: c),
      };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final compact = MediaQuery.sizeOf(context).width < 900;
          return Scaffold(
            body: SafeArea(
              child: Row(children: [
                if (!compact) _sidebar(),
                Expanded(
                    child: Column(children: [
                  _topbar(compact),
                  Expanded(child: _page(widget.controller)),
                ])),
              ]),
            ),
            bottomNavigationBar: compact
                ? NavigationBar(
                    height: 76,
                    backgroundColor: const Color(0xFF0C1522),
                    elevation: 0,
                    indicatorColor: mint.withValues(alpha: .13),
                    selectedIndex: selected,
                    onDestinationSelected: (value) =>
                        setState(() => selected = value),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: [
                      for (final d in destinations)
                        NavigationDestination(
                          icon: Icon(d.$2),
                          selectedIcon: Icon(d.$2, color: mint),
                          label: d.$1,
                        )
                    ],
                  )
                : null,
          );
        },
      );

  Widget _sidebar() => Container(
        width: 254,
        decoration: const BoxDecoration(
            color: Color(0xFF0B1320),
            border: Border(right: BorderSide(color: border))),
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      mint.withValues(alpha: .24),
                      const Color(0xFF91B9FF).withValues(alpha: .10),
                    ]),
                    border: Border.all(color: mint.withValues(alpha: .25)),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.home_work_rounded, color: mint, size: 22)),
            const SizedBox(width: 11),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('NEXAHOME',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1)),
                  Text('CONNECTED HOME CONTROL',
                      style: TextStyle(
                          color: muted, fontSize: 9, letterSpacing: 1.15))
                ])),
          ]),
          const SizedBox(height: 32),
          const Padding(
              padding: EdgeInsets.only(left: 11, bottom: 10),
              child: Text('CONTROL CENTER',
                  style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800))),
          for (var i = 0; i < destinations.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: selected == i
                    ? const Color(0xFF142C34)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => selected = i),
                  child: SizedBox(
                    height: 46,
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 3,
                        height: selected == i ? 25 : 0,
                        decoration: BoxDecoration(
                          color: mint,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        destinations[i].$2,
                        color: selected == i ? mint : muted,
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destinations[i].$1,
                          style: TextStyle(
                            color: selected == i
                                ? const Color(0xFFE8F5F2)
                                : const Color(0xFFBCC9D8),
                            fontSize: 12,
                            fontWeight: selected == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected == i)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child:
                              Icon(Icons.chevron_right, size: 16, color: mint),
                        ),
                    ]),
                  ),
                ),
              ),
            )
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.controller.cloud.signedIn ? mint : cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.controller.cloud.signedIn
                          ? 'Cloud connected'
                          : 'Local simulation',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.controller.cloud.signedIn
                          ? 'Firebase session active'
                          : 'Hardware setup available',
                      style: const TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.controller.cloud.signedIn
                    ? Icons.cloud_done_outlined
                    : Icons.devices_outlined,
                size: 17,
                color: widget.controller.cloud.signedIn ? mint : muted,
              ),
            ]),
          ),
          const SizedBox(height: 11),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Text('NEXAHOME  •  v2.0',
                style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF708198),
                    letterSpacing: 1.05)),
          ),
        ]),
      );

  Widget _topbar(bool compact) => Container(
        height: 72,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 30),
        decoration: const BoxDecoration(
          color: Color(0xFF0A111D),
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(children: [
          if (compact) ...[
            const Icon(Icons.home_work_rounded, color: mint, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact)
                  const Text('NEXAHOME  /  WORKSPACE',
                      style: TextStyle(
                          color: muted,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700)),
                Text(destinations[selected].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.2)),
              ],
            ),
          ),
          if (!compact) ...[
            const Icon(Icons.schedule_rounded, color: muted, size: 15),
            const SizedBox(width: 6),
            Text(
              TimeOfDay.now().format(context),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(width: 18),
          ],
          StatusPill(
            text: widget.controller.cloud.signedIn ? 'Firebase' : 'Simulation',
            color: widget.controller.cloud.signedIn ? mint : cyan,
            icon: widget.controller.cloud.signedIn
                ? Icons.cloud_done_outlined
                : Icons.tune_rounded,
          ),
        ]),
      );
}

class Panel extends StatelessWidget {
  const Panel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border.withValues(alpha: .82)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 20,
                offset: Offset(0, 7),
              ),
            ]),
        child: child,
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key, required this.text, this.color = mint, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: .22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon ?? Icons.circle, color: color, size: icon == null ? 7 : 14),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 700 ? 16 : 32,
            MediaQuery.sizeOf(context).width < 700 ? 20 : 28,
            MediaQuery.sizeOf(context).width < 700 ? 16 : 32,
            40),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children))),
      );
}

class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFF0F4FA),
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.5),
            )
          ],
        ]),
      );
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.note});
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: muted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
          ]),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 27,
                height: 1.1,
                letterSpacing: -.7,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFF0F4FA),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 10, height: 1.4),
          ),
        ]),
      );
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: mint),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFD3E1E4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

Widget responsiveTiles(BuildContext context, List<Widget> children,
        {double minWidth = 210, double space = 12}) =>
    LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(1, (constraints.maxWidth / minWidth).floor());
        final width = (constraints.maxWidth - space * (count - 1)) / count;
        return Wrap(spacing: space, runSpacing: space, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      },
    );

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => PageBody(children: [
        Container(
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 28),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF12333A),
                  Color(0xFF142635),
                  Color(0xFF111A2A),
                ],
                stops: [0, .42, 1],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2C5457)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x23000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ]),
          child: Stack(children: [
            Positioned(
              right: -55,
              top: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: mint.withValues(alpha: .09), width: 1.2),
                ),
              ),
            ),
            Positioned(
              right: 9,
              bottom: -144,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cyan.withValues(alpha: .035),
                ),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    text: controller.cloud.signedIn
                        ? 'HOME SYSTEM  ·  CLOUD CONNECTED'
                        : 'HOME SYSTEM  ·  LOCAL SIMULATION',
                    color: mint,
                    icon: controller.cloud.signedIn
                        ? Icons.cloud_done_outlined
                        : Icons.home_work_outlined,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'A clearer view of your home.',
                    style: TextStyle(
                      fontSize: compact ? 25 : 34,
                      height: 1.12,
                      letterSpacing: -1.1,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF0F6F6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Monitor simulated energy, manage room controls, and check the status of connected ESP32 hardware.',
                    style: TextStyle(
                      color: Color(0xFFB9CBD2),
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Wrap(spacing: 8, runSpacing: 8, children: [
                    _HeroTag(
                        icon: Icons.bolt_outlined, label: 'Energy insights'),
                    _HeroTag(
                        icon: Icons.sensors_outlined, label: 'Device status'),
                    _HeroTag(
                        icon: Icons.shield_outlined, label: 'Simulation-first'),
                  ]),
                ],
              );
              if (compact) return intro;
              return Row(children: [
                Expanded(child: intro),
                const SizedBox(width: 24),
                Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      mint.withValues(alpha: .16),
                      mint.withValues(alpha: .03),
                    ]),
                    border: Border.all(color: mint.withValues(alpha: .18)),
                  ),
                  child: const Icon(Icons.home_work_rounded,
                      color: mint, size: 58),
                ),
              ]);
            }),
          ]),
        ),
        const SizedBox(height: 20),
        responsiveTiles(context, [
          StatTile(
              label: 'Live simulated load',
              value: '${controller.liveWatts.toStringAsFixed(0)} W',
              icon: Icons.bolt_rounded,
              color: mint,
              note: 'Sum of ON simulated devices'),
          StatTile(
              label: 'Energy projection',
              value: '${controller.dailyKwh.toStringAsFixed(2)} kWh',
              icon: Icons.bar_chart_rounded,
              color: cyan,
              note: 'Estimated per day • ${controller.routine}'),
          StatTile(
              label: 'Monthly cost estimate',
              value: '₹${controller.monthlyBill.toStringAsFixed(0)}',
              icon: Icons.currency_rupee_rounded,
              color: orange,
              note: '30 days • ₹${controller.tariff.toStringAsFixed(1)}/kWh'),
          StatTile(
              label: 'Devices running',
              value: '${controller.onCount} / ${controller.devices.length}',
              icon: Icons.power_settings_new,
              color: mint,
              note: 'Simulation switches only'),
        ]),
        const SizedBox(height: 26),
        responsiveTiles(
            context,
            [
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SectionHead('Power activity',
                        subtitle: 'Recent simulated power samples'),
                    SizedBox(
                        height: 200,
                        child: PowerChart(values: [
                          for (final e in controller.samples) e.watts
                        ])),
                  ])),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SectionHead('Energy insights'),
                    StatusPill(
                        text: controller.overload
                            ? 'Power threshold exceeded'
                            : 'Below power limit',
                        color: controller.overload ? orange : mint,
                        icon: controller.overload
                            ? Icons.warning_amber
                            : Icons.check_circle_outline),
                    const SizedBox(height: 17),
                    Text(controller.efficiencyTip,
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 12),
                    Text(
                        'Configured alert threshold: ${controller.overloadLimitW.toStringAsFixed(0)} W',
                        style: const TextStyle(color: muted, fontSize: 12)),
                    const Divider(height: 30),
                    const Text('Cloud connection',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                        controller.cloud.signedIn
                            ? 'Signed in. Open Real IoT Sensors to view latest hardware acknowledgements.'
                            : 'Not connected. The simulator runs independently of Firebase.',
                        style: const TextStyle(color: muted, height: 1.5)),
                  ])),
            ],
            minWidth: 355),
        const SizedBox(height: 25),
        const SectionHead('Quick simulation controls',
            subtitle:
                'All of these switches are also available directly on the Home Layout page.'),
        responsiveTiles(
            context,
            [
              for (final id in ['lamp', 'ac', 'geyser', 'fridge'])
                Panel(
                    child: DeviceToggle(
                        controller: controller, device: controller.device(id))),
            ],
            minWidth: 245),
        const SizedBox(height: 25),
        const SectionHead('Recent activity'),
        Panel(
            child: controller.events.isEmpty
                ? const Text('No events yet.', style: TextStyle(color: muted))
                : Column(children: [
                    for (final event in controller.events.take(5))
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            const Icon(Icons.history_rounded,
                                size: 18, color: muted),
                            const SizedBox(width: 11),
                            Expanded(child: Text(event.message)),
                            Text(
                                TimeOfDay.fromDateTime(event.time)
                                    .format(context),
                                style: const TextStyle(
                                    color: muted, fontSize: 11)),
                          ]))
                  ])),
      ]);
}

class PowerChart extends StatelessWidget {
  const PowerChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PowerPainter(values),
        child: const SizedBox.expand(),
      );
}

class _PowerPainter extends CustomPainter {
  _PowerPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF27374D)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = 10 + (size.height - 20) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final peak = math.max(300.0, values.reduce(math.max) * 1.20);
    final dx = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - 10 - values[i] / peak * (size.height - 25);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = mint
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter old) => old.values != values;
}

class DeviceToggle extends StatelessWidget {
  const DeviceToggle(
      {super.key, required this.controller, required this.device});
  final AppController controller;
  final TwinDevice device;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: mint.withOpacity(.09),
                borderRadius: BorderRadius.circular(12)),
            child:
                Icon(device.icon, color: device.on ? mint : muted, size: 20)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
              device.controlledBySensor
                  ? 'Reed door sensor'
                  : '${device.watts.toStringAsFixed(0)} W • Simulated',
              style: const TextStyle(fontSize: 11, color: muted)),
        ])),
        Switch.adaptive(
            value: device.on,
            activeColor: mint,
            onChanged: device.controlledBySensor
                ? null
                : (on) => controller.toggle(device.id, on)),
      ]);
}

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => PageBody(children: [
        const SectionHead('Interactive smart-home layout',
            subtitle:
                'Top-down floor plan • 3 bedrooms • living room • kitchen • washroom • utility'),
        Panel(
            child: Row(children: [
          const Icon(Icons.touch_app_outlined, color: mint),
          const SizedBox(width: 10),
          const Expanded(
              child: Text(
                  'Control simulated appliances in place. Changes sync with the dashboard.',
                  style: TextStyle(color: muted))),
          StatusPill(text: 'SIMULATION', color: cyan),
        ])),
        const SizedBox(height: 20),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Row(children: [
                  Icon(Icons.architecture_rounded, color: mint, size: 19),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('HOME FLOOR PLAN',
                          style: TextStyle(
                              color: mint,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4))),
                  Text('WINDOWS  •  DOORS  •  FURNITURE',
                      style: TextStyle(
                          color: muted, fontSize: 9, letterSpacing: .5)),
                ]),
              ),
              SmartHomeFloorPlan(controller: controller),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: Text(
                    'Scroll horizontally to view the full plan on smaller screens. '
                    'Sensor-linked appliances follow their simulated sensor.',
                    style: TextStyle(color: muted, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHead('Fridge sensor demo',
              subtitle: 'Fridge interior LED follows simulated door state.'),
          Row(children: [
            Icon(
                controller.fridgeDoorOpen
                    ? Icons.door_front_door_outlined
                    : Icons.door_sliding_outlined,
                color: controller.fridgeDoorOpen ? orange : mint),
            const SizedBox(width: 14),
            const Expanded(child: Text('Fridge door is open')),
            Switch.adaptive(
                value: controller.fridgeDoorOpen,
                activeColor: mint,
                onChanged: controller.setDoorOpen),
          ]),
        ])),
      ]);
}

class SimulationPage extends StatelessWidget {
  const SimulationPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => PageBody(children: [
        const SectionHead('Simulation laboratory',
            subtitle:
                'Explore what-if energy scenarios without changing physical hardware.'),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHead('Daily routine profile',
              subtitle:
                  'Changes the assumed operating duty cycle for projected energy.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in ['Morning', 'Evening', 'Night', 'Eco'])
              ChoiceChip(
                  label: Text(p),
                  selected: controller.routine == p,
                  onSelected: (_) => controller.setRoutine(p)),
          ]),
          const SizedBox(height: 15),
          Text(
              'Daily energy: ${controller.dailyKwh.toStringAsFixed(2)} kWh  •  Monthly estimate: ₹${controller.monthlyBill.toStringAsFixed(0)}',
              style: const TextStyle(color: mint, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(height: 16),
        responsiveTiles(
            context,
            [
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SectionHead('What-if device runtime',
                        subtitle:
                            'Estimate energy and monthly cost for a chosen device.'),
                    DropdownButtonFormField<String>(
                      value: controller.whatIfDeviceId,
                      isExpanded: true,
                      items: [
                        for (final d in controller.devices
                            .where((d) => !d.controlledBySensor))
                          DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name +
                                  ' • ' +
                                  rooms
                                      .firstWhere((r) => r.id == d.roomId)
                                      .name))
                      ],
                      onChanged: (id) {
                        if (id != null) controller.setWhatIfDevice(id);
                      },
                      decoration: const InputDecoration(labelText: 'Device'),
                    ),
                    const SizedBox(height: 18),
                    _SliderRow(
                        label: 'Hours/day',
                        value: controller.whatIfHours,
                        min: 0,
                        max: 24,
                        suffix: 'h',
                        onChanged: controller.setWhatIfHours),
                    const SizedBox(height: 8),
                    Text('${controller.whatIfKwh.toStringAsFixed(2)} kWh/day',
                        style: const TextStyle(
                            color: mint,
                            fontSize: 25,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                        '₹${controller.whatIfCost.toStringAsFixed(0)} / month at the chosen tariff',
                        style: const TextStyle(color: muted)),
                  ])),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SectionHead('Simulated sensor inputs',
                        subtitle:
                            'Adjust environmental conditions to explore alert conditions.'),
                    _SliderRow(
                        label: 'Temperature',
                        value: controller.simulateTemp,
                        min: 15,
                        max: 55,
                        suffix: '°C',
                        onChanged: controller.setTemperature),
                    _SliderRow(
                        label: 'Humidity',
                        value: controller.simulateHumidity,
                        min: 10,
                        max: 100,
                        suffix: '%',
                        onChanged: controller.setHumidity),
                    const SizedBox(height: 12),
                    StatusPill(
                        text: controller.highTemperature
                            ? 'High temperature (demo)'
                            : 'Temperature normal (demo)',
                        color: controller.highTemperature ? orange : mint),
                  ])),
            ],
            minWidth: 350),
        const SizedBox(height: 16),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHead('Power budget & tariff'),
          _SliderRow(
              label: 'Overload threshold',
              value: controller.overloadLimitW,
              min: 500,
              max: 7000,
              suffix: 'W',
              onChanged: controller.setOverloadLimit),
          _SliderRow(
              label: 'Electricity rate',
              value: controller.tariff,
              min: 2,
              max: 20,
              suffix: '₹/kWh',
              onChanged: controller.setTariff),
          const SizedBox(height: 10),
          StatusPill(
              text: controller.overload
                  ? 'Simulated overload warning'
                  : 'Below simulated threshold',
              color: controller.overload ? orange : mint),
          const SizedBox(height: 10),
          const Text(
              'Illustrative forecasting only: real energy metering requires calibrated sensors. The AC, geyser and fridge power ratings here are editable in source code.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ])),
      ]);
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.suffix,
      required this.onChanged});
  final String label, suffix;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: muted))),
          Text('${value.toStringAsFixed(suffix == '₹/kWh' ? 1 : 0)} $suffix',
              style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
        Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            activeColor: mint,
            onChanged: onChanged),
      ]);
}

class RealIoTPage extends StatelessWidget {
  const RealIoTPage(
      {super.key, required this.controller, required this.openSettings});
  final AppController controller;
  final VoidCallback openSettings;
  @override
  Widget build(BuildContext context) => PageBody(children: [
        const SectionHead('Real IoT Sensors',
            subtitle:
                'ESP32 ↔ Firebase Realtime Database ↔ this app. Separate from simulation.'),
        if (!controller.cloud.signedIn) ...[
          Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Row(children: [
                  Icon(Icons.cloud_off_outlined, color: orange),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text('Hardware control is not connected',
                          style: TextStyle(fontWeight: FontWeight.w800)))
                ]),
                const SizedBox(height: 14),
                const Text(
                    'Connect to your own Firebase project using Settings. The app works offline in simulation mode without Firebase.',
                    style: TextStyle(color: muted, height: 1.6)),
                const SizedBox(height: 14),
                FilledButton.icon(
                    onPressed: openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Configure Firebase')),
              ])),
        ] else ...[
          Panel(
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 15,
                  runSpacing: 12,
                  children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const StatusPill(
                      text: 'AUTHENTICATED TO FIREBASE',
                      color: mint,
                      icon: Icons.verified_user_outlined),
                  const SizedBox(height: 8),
                  StatusPill(
                      text: controller.hardwareOnline
                          ? 'ESP32 ONLINE'
                          : controller.reading.source == 'mock'
                              ? 'MOCK DEVICE · NOT ESP32'
                              : 'ESP32 OFFLINE',
                      color: controller.hardwareOnline ? mint : muted,
                      icon: controller.hardwareOnline
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined),
                  const SizedBox(height: 8),
                  Text('Home ID: ${controller.cloud.homeId}',
                      style: const TextStyle(color: muted)),
                  Text(
                      'Last poll: ${controller.lastCloudFetch == null ? 'Not yet' : TimeOfDay.fromDateTime(controller.lastCloudFetch!).format(context)}',
                      style: const TextStyle(color: muted, fontSize: 12)),
                ]),
                OutlinedButton.icon(
                    onPressed:
                        controller.cloudBusy ? null : controller.refreshIoT,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh now')),
              ])),
          const SizedBox(height: 16),
          if (controller.cloudError != null) ...[
            _WarningBox('Firebase error: ${controller.cloudError}'),
            const SizedBox(height: 15),
          ],
          if (controller.lastCloudFetch == null) ...[
            const _WarningBox(
                'No successful database read yet. Verify the URL, Home ID and Firebase rules.'),
            const SizedBox(height: 15),
          ],
          if (controller.reading.source == 'mock') ...[
            const _WarningBox(
                'MOCK DEVICE ACTIVE: Cloud reports are simulated by a computer, not physical ESP32 hardware. Stop mock_device.py before testing real electronics.'),
            const SizedBox(height: 16),
          ],
          if (controller.realStale) ...[
            const _WarningBox(
                'No recent sensor timestamp. Telemetry may be missing or the ESP32 may be offline. Cloud sign-in is NOT proof of hardware connection.'),
            const SizedBox(height: 16),
          ],
          const SectionHead('Hardware readings',
              subtitle:
                  'Values must be published by your physical ESP32 firmware; missing values show —.'),
          responsiveTiles(
              context,
              [
                StatTile(
                    label: 'Temperature',
                    value: !controller.hardwareOnline ||
                            controller.reading.temperature == null
                        ? 'Sensor data unavailable'
                        : '${controller.reading.temperature!.toStringAsFixed(1)} °C',
                    icon: Icons.thermostat_outlined,
                    color: cyan,
                    note: 'DHT22 physical reading'),
                StatTile(
                    label: 'Humidity',
                    value: !controller.hardwareOnline ||
                            controller.reading.humidity == null
                        ? 'Sensor data unavailable'
                        : '${controller.reading.humidity!.toStringAsFixed(1)} %',
                    icon: Icons.water_outlined,
                    color: mint,
                    note: 'DHT22 physical reading'),
                StatTile(
                    label: 'Fridge door',
                    value: !controller.hardwareOnline ||
                            controller.reading.doorOpen == null
                        ? 'Sensor data unavailable'
                        : (controller.reading.doorOpen! ? 'OPEN' : 'CLOSED'),
                    icon: Icons.door_front_door_outlined,
                    color: orange,
                    note: 'GPIO13 INPUT_PULLUP • magnet near = closed'),
                StatTile(
                    label: 'MQ-2 raw ADC',
                    value: !controller.hardwareOnline ||
                            controller.reading.gasRaw == null
                        ? 'Sensor data unavailable'
                        : '${controller.reading.gasRaw} ADC',
                    icon: Icons.sensors_outlined,
                    color: cyan,
                    note: !controller.hardwareOnline ||
                            controller.reading.gasRaw == null
                        ? 'Sensor data unavailable'
                        : controller.reading.gasRaw! >=
                                controller.gasWarningThreshold
                            ? 'Prototype warning • not calibrated'
                            : 'Below prototype threshold • raw only'),
              ],
              minWidth: 230),
          const SizedBox(height: 26),
          const SectionHead('ESP32 device control',
              subtitle:
                  'Switches send commands. Physical state is shown ONLY when the ESP32 acknowledges them.'),
          responsiveTiles(
              context,
              [
                IoTControlCard(
                    controller: controller,
                    keyName: 'lamp',
                    name: 'Lamp LED',
                    pin: 'GPIO5',
                    icon: Icons.lightbulb_outline),
                _IoTAcModeCard(controller: controller),
                IoTControlCard(
                    controller: controller,
                    keyName: 'geyser',
                    name: 'Geyser Indicator LED',
                    pin: 'GPIO23',
                    icon: Icons.water_drop_outlined),
                _IoTFridgeCard(controller: controller),
              ],
              minWidth: 275),
          const SizedBox(height: 16),
          Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const SectionHead('Main-door servo',
                    subtitle:
                        'Prototype servo only • never connect a real security door lock to this demo.'),
                const Text('SG90 signal · GPIO18',
                    style: TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  OutlinedButton(
                    onPressed: () =>
                        controller.sendIoTCommand('door_open', true),
                    child: const Text('OPEN'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        controller.sendIoTCommand('door_open', false),
                    child: const Text('CLOSE'),
                  ),
                ]),
                const SizedBox(height: 8),
                StatusPill(
                  text: !controller.hardwareOnline ||
                          controller.actual('main_door_open') == null
                      ? 'Door status unavailable'
                      : controller.actual('main_door_open')!
                          ? 'ESP32 REPORTS OPEN'
                          : 'ESP32 REPORTS CLOSED',
                  color: controller.hardwareOnline &&
                          controller.actual('main_door_open') != null
                      ? mint
                      : muted,
                ),
                if (controller.commandPending('door_open',
                    reportedKey: 'main_door_open'))
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text('Door command pending',
                        style: TextStyle(color: orange, fontSize: 11)),
                  ),
              ])),
          const SizedBox(height: 18),
          const Text(
              'Important: Internet access alone does not operate LEDs. Flash compatible ESP32 firmware, provide Wi-Fi, confirm the Firebase home path and use the same database project and permitted accounts. This app does not control mains electricity.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ],
      ]);
}

class _IoTAcModeCard extends StatelessWidget {
  const _IoTAcModeCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final reported =
        controller.hardwareOnline ? controller.reportedAcMode : null;
    final requested = controller.requestedAcMode;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.ac_unit_outlined, color: mint),
          SizedBox(width: 9),
          Expanded(
              child: Text('AC mode · GPIO19 / 21 / 22',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Text('ESP32 reported: ${reported?.label ?? 'Sensor data unavailable'}',
            style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
        SegmentedButton<AcMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: AcMode.off, label: Text('OFF')),
            ButtonSegment(value: AcMode.low, label: Text('LOW')),
            ButtonSegment(value: AcMode.medium, label: Text('MED')),
            ButtonSegment(value: AcMode.high, label: Text('HIGH')),
          ],
          selected: {requested ?? reported ?? AcMode.off},
          onSelectionChanged: (selection) =>
              controller.setAcMode(selection.first),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: [
          _PinStatus('GPIO19 LOW', reported == AcMode.low),
          _PinStatus('GPIO21 MED', reported == AcMode.medium),
          _PinStatus('GPIO22 HIGH', reported == AcMode.high),
        ]),
        if (controller.commandPending('ac_mode'))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('AC mode command pending ESP32 confirmation',
                style: TextStyle(color: orange, fontSize: 11)),
          ),
      ]),
    );
  }
}

class _PinStatus extends StatelessWidget {
  const _PinStatus(this.label, this.active);
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        backgroundColor: active ? mint.withValues(alpha: .15) : panel,
        side: BorderSide(color: active ? mint : border),
        visualDensity: VisualDensity.compact,
      );
}

class _IoTFridgeCard extends StatelessWidget {
  const _IoTFridgeCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final door = controller.hardwareOnline ? controller.reading.doorOpen : null;
    final led =
        controller.hardwareOnline ? controller.actual('fridge_led') : null;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.kitchen_outlined, color: mint),
          SizedBox(width: 10),
          Expanded(
              child: Text('Fridge Interior LED',
                  style: TextStyle(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 12),
        const Text('GPIO14 · follows GPIO13 reed sensor (INPUT_PULLUP)',
            style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        StatusPill(
          text: door == null
              ? 'Sensor data unavailable'
              : door
                  ? 'DOOR OPEN'
                  : 'DOOR CLOSED',
          color: door == true
              ? orange
              : door == false
                  ? mint
                  : muted,
        ),
        const SizedBox(height: 8),
        StatusPill(
          text: led == null
              ? 'No fresh hardware report'
              : led
                  ? 'ESP32 REPORTS LED ON'
                  : 'ESP32 REPORTS LED OFF',
          color: led == true ? mint : muted,
        ),
        const SizedBox(height: 9),
        const Text('Automatic reed-sensor control · no manual switch',
            style: TextStyle(color: muted, fontSize: 11)),
      ]),
    );
  }
}

class IoTControlCard extends StatelessWidget {
  const IoTControlCard(
      {super.key,
      required this.controller,
      required this.keyName,
      required this.name,
      required this.pin,
      required this.icon});
  final AppController controller;
  final String keyName, name, pin;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final actual =
        controller.hardwareOnline ? controller.actual(keyName) : null;
    final requested = controller.command(keyName);
    return Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: mint),
        const SizedBox(width: 9),
        Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800))),
        Switch.adaptive(
            value: requested,
            activeColor: mint,
            onChanged: controller.cloud.signedIn
                ? (v) => controller.toggleIoT(keyName, v)
                : null)
      ]),
      const SizedBox(height: 10),
      Text('$pin • Command: ${requested ? 'ON' : 'OFF'}',
          style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 10),
      StatusPill(
          text: actual == null
              ? 'No fresh hardware report'
              : (actual ? 'ESP32 REPORTS ON' : 'ESP32 REPORTS OFF'),
          color: actual == true
              ? mint
              : actual == false
                  ? cyan
                  : orange),
      if (controller.commandPending(keyName)) ...[
        const SizedBox(height: 10),
        const Text('Command pending / state mismatch',
            style: TextStyle(color: orange, fontSize: 11)),
      ],
    ]));
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: orange.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: orange.withOpacity(.3))),
        child: Row(children: [
          const Icon(Icons.info_outline, color: orange),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFFFDBA8), fontSize: 12, height: 1.5)))
        ]),
      );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => PageBody(children: [
        const SectionHead('Cloud & application settings',
            subtitle:
                'Simulation saves locally. Live IoT requires your own configured Firebase backend.'),
        CloudSetupCard(controller: controller),
        const SizedBox(height: 16),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHead('Data flow'),
          const Text(
              'Mobile/Desktop Flutter App  ⇄  Firebase Realtime Database  ⇄  ESP32 hardware',
              style: TextStyle(color: mint, fontWeight: FontWeight.w700)),
          const SizedBox(height: 11),
          const Text(
              'Firebase rules must allow only the approved user accounts. Use separate app and device accounts; never put a service-account private key in the app or ESP32. Commands and ESP32 acknowledgements live at /homes/<homeId>/.',
              style: TextStyle(color: muted, height: 1.6)),
          const SizedBox(height: 12),
          const Text(
              'Setup guide and exact ESP32 cloud data protocol are included in README.md and hardware/ of this ZIP.',
              style: TextStyle(color: muted, height: 1.5)),
        ])),
        const SizedBox(height: 16),
        Panel(
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              SectionHead('About NexaHome'),
              Text(
                  'NexaHome brings your home controls, energy insights and connected devices into one clear workspace.'),
              SizedBox(height: 9),
              Text(
                  'Available on Windows, macOS and Android.\nCombines local simulation, energy estimates and Firebase-connected ESP32 controls.\nThe app remains useful when cloud hardware is offline.',
                  style: TextStyle(color: muted, height: 1.7)),
            ])),
      ]);
}

class CloudSetupCard extends StatefulWidget {
  const CloudSetupCard({super.key, required this.controller});
  final AppController controller;
  @override
  State<CloudSetupCard> createState() => _CloudSetupCardState();
}

class _CloudSetupCardState extends State<CloudSetupCard> {
  late final TextEditingController api =
      TextEditingController(text: widget.controller.cloud.apiKey);
  late final TextEditingController url =
      TextEditingController(text: widget.controller.cloud.databaseUrl);
  late final TextEditingController home =
      TextEditingController(text: widget.controller.cloud.homeId);
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  String? localError;
  bool saving = false;

  @override
  void dispose() {
    api.dispose();
    url.dispose();
    home.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      localError = null;
    });
    try {
      if (api.text.trim().isEmpty)
        throw FormatException('Enter your Firebase Web API key.');
      await widget.controller
          .saveCloudSettings(key: api.text, url: url.text, home: home.text);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Firebase connection settings saved locally. Sign in next.')));
    } catch (e) {
      if (mounted) setState(() => localError = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() =>
          localError = 'Enter the Firebase Auth user email and password.');
      return;
    }
    setState(() => localError = null);
    await widget.controller.signIn(email.text, password.text);
    password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHead('Firebase Realtime Database setup',
          subtitle:
              'Use a dedicated Firebase project with Email/Password Authentication enabled.'),
      TextField(
          controller: api,
          decoration: const InputDecoration(labelText: 'Firebase Web API key')),
      const SizedBox(height: 12),
      TextField(
          controller: url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              labelText: 'Realtime Database URL',
              hintText: 'https://your-project-default-rtdb.firebaseio.com')),
      const SizedBox(height: 12),
      TextField(
          controller: home,
          decoration: const InputDecoration(
              labelText: 'Home ID', hintText: 'demo-home')),
      const SizedBox(height: 12),
      Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Saving...' : 'Save configuration'))),
      const Divider(height: 35),
      if (c.cloud.signedIn) ...[
        Row(children: [
          const Icon(Icons.check_circle_outline, color: mint),
          const SizedBox(width: 9),
          Expanded(
              child: Text('Signed in as ${c.cloud.email}',
                  style: const TextStyle(color: mint))),
          OutlinedButton(onPressed: c.signOut, child: const Text('Sign out'))
        ]),
        const SizedBox(height: 8),
        Text('User UID: ${c.cloud.uid}',
            style: const TextStyle(color: muted, fontSize: 12)),
      ] else ...[
        const Text(
            'Authenticate a user already created in Firebase Authentication.',
            style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration:
                const InputDecoration(labelText: 'Firebase user email')),
        const SizedBox(height: 12),
        TextField(
            controller: password,
            obscureText: true,
            onSubmitted: (_) => _login(),
            decoration:
                const InputDecoration(labelText: 'Firebase user password')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: c.busy ? null : _login,
            icon: const Icon(Icons.login),
            label: Text(c.busy ? 'Connecting...' : 'Sign in & connect')),
      ],
      if (localError != null) ...[
        const SizedBox(height: 12),
        _WarningBox(localError!)
      ],
      if (c.cloudError != null) ...[
        const SizedBox(height: 12),
        _WarningBox(c.cloudError!)
      ],
      const SizedBox(height: 14),
      const Text(
          'Configuration values are saved on this device. Passwords and access tokens are kept only in app memory; sign in again after restarting. Never use open/public Firebase rules.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
    ]));
  }
}
