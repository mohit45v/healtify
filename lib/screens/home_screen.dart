import 'package:flutter/material.dart';
import 'calorie_calculator.dart';
import 'water_reminder.dart';
import 'progress_tracker.dart';
import 'placeholder_screen.dart';
import 'settings_screen.dart';
import 'health_dashboard.dart';
import 'pedometer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Calorie Calculator',
        'icon': Icons.local_fire_department,
        'screen': const CalorieCalculator(),
      },
      {
        'title': 'Water Reminder',
        'icon': Icons.water_drop,
        'screen': const WaterReminder(),
      },
      {
        'title': 'Progress Tracker',
        'icon': Icons.show_chart,
        'screen': const ProgressTracker(),
      },
      {
        'title': 'Health Dashboard',
        'icon': Icons.health_and_safety,
        'screen': const HealthDashboard(),
      },
      {
        'title': 'Pedometer',
        'icon': Icons.directions_walk,
        'screen': const PedometerScreen(),
      },
      {
        'title': 'Workout Videos',
        'icon': Icons.fitness_center,
        'screen': const PlaceholderScreen(title: 'Workout Videos'),
      },
    ];

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              tween: Tween(begin: 0.9, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => features[index]['screen'] as Widget,
                  ),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          features[index]['icon'] as IconData,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          features[index]['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
