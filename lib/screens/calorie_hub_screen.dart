import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class CalorieHubScreen extends StatefulWidget {
  const CalorieHubScreen({super.key});

  @override
  State<CalorieHubScreen> createState() => _CalorieHubScreenState();
}

class _CalorieHubScreenState extends State<CalorieHubScreen> {
  int? _dailyBudget;
  int _consumedToday = 0; // Default to 0
  int? _remainingCalories;
  bool _isLoading = true;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  // Form Key for the food log dialog
  final _foodLogFormKey = GlobalKey<FormState>();
  late TextEditingController _caloriesController;
  late TextEditingController _descriptionController;

  // For Quick Adjust Dialog
  final _quickAdjustFormKey = GlobalKey<FormState>();
  late TextEditingController _quickAdjustCaloriesController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController();
    _descriptionController = TextEditingController();
    _quickAdjustCaloriesController = TextEditingController(); // Initialize new controller
    _fetchCalorieData();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _descriptionController.dispose();
    _quickAdjustCaloriesController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _fetchCalorieData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw 'User not logged in.';
      }

      // 1. Fetch Daily Calorie Budget
      final budgetResponse = await _supabase
          .from('macro_goals')
          .select('daily_calorie_budget')
          .eq('user_id', userId)
          .maybeSingle(); // Use maybeSingle to handle potential null

      if (budgetResponse == null) {
        // This case should ideally not happen due to the trigger,
        // but handle it defensively.
        print('Warning: No macro_goals found for user $userId. Using default budget 2000.');
        _dailyBudget = 2000; // Fallback default
      } else {
         _dailyBudget = budgetResponse['daily_calorie_budget'] as int? ?? 2000; // Use default if null
      }

      // 2. Fetch Today's Calorie Activities
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

      final activityResponse = await _supabase
          .from('calorie_activity')
          .select('calories, operation')
          .eq('user_id', userId)
          .gte('activity_timestamp', startOfDay)
          .lte('activity_timestamp', endOfDay);

      // 3. Calculate Consumed Calories
      int consumed = 0;
      for (var activity in activityResponse as List) {
        final calories = activity['calories'] as int? ?? 0;
        final operation = activity['operation'] as String?;
        if (operation == 'decrease') { // Food intake, manual subtractions from budget
            consumed += calories;
        } else if (operation == 'increase') { // Manual additions to budget (e.g., exercise credit)
            consumed -= calories; // Effectively adds back to remaining by reducing what's considered "consumed" from budget
        }
      }
      _consumedToday = consumed;

      // 4. Calculate Remaining Calories
      _remainingCalories = (_dailyBudget ?? 0) - _consumedToday;

    } catch (e) {
       print('Error fetching calorie data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load calorie data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCalorieData, // Use the existing fetch method for refresh
        child: ListView( // Replace Center with ListView to ensure scrollability
          children: [
             Padding( // Keep padding around the content
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? Center(child: const CircularProgressIndicator()) // Center loading indicator
                    : _errorMessage != null
                        ? Center( // Center error message
                            child: Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column( // Existing content column
                              mainAxisAlignment: MainAxisAlignment.center, // Column properties remain
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Daily Budget: ${_dailyBudget != null ? _dailyBudget! : "N/A"} kcal',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Consumed Today: $_consumedToday kcal',
                                   style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Today\'s Calories Remaining:',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                if (_remainingCalories != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade900, size: 30),
                                        onPressed: () => _showQuickAdjustDialog(isIncrease: false),
                                        tooltip: 'Subtract Calories',
                                      ),
                                      Expanded(
                                        child: Text(
                                          '$_remainingCalories kcal',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: _remainingCalories! >= 0
                                                ? Colors.green.shade700 // Darker Green
                                                : Colors.red.shade900, // Darker Red
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline, color: Colors.green.shade700, size: 30),
                                        onPressed: () => _showQuickAdjustDialog(isIncrease: true),
                                        tooltip: 'Add Calories',
                                      ),
                                    ],
                                  )
                                else
                                  const Text(
                                    'N/A',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                if (_remainingCalories != null)
                                   Text(
                                     _remainingCalories! >= 0
                                        ? "You're currently in a Calorie Deficit for the day"
                                        : "You're currently in a Calorie Surplus for the day",
                                     style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showLogFoodDialog,
                                  icon: const Icon(Icons.fastfood_outlined),
                                  label: const Text('Log Food Intake'),
                                  style: ElevatedButton.styleFrom(
                                    //primary: Theme.of(context).colorScheme.secondary, // Example styling
                                  ),
                                )
                              ],
                            ),
              ),
           ],
        ),
      ),
    );
  }

  void _showLogFoodDialog() {
    // Clear previous values
    _caloriesController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Food Intake'),
          content: SingleChildScrollView(
            child: Form(
              key: _foodLogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories*',
                      hintText: 'e.g., 350',
                      icon: Icon(Icons.local_fire_department),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter calories';
                      }
                      final intCalories = int.tryParse(value);
                      if (intCalories == null) {
                        return 'Please enter a valid number';
                      }
                      if (intCalories < 1 || intCalories > 10000) {
                        return 'Calories must be between 1 and 10000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'What did you eat?',
                      hintText: 'e.g., Apple and peanut butter',
                      icon: Icon(Icons.description_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    // Can be optional, so no validator or a lenient one
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            ElevatedButton(
              child: const Text('Log'),
              onPressed: () {
                _submitFoodLogForm(dialogContext); // Pass dialogContext to close it later
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFoodLogForm(BuildContext dialogContext) async {
    if (_foodLogFormKey.currentState?.validate() ?? false) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final calories = int.parse(_caloriesController.text);
        final description = _descriptionController.text;

        await _supabase.from('calorie_activity').insert({
          'user_id': userId,
          'calories': calories,
          'description': description.isNotEmpty ? description : null, // Store null if empty
          'activity': 'food_intake', // Corrected ENUM value for food logging
          'operation': 'decrease',  // Food intake DECREASES remaining budget
          'activity_timestamp': DateTime.now().toIso8601String(),
        });

        // ignore: use_build_context_synchronously
        if (!Navigator.of(dialogContext).canPop()) return; // Check if dialog is still mounted
        Navigator.of(dialogContext).pop(); // Dismiss dialog
        
        // Refresh the main screen data
        _fetchCalorieData(); 

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food logged successfully!'), backgroundColor: Colors.green),
        );

      } catch (e) {
        print('Error logging food: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log food: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Quick Adjust Dialog and Logic ---
  void _showQuickAdjustDialog({required bool isIncrease}) {
    _quickAdjustCaloriesController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isIncrease ? 'Add Calories' : 'Subtract Calories'),
          content: SingleChildScrollView(
            child: Form(
              key: _quickAdjustFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _quickAdjustCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories*',
                      hintText: 'e.g., 100',
                      icon: Icon(Icons.calculate_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter calories';
                      }
                      final intCalories = int.tryParse(value);
                      if (intCalories == null) {
                        return 'Please enter a valid number';
                      }
                      if (intCalories < 1 || intCalories > 10000) {
                        return 'Calories must be between 1 and 10000';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                _submitQuickAdjustForm(isIncrease: isIncrease, dialogContext: dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitQuickAdjustForm({
    required bool isIncrease,
    required BuildContext dialogContext,
  }) async {
    if (_quickAdjustFormKey.currentState?.validate() ?? false) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final calories = int.parse(_quickAdjustCaloriesController.text);

        await _supabase.from('calorie_activity').insert({
          'user_id': userId,
          'calories': calories,
          'description': isIncrease ? 'Manual calorie addition' : 'Manual calorie subtraction',
          'activity': 'manual_adjustment', // As per ENUM calorie_activity_action
          'operation': isIncrease ? 'increase' : 'decrease',
          'activity_timestamp': DateTime.now().toIso8601String(),
        });

        if (Navigator.of(dialogContext).canPop()) {
           Navigator.of(dialogContext).pop();
        }
        
        _fetchCalorieData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calories ${isIncrease ? "added" : "subtracted"} successfully!'),
            backgroundColor: Colors.green,
          ),
        );

      } catch (e) {
        print('Error quick adjusting calories: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update calories: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- End Quick Adjust --- 
} 