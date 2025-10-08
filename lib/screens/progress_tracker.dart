import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ProgressTracker extends StatefulWidget {
  const ProgressTracker({super.key});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final progress = appState.weeklyProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Weekly Progress: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Slider(value: progress, onChanged: appState.setWeeklyProgress),
          ],
        ),
      ),
    );
  }
}
