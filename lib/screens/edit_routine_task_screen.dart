// lib/screens/edit_routine_task_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cursor_fitchef/constants/app_theme.dart'; // For theme access

// --- Edit/Create Routine Task Screen ---
// Allows users to create a new routine task definition or edit an existing one.
class EditRoutineTaskScreen extends StatefulWidget {
  final String? taskId; // Null if creating, has value if editing

  const EditRoutineTaskScreen({super.key, this.taskId});

  @override
  State<EditRoutineTaskScreen> createState() => _EditRoutineTaskScreenState();
}

class _EditRoutineTaskScreenState extends State<EditRoutineTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  // State variables for repetition options
  bool _isDaily = true;
  bool _isMonday = false;
  bool _isTuesday = false;
  bool _isWednesday = false;
  bool _isThursday = false;
  bool _isFriday = false;
  bool _isSaturday = false;
  bool _isSunday = false;
  // State variable for task activation
  bool _isActive = true;
  // Loading states
  bool _isLoading = false; // For saving
  bool _isFetching = false; // For loading existing data

  // Helper to determine if we are editing an existing task
  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    // If taskId is provided, load the existing task data for editing
    if (_isEditing) {
      _loadTaskData();
    }
  }

  // --- Load Existing Task Data --- 
  Future<void> _loadTaskData() async {
    if (!_isEditing) return; // Should not happen, but safety check
    setState(() => _isFetching = true);
    try {
      // Fetch the specific task by its ID, selecting only necessary columns
      final response = await Supabase.instance.client
          .from('routine_tasks')
          .select('description, repeat_daily, repeat_monday, repeat_tuesday, repeat_wednesday, repeat_thursday, repeat_friday, repeat_saturday, repeat_sunday, is_active') // Specify columns
          .eq('id', widget.taskId!)
          .single(); // Use .single() as ID should be unique

      // Populate the form fields with the fetched data
      _descriptionController.text = response['description'] ?? '';
      _isDaily = response['repeat_daily'] ?? true;
      _isMonday = response['repeat_monday'] ?? false;
      _isTuesday = response['repeat_tuesday'] ?? false;
      _isWednesday = response['repeat_wednesday'] ?? false;
      _isThursday = response['repeat_thursday'] ?? false;
      _isFriday = response['repeat_friday'] ?? false;
      _isSaturday = response['repeat_saturday'] ?? false;
      _isSunday = response['repeat_sunday'] ?? false;
      _isActive = response['is_active'] ?? true;

    } catch (e) {
      // Handle errors during data fetching
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error loading task: ${e.toString()}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      // Ensure loading indicator is turned off regardless of success/failure
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  // --- Dispose Controllers --- 
  @override
  void dispose() {
    // Clean up the text controller when the widget is removed
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Save Task Logic --- 
  Future<void> _saveTask() async {
    // Validate the form input
    if (!_formKey.currentState!.validate()) {
      return; // Exit if form validation fails
    }

    setState(() => _isLoading = true);

    // Ensure user is logged in
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text("Error: User not logged in. Cannot save task."),
           backgroundColor: Colors.red,
         ));
       }
       setState(() => _isLoading = false);
       return;
    }

    // Prepare data object for Supabase
    final taskData = {
      'user_id': userId, // Ensure user_id is always set for RLS
      'description': _descriptionController.text.trim(),
      'repeat_daily': _isDaily,
      // Only include specific days if daily is false
      'repeat_monday': !_isDaily && _isMonday,
      'repeat_tuesday': !_isDaily && _isTuesday,
      'repeat_wednesday': !_isDaily && _isWednesday,
      'repeat_thursday': !_isDaily && _isThursday,
      'repeat_friday': !_isDaily && _isFriday,
      'repeat_saturday': !_isDaily && _isSaturday,
      'repeat_sunday': !_isDaily && _isSunday,
      'is_active': _isActive,
      // updated_at is handled by the database trigger
    };

    try {
      if (_isEditing) {
        // Update the existing task record
        await Supabase.instance.client
            .from('routine_tasks')
            .update(taskData)
            .eq('id', widget.taskId!); 
      } else {
        // Insert a new task record
        await Supabase.instance.client.from('routine_tasks').insert(taskData);
      }

      // Show success message and navigate back, passing `true` to indicate success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Routine task ${_isEditing ? 'updated' : 'created'} successfully!"),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true); // Return true to signal refresh needed
      }
    } catch (e) {
      // Show error message if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error saving task: ${e.toString()}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      // Ensure loading indicator is turned off
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Build Method --- 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Routine Task' : 'Create Routine Task'),
        // Optionally add delete button here if editing?
      ),
      // Show loading indicator while fetching data for editing
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          // Main form content
          : Form(
              key: _formKey,
              child: ListView( // Use ListView for scrollable content
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Task Description Input
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Task Description',
                      hintText: 'e.g., Morning run, Drink water'
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // --- Repetition Options ---
                  Text('Repeat Options:', style: Theme.of(context).textTheme.titleMedium),
                  // Daily Checkbox
                  CheckboxListTile(
                    title: const Text('Daily'),
                    value: _isDaily,
                    controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                           _isDaily = value;
                           // If daily is checked, uncheck all specific days
                           if (_isDaily) {
                             _isMonday = _isTuesday = _isWednesday = _isThursday = _isFriday = _isSaturday = _isSunday = false;
                           }
                        });
                      }
                    },
                  ),
                  // Specific Day Checkboxes (only visible if Daily is unchecked)
                  if (!_isDaily) ...[
                     Padding(
                       padding: const EdgeInsets.only(left: 16.0), // Indent day options
                       child: Text('Specific days:', style: Theme.of(context).textTheme.bodySmall),
                     ),
                     CheckboxListTile(
                       dense: true, // Make tiles more compact
                       title: const Text('Monday'),
                       value: _isMonday,
                       controlAffinity: ListTileControlAffinity.leading,
                       onChanged: (value) => setState(() => _isMonday = value!),
                     ),
                      CheckboxListTile(
                        dense: true,
                        title: const Text('Tuesday'),
                        value: _isTuesday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isTuesday = value!),
                      ),
                      CheckboxListTile(
                        dense: true,
                        title: const Text('Wednesday'),
                        value: _isWednesday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isWednesday = value!),
                      ),
                       CheckboxListTile(
                        dense: true,
                        title: const Text('Thursday'),
                        value: _isThursday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isThursday = value!),
                      ),
                       CheckboxListTile(
                        dense: true,
                        title: const Text('Friday'),
                        value: _isFriday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isFriday = value!),
                      ),
                       CheckboxListTile(
                        dense: true,
                        title: const Text('Saturday'),
                        value: _isSaturday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isSaturday = value!),
                      ),
                      CheckboxListTile(
                        dense: true,
                        title: const Text('Sunday'),
                        value: _isSunday,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() => _isSunday = value!),
                      ),
                  ],
                  const SizedBox(height: 20),
                  
                  // --- Active Status Switch ---
                  SwitchListTile(
                     title: const Text('Task Enabled'),
                     subtitle: const Text('If disabled, this task won\'t appear in your daily list.'),
                     value: _isActive,
                     onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 30),
                  
                  // --- Save Button ---
                  ElevatedButton(
                    // Disable button while loading
                    onPressed: _isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: Text(_isLoading 
                                ? 'Saving...'
                                : (_isEditing ? 'Update Task' : 'Create Task')
                              ),
                  ),
                ],
              ),
            ),
    );
  }
} 