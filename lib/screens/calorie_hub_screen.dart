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

  // Constants for calorie validation ranges
  static const int _minFoodLogCalories = 1;
  static const int _maxFoodLogCalories = 10000;
  static const int _minQuickAdjustCalories = 1;
  static const int _maxQuickAdjustCalories = 10000;
  static const int _minBudgetCalories = 500;
  static const int _maxBudgetCalories = 10000;

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

  // For Log Exercise Dialog
  final _logExerciseFormKey = GlobalKey<FormState>();
  late TextEditingController _exerciseCaloriesController;
  late TextEditingController _exerciseDescriptionController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController();
    _descriptionController = TextEditingController();
    _quickAdjustCaloriesController = TextEditingController();
    _editBudgetController = TextEditingController();
    _exerciseCaloriesController = TextEditingController();
    _exerciseDescriptionController = TextEditingController();
    _fetchCalorieData();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _descriptionController.dispose();
    _quickAdjustCaloriesController.dispose();
    _editBudgetController.dispose();
    _exerciseCaloriesController.dispose();
    _exerciseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCalorieData() async {
    if (!mounted) return;

    // Use local variables to hold calculation results before committing to state.
    int? newDailyBudget;
    int newSumDecreaseCalories = 0;
    int newSumIncreaseCalories = 0;
    int? newRemainingCaloriesCalculation;
    String? errorLoadingMessage; // Local variable for error message

    // Initial setState to show loading and clear previous error message from UI.
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
          .maybeSingle();

      newDailyBudget = budgetResponse?['daily_calorie_budget'] as int? ?? _defaultDailyBudget;

      // 2. Fetch Today\'s Calorie Activities
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

      final activityResponse = await _supabase
          .from('calorie_activity')
          .select('calories, operation')
          .eq('user_id', userId)
          .gte('activity_timestamp', startOfDay)
          .lte('activity_timestamp', endOfDay);

      for (var activity in activityResponse as List) {
        final calories = activity['calories'] as int? ?? 0;
        final operation = activity['operation'] as String?;
        if (operation == 'decrease') {
            newSumDecreaseCalories += calories;
        } else if (operation == 'increase') {
            newSumIncreaseCalories += calories;
        }
      }
      
      // Calculate remaining calories using the fetched and calculated local values
      newRemainingCaloriesCalculation = (newDailyBudget ?? _defaultDailyBudget) - newSumDecreaseCalories + newSumIncreaseCalories;

    } catch (e) {
       errorLoadingMessage = 'Failed to load calorie data: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          if (errorLoadingMessage != null) {
            _errorMessage = errorLoadingMessage;
            // When an error occurs, we might not want to update calorie values,
            // or reset them to a default/null state. For now, we only set the error message.
            // The calorie values displayed will be from the last successful fetch or initial state.
          } else {
            // No error, so commit all fetched/calculated values to the state.
            _dailyBudget = newDailyBudget;
            _editBudgetController.text = newDailyBudget?.toString() ?? _defaultDailyBudget.toString(); // Update controller text here
            _consumedToday = newSumDecreaseCalories;
            _remainingCalories = newRemainingCaloriesCalculation;
            _errorMessage = null; // Clear any previous error message if successful
          }
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
                                          ? "You\'re currently in a Calorie Deficit for the day"
                                          : "You\'re currently in a Calorie Surplus for the day",
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
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showLogExerciseDialog,
                                    icon: const Icon(Icons.fitness_center_outlined),
                                    label: const Text('Log Exercise'),
                                  ),
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
            child: Column( // Changed from Center(child: Table(...)) to Column
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Center children horizontally
              children: [
                // Row 1: Consumed (Now a simple Text.rich, centered)
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.titleMedium,
                    children: <TextSpan>[
                      TextSpan(text: 'Calories Consumed Today: '),
                      TextSpan(
                        text: '$_consumedToday kcal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0), // Spacing between consumed and budget box

                // Row 2: Budget (New styled box)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0), // Added padding to make the box narrower
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50, // Very light green background
                      borderRadius: BorderRadius.circular(12.0),
                      // border: Border.all( // Border removed
                      //   color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      //   width: 1.0,
                      // ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        )
                      ]
                    ),
                    child: Column( // Changed from Stack to Column for simpler top-to-bottom layout
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'My Daily Calorie Budget',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisSize: MainAxisSize.min, // Let this Row be as wide as its children
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${_dailyBudget != null ? _dailyBudget! : "N/A"}',
                                  ),
                                  TextSpan(
                                    text: ' kcal',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0), // Spacing
                            Container( // Existing styled container for the icon
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                      return _validateCalorieInput(value, min: _minFoodLogCalories, max: _maxFoodLogCalories, fieldName: 'Calories');
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
    if (!(_foodLogFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final foodItem = _descriptionController.text;
      final caloriesValue = int.parse(_caloriesController.text);

      await _supabase.from('calorie_activity').insert({
        'user_id': userId,
        'activity': 'food_intake',
        'description': foodItem,
        'calories': caloriesValue,
        'operation': 'decrease'
      });

      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      await _fetchCalorieData();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Food logged successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(dialogContext).canPop()) { // Ensure dialog is dismissed on error too
            Navigator.of(dialogContext).pop();
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to log food: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                      return _validateCalorieInput(value, min: _minQuickAdjustCalories, max: _maxQuickAdjustCalories, fieldName: 'Calories');
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
    if (!(_quickAdjustFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final caloriesValue = int.parse(_quickAdjustCaloriesController.text);
      final operationType = isIncrease ? 'increase' : 'decrease';
      final String activityTypeValue = 'manual_adjustment';
      final String descriptionValue =
          isIncrease ? 'Manual calorie addition' : 'Manual calorie subtraction';

      await _supabase.from('calorie_activity').insert({
        'user_id': userId,
        'activity': activityTypeValue,
        'description': descriptionValue,
        'calories': caloriesValue,
        'operation': operationType
      });

      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      await _fetchCalorieData();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Quick adjustment logged: $caloriesValue calories ${isIncrease ? "added" : "subtracted"}!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(dialogContext).canPop()) { // Ensure dialog is dismissed on error too
            Navigator.of(dialogContext).pop();
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text('Failed to log quick adjustment: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                      return _validateCalorieInput(value, min: _minBudgetCalories, max: _maxBudgetCalories, fieldName: 'Budget');
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
    if (!(_editBudgetFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) { // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Capture ScaffoldMessenger state before async operations if context might change
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool dialogPopped = false; // To ensure dialog is popped only once

    try {
      final newBudgetValue = int.parse(_editBudgetController.text);

      await _supabase
          .from('macro_goals')
          .update({'daily_calorie_budget': newBudgetValue})
          .eq('user_id', userId);

      // Pop dialog first if it\'s still active and mounted
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
        dialogPopped = true;
      }

      await _fetchCalorieData(); // Refresh the main screen data (has its own mounted checks)

      if (mounted) { // Check mounted for the main screen context
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Daily budget updated successfully!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      // If dialog wasn\'t popped due to an error before it, try to pop it if it makes sense
      // or just ensure a message is shown on the main screen.
      if (!dialogPopped && Navigator.of(dialogContext).canPop()){
          // Potentially pop here if the error means the dialog should close,
          // but typically errors are shown within the dialog or on the main screen after pop.
          // For now, we assume main screen SnackBar is sufficient.
      }
      if (mounted) { // Check mounted for the main screen context
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to update budget: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- End Edit Daily Budget ---

  // For Log Exercise Dialog
  void _showLogExerciseDialog() {
    // Clear previous values
    _exerciseCaloriesController.clear();
    _exerciseDescriptionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Exercise'),
          content: SingleChildScrollView(
            child: Form(
              key: _logExerciseFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _exerciseCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories*',
                      hintText: 'e.g., 350',
                      icon: Icon(Icons.local_fire_department),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      return _validateCalorieInput(value, min: _minFoodLogCalories, max: _maxFoodLogCalories, fieldName: 'Calories');
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _exerciseDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'What exercise did you do?',
                      hintText: 'e.g., Running, Weightlifting',
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
                _submitExerciseLogForm(dialogContext); // Pass dialogContext to close it later
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitExerciseLogForm(BuildContext dialogContext) async {
    if (!(_logExerciseFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final exerciseItem = _exerciseDescriptionController.text;
      final caloriesValue = int.parse(_exerciseCaloriesController.text);

      await _supabase.from('calorie_activity').insert({
        'user_id': userId,
        'activity': 'exercise',
        'description': exerciseItem,
        'calories': caloriesValue,
        'operation': 'increase' // Corrected: Exercise increases available calories
      });

      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      await _fetchCalorieData();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Exercise logged successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(dialogContext).canPop()) { // Ensure dialog is dismissed on error too
            Navigator.of(dialogContext).pop();
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to log exercise: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 