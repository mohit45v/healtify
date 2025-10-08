import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class WaterReminder extends StatefulWidget {
  const WaterReminder({super.key});

  @override
  State<WaterReminder> createState() => _WaterReminderState();
}

class _WaterReminderState extends State<WaterReminder> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final goal = appState.dailyWaterGoal;
    final count = appState.waterCount;
    final progress = (goal == 0) ? 0.0 : (count / goal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Water Reminder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Today\'s Goal: $goal glasses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),
            const SizedBox(height: 10),
            Text('$count', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: appState.incrementWater,
              child: const Text('Add a Glass'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: appState.resetWaterForToday,
              child: const Text('Reset Today'),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Daily Goal:'),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: goal,
                    items: const [6, 8, 10, 12, 14]
                        .map((g) => DropdownMenuItem(value: g, child: Text('$g')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) appState.setDailyWaterGoal(v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
