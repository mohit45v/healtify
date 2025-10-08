import 'package:flutter/material.dart';

class CalorieCalculator extends StatefulWidget {
  const CalorieCalculator({super.key});

  @override
  State<CalorieCalculator> createState() => _CalorieCalculatorState();
}

class _CalorieCalculatorState extends State<CalorieCalculator> {
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  String gender = 'Male';
  String activity = 'Sedentary';
  double? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            TextField(
              controller: heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
            ),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Gender:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: gender,
                  items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female'))],
                  onChanged: (v) => setState(() => gender = v ?? 'Male'),
                ),
                const SizedBox(width: 24),
                const Text('Activity:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: activity,
                  items: const [
                    DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary')),
                    DropdownMenuItem(value: 'Lightly active', child: Text('Lightly active')),
                    DropdownMenuItem(value: 'Moderately active', child: Text('Moderately active')),
                    DropdownMenuItem(value: 'Very active', child: Text('Very active')),
                    DropdownMenuItem(value: 'Extra active', child: Text('Extra active')),
                  ],
                  onChanged: (v) => setState(() => activity = v ?? 'Sedentary'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightCtrl.text);
                final h = double.tryParse(heightCtrl.text);
                final a = double.tryParse(ageCtrl.text);
                if (w == null || h == null || a == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid numbers')),
                  );
                  return;
                }
                // Mifflin-St Jeor BMR
                double bmr;
                if (gender == 'Male') {
                  bmr = 10 * w + 6.25 * h - 5 * a + 5;
                } else {
                  bmr = 10 * w + 6.25 * h - 5 * a - 161;
                }
                final factors = {
                  'Sedentary': 1.2,
                  'Lightly active': 1.375,
                  'Moderately active': 1.55,
                  'Very active': 1.725,
                  'Extra active': 1.9,
                };
                final tdee = bmr * (factors[activity] ?? 1.2);
                setState(() => result = tdee);
              },
              child: const Text('Calculate'),
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              Text(
                'Estimated daily calories: ${result!.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('For weight loss: ${(result! - 500).toStringAsFixed(0)} kcal'),
              Text('For weight gain: ${(result! + 300).toStringAsFixed(0)} kcal'),
            ],
          ],
        ),
      ),
    );
  }
}
