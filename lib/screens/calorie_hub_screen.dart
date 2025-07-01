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
  List<Map<String, dynamic>> _activityHistory = []; // Add this line to store activity history

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
    int newFoodIntakeCalories = 0;
    int? newRemainingCaloriesCalculation;
    String? errorLoadingMessage;
    List<Map<String, dynamic>> newActivityHistory = [];

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

      // 2. Fetch Today's Calorie Activities
      final nowLocal = DateTime.now();
      final localStartOfDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 0, 0, 0, 0);
      final localEndOfDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59, 999);

      final utcStartOfDay = localStartOfDay.toUtc();
      final utcEndOfDay = localEndOfDay.toUtc();

      final startOfDayStringForQuery = utcStartOfDay.toIso8601String();
      final endOfDayStringForQuery = utcEndOfDay.toIso8601String();

      final activityResponse = await _supabase
          .from('calorie_activity')
          .select('id, calories, operation, activity, description, activity_timestamp')
          .eq('user_id', userId)
          .gte('activity_timestamp', startOfDayStringForQuery)
          .lte('activity_timestamp', endOfDayStringForQuery)
          .order('activity_timestamp', ascending: false);

      print('Debug: Activity Response: $activityResponse'); // Debug log

      for (final activityEntry in activityResponse) {
        final calories = activityEntry['calories'] as int? ?? 0;
        final operation = activityEntry['operation'] as String?;
        final activityType = activityEntry['activity'] as String?;
        final description = activityEntry['description'] as String? ?? '';
        final timestamp = activityEntry['activity_timestamp'] as String?;
        final id = activityEntry['id'];

        print('Debug: Processing activity: $activityType, $description, $calories'); // Debug log

        // Add to activity history with ID
        newActivityHistory.add({
          'id': id,
          'calories': calories,
          'operation': operation,
          'activity': activityType,
          'description': description,
          'timestamp': timestamp,
        });

        if (operation == 'decrease') {
          newSumDecreaseCalories += calories;
        } else if (operation == 'increase') {
          newSumIncreaseCalories += calories;
        }

        if (activityType == 'food_intake') {
          newFoodIntakeCalories += calories;
        }
      }

      print('Debug: Final activity history: $newActivityHistory'); // Debug log

      newRemainingCaloriesCalculation = (newDailyBudget ?? _defaultDailyBudget) - newSumDecreaseCalories + newSumIncreaseCalories;

    } catch (e) {
      errorLoadingMessage = 'Failed to load calorie data: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          if (errorLoadingMessage != null) {
            _errorMessage = errorLoadingMessage;
          } else {
            _dailyBudget = newDailyBudget;
            _editBudgetController.text = newDailyBudget?.toString() ?? _defaultDailyBudget.toString();
            _consumedToday = newFoodIntakeCalories;
            _remainingCalories = newRemainingCaloriesCalculation;
            _activityHistory = newActivityHistory;
            _errorMessage = null;
          }
          _isLoading = false;
        });
      }
    }
  }

  // Add this new method to format the timestamp
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp).toLocal();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Add this new method to get the appropriate icon for each activity
  Icon _getActivityIcon(String? activity) {
    switch (activity) {
      case 'food_intake':
        return const Icon(Icons.fastfood_outlined, color: Colors.orange);
      case 'exercise':
        return const Icon(Icons.fitness_center_outlined, color: Colors.green);
      case 'manual_adjustment':
        return const Icon(Icons.edit_outlined, color: Colors.blue);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCalorieData,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  'Error: $_errorMessage',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
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
                                  const SizedBox(height: 24),
                                  // Add the new Activity History section
                                  const Text(
                                    'Today\'s Activity History',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_activityHistory.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No activities logged today',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _activityHistory.length,
                                        itemBuilder: (context, index) {
                                          final activity = _activityHistory[index];
                                          final isIncrease = activity['operation'] == 'increase';
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            child: ListTile(
                                              leading: _getActivityIcon(activity['activity']),
                                              title: Text(
                                                activity['description'] ?? 'No description',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                _formatTimestamp(activity['timestamp']),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${isIncrease ? '+' : '-'}${activity['calories']} kcal',
                                                    style: TextStyle(
                                                      color: isIncrease ? Colors.green : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                                    onPressed: () => _showEditActivityDialog(activity),
                                                    tooltip: 'Edit',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 20),
                                                    onPressed: () => _deleteActivity(activity),
                                                    tooltip: 'Delete',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
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
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'What did you eat?',
                      hintText: 'e.g., Apple and peanut butter',
                      icon: Icon(Icons.description_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    // Can be optional, so no validator or a lenient one
                  ),
                  const SizedBox(height: 16),
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
                    controller: _exerciseDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'What exercise did you do?',
                      hintText: 'e.g., Running, Weightlifting',
                      icon: Icon(Icons.description_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    // Can be optional, so no validator or a lenient one
                  ),
                  const SizedBox(height: 16),
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

  // Add these new methods for edit and delete functionality
  void _showEditActivityDialog(Map<String, dynamic> activity) {
    final controller = TextEditingController(text: activity['description']);
    final caloriesController = TextEditingController(text: activity['calories'].toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          content: SingleChildScrollView(
            child: Form(
              key: _foodLogFormKey, // Reuse existing form key
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: caloriesController,
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
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Apple and peanut butter',
                      icon: Icon(Icons.description_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (!(_foodLogFormKey.currentState?.validate() ?? false)) return;

                try {
                  await _supabase
                      .from('calorie_activity')
                      .update({
                        'description': controller.text,
                        'calories': int.parse(caloriesController.text),
                      })
                      .eq('id', activity['id']);

                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  await _fetchCalorieData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update activity: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteActivity(Map<String, dynamic> activity) async {
    try {
      // First verify we have a valid ID
      final activityId = activity['id'];
      if (activityId == null) {
        throw 'Activity ID is missing';
      }

      // Delete the activity
      final response = await _supabase
          .from('calorie_activity')
          .delete()
          .eq('id', activityId)
          .select()
          .single();

      if (response == null) {
        throw 'Failed to delete activity';
      }

      await _fetchCalorieData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete activity: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
} 