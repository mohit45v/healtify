import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../services/health_service.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final _service = HealthService();
  bool _loading = true;
  bool _granted = false;
  int _steps = 0;
  double? _heartRate;
  double _activeEnergy = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _service.requestPermissions();
    if (!ok) {
      setState(() {
        _granted = false;
        _loading = false;
      });
      return;
    }
    final steps = await _service.getTodaySteps();
    final hr = await _service.getLatestHeartRate();
    final energy = await _service.getTodayActiveEnergy();
    // Persist today's steps to weekly history
    if (mounted) {
      try {
        final appState = context.read<AppState>();
        await appState.recordTodaySteps(steps);
      } catch (_) {}
    }
    setState(() {
      _granted = true;
      _steps = steps;
      _heartRate = hr;
      _activeEnergy = energy;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();
    return Scaffold(
      body: _loading
          ? const _LoadingShimmers()
          : !_granted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(Icons.lock_outline, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 12),
                        const Text('Permissions not granted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('We need health permissions to show your dashboard.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _init();
                        },
                          child: const Text('Grant Permissions'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _init,
                  child: CustomScrollView(
                    slivers: [
                      _Header(
                        steps: _steps,
                        activeEnergy: _activeEnergy,
                        goal: appState.stepGoal,
                        onEditGoal: () => _editGoal(context, appState),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          delegate: SliverChildListDelegate.fixed([
                            _MetricTile(
                              icon: Icons.directions_walk,
                              title: 'Steps',
                              value: '$_steps',
                              subtitle: 'today',
                              color: colorScheme.primary,
                            ).animate().fadeIn(duration: 300.ms).move(begin: const Offset(0, 12), end: Offset.zero, curve: Curves.easeOut),
                            _MetricTile(
                              icon: Icons.favorite_rounded,
                              title: 'Heart Rate',
                              value: _heartRate == null ? '—' : '${_heartRate!.toStringAsFixed(0)} bpm',
                              subtitle: _heartRate == null ? 'no data' : 'latest',
                              color: Colors.pinkAccent,
                            ).animate().fadeIn(duration: 350.ms).move(begin: const Offset(0, 12), end: Offset.zero, curve: Curves.easeOut),
                            _MetricTile(
                              icon: Icons.local_fire_department_rounded,
                              title: 'Active Energy',
                              value: '${_activeEnergy.toStringAsFixed(0)} kcal',
                              subtitle: 'today',
                              color: Colors.orangeAccent,
                            ).animate().fadeIn(duration: 400.ms).move(begin: const Offset(0, 12), end: Offset.zero, curve: Curves.easeOut),
                            _MetricTile(
                              icon: Icons.show_chart_rounded,
                              title: 'Goal Progress',
                              value: _goalProgressLabel(_steps),
                              subtitle: '10k daily goal',
                              color: Colors.teal,
                            ).animate().fadeIn(duration: 450.ms).move(begin: const Offset(0, 12), end: Offset.zero, curve: Curves.easeOut),
                          ]),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _MiniWeeklyChart(stepsByDay: appState.weeklySteps, todaySteps: _steps),
                        ).animate().fadeIn(duration: 500.ms).move(begin: const Offset(0, 12), end: Offset.zero, curve: Curves.easeOut),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _QuickActions(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _editGoal(BuildContext context, AppState appState) async {
    final controller = TextEditingController(text: appState.stepGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Daily Step Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Steps'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final goal = int.tryParse(controller.text);
                if (goal != null && goal >= 1000) {
                  Navigator.pop(ctx, goal);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await appState.setStepGoal(result);
      if (mounted) setState(() {});
    }
  }
}

String _goalProgressLabel(int steps) {
  final goal = 10000;
  final pct = (steps / goal).clamp(0.0, 1.0);
  final percent = (pct * 100).toStringAsFixed(0);
  return '$percent%';
}

class _Header extends StatelessWidget {
  final int steps;
  final double activeEnergy;
  final int goal;
  final VoidCallback onEditGoal;
  const _Header({required this.steps, required this.activeEnergy, required this.goal, required this.onEditGoal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (steps / goal).clamp(0.0, 1.0);
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: scheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ProgressRing(progress: progress, label: '${(progress * 100).toStringAsFixed(0)}%').animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Today', style: TextStyle(color: scheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onEditGoal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.onPrimary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Goal: $goal', style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('$steps steps', style: TextStyle(color: scheme.onPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, color: scheme.onPrimary, size: 18),
                            const SizedBox(width: 6),
                            Text('${activeEnergy.toStringAsFixed(0)} kcal', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
        title: Text('Health Dashboard', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final String label;
  const _ProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: scheme.onPrimary.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
                ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  const _MetricTile({required this.icon, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: scheme.onPrimaryContainer.withOpacity(0.8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/water'),
            icon: const Icon(Icons.water_drop),
            label: const Text('Water'),
            style: ElevatedButton.styleFrom(backgroundColor: scheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/pedometer'),
            icon: const Icon(Icons.directions_walk),
            label: const Text('Pedometer'),
            style: ElevatedButton.styleFrom(backgroundColor: scheme.secondary),
          ),
        ),
      ],
    );
  }
}

class _MiniWeeklyChart extends StatelessWidget {
  final List<int> stepsByDay; // Mon..Sun
  final int todaySteps;
  const _MiniWeeklyChart({required this.stepsByDay, required this.todaySteps});

  List<BarChartGroupData> _bars(Color barColor) {
    final values = List<int>.from(stepsByDay);
    if (values.length != 7) {
      values
        ..clear()
        ..addAll([0, 0, 0, 0, 0, 0, todaySteps]);
    } else {
      values[6] = todaySteps; // ensure last is today
    }
    return List.generate(values.length, (i) {
      final isToday = i == values.length - 1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i].toDouble(),
            color: isToday ? barColor : barColor.withOpacity(0.5),
            width: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly Steps', style: TextStyle(fontWeight: FontWeight.w700)),
                Icon(Icons.calendar_today_rounded, size: 18, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) return const SizedBox();
                          final isToday = idx == labels.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(labels[idx], style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: _bars(scheme.primary),
                  maxY: 12000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShimmers extends StatelessWidget {
  const _LoadingShimmers();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}



