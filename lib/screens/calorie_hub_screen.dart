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
  static const int _defaultDailyBudget = 2000;

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

  // For Editing Daily Budget
  final _editBudgetFormKey = GlobalKey<FormState>();
  late TextEditingController _editBudgetController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController();
    _descriptionController = TextEditingController();
    _quickAdjustCaloriesController = TextEditingController(); // Initialize new controller
    _editBudgetController = TextEditingController(); // Initialize budget controller
    _fetchCalorieData();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _descriptionController.dispose();
    _quickAdjustCaloriesController.dispose(); // Dispose new controller
    _editBudgetController.dispose(); // Dispose budget controller
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
        print('Warning: No macro_goals found for user $userId. Using default budget $_defaultDailyBudget.');
        _dailyBudget = _defaultDailyBudget; // Fallback default
      } else {
         _dailyBudget = budgetResponse['daily_calorie_budget'] as int? ?? _defaultDailyBudget; // Use default if null
      }
      // Update the controller when budget is fetched
      _editBudgetController.text = _dailyBudget?.toString() ?? _defaultDailyBudget.toString();

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
      body: Column( // Main body is now a Column
        children: [
          Expanded( // Scrollable content takes up available space
            child: RefreshIndicator(
              onRefresh: _fetchCalorieData,
              child: ListView( // Your existing ListView for scrollable content
                children: [
                  Padding( // Keep padding around the scrollable content
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? Center(child: const CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  'Error: $_errorMessage',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column( // This Column is for the scrollable part
                                mainAxisAlignment: MainAxisAlignment.start, // Align to start
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // --- Content that stays in the main/upper scrollable part ---
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
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade900,
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
                                    style: ElevatedButton.styleFrom(),
                                  ),
                                  // Removed Spacer and bottom content from here
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
          // --- Bottom-anchored content ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0), // User adjusted bottom padding
            child: Center( // Center the Table horizontally
              child: Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: IntrinsicColumnWidth(),     // For labels
                  1: IntrinsicColumnWidth(),     // For values (colon + number + kcal) - make intrinsic to prevent too much flex
                  2: IntrinsicColumnWidth(),     // For the icon / placeholder
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  // Row 1: Consumed (Moved to the top)
                  TableRow(
                    children: <Widget>[
                      // Label
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0), // Reduced space after label
                        child: Text(
                          'Calories Consumed Today',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.right, // Right-align the label
                        ),
                      ),
                      // Value
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.titleMedium,
                          children: <TextSpan>[
                            TextSpan(text: ': '),
                            TextSpan(
                              text: '$_consumedToday',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' kcal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left, // Explicitly left-align value part
                      ),
                      // Placeholder for Icon to ensure alignment with the (now below) budget row's icon
                      SizedBox(width: 46), 
                    ],
                  ),
                  // Spacer Row - for vertical spacing
                  TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                  // Row 2: Budget (Moved to the bottom, keeps the icon)
                  TableRow(
                    children: <Widget>[
                      // Label
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          'My Daily Calorie Budget',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2,
                              ),
                          textAlign: TextAlign.right, // Right-align the label
                        ),
                      ),
                      // Value (colon + number + kcal)
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2,
                              ),
                          children: <TextSpan>[
                            TextSpan(text: ': '),
                            TextSpan(
                              text: '${_dailyBudget != null ? _dailyBudget! : "N/A"}',
                              style: TextStyle(fontWeight: FontWeight.bold), //fontSize will be inherited
                            ),
                            TextSpan(
                              text: ' kcal',
                              style: TextStyle(fontWeight: FontWeight.bold), //fontSize will be inherited
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left, // Explicitly left-align value part
                      ),
                      // Icon
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Increased space before icon for balance
                        child: Container( // Existing styled container for the icon
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: _showEditBudgetDialog,
                            tooltip: 'Edit Daily Budget',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            splashRadius: 18,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Functions ---
  String? _validateCalorieInput(String? value, {required int min, required int max, required String fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    final intCalories = int.tryParse(value);
    if (intCalories == null) {
      return 'Please enter a valid number';
    }
    if (intCalories < min || intCalories > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
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
                      return _validateCalorieInput(value, min: 1, max: 10000, fieldName: 'Calories');
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
                      return _validateCalorieInput(value, min: 1, max: 10000, fieldName: 'Calories');
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

  // --- Edit Daily Budget Dialog and Logic ---
  void _showEditBudgetDialog() {
    _editBudgetController.text = _dailyBudget?.toString() ?? _defaultDailyBudget.toString(); // Pre-fill with current budget or default

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Daily Budget'),
          content: SingleChildScrollView(
            child: Form(
              key: _editBudgetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _editBudgetController,
                    decoration: const InputDecoration(
                      labelText: 'New Daily Calorie Budget*',
                      hintText: 'e.g., 2500',
                      icon: Icon(Icons.settings_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      return _validateCalorieInput(value, min: 500, max: 10000, fieldName: 'Budget');
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
              child: const Text('Save'),
              onPressed: () {
                _submitNewBudget(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitNewBudget(BuildContext dialogContext) async {
    if (_editBudgetFormKey.currentState?.validate() ?? false) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final newBudgetValue = int.parse(_editBudgetController.text);

        await _supabase
            .from('macro_goals')
            .update({'daily_calorie_budget': newBudgetValue})
            .eq('user_id', userId);

        // ignore: use_build_context_synchronously
        if (!Navigator.of(dialogContext).canPop()) return;
        Navigator.of(dialogContext).pop(); // Dismiss dialog

        _fetchCalorieData(); // Refresh the main screen data

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily budget updated successfully!'), backgroundColor: Colors.green),
        );

      } catch (e) {
        print('Error updating daily budget: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update budget: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- End Edit Daily Budget ---
} 