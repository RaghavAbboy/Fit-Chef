// --- Imports ---
import 'package:cursor_fitchef/constants/app_theme.dart'; // For potential theme usage
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase client access
import 'edit_routine_task_screen.dart'; // Import the new screen

// --- Daily Routine Screen Widget ---
// This screen displays the user's daily routine tasks, separated into
// "Today's Routine" and "Done and Dusted".
class DailyRoutineScreen extends StatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

// --- Daily Routine Screen State ---
class _DailyRoutineScreenState extends State<DailyRoutineScreen> {
  bool _isLoading = true; // Flag to show a loading indicator
  String? _errorMessage; // To store any error messages during data fetch
  List<Map<String, dynamic>> _todayTasks = []; // List for incomplete tasks
  List<Map<String, dynamic>> _doneTasks = []; // List for completed tasks

  @override
  void initState() {
    super.initState();
    // Fetch tasks when the screen is first loaded
    _fetchDailyTasks(); 
  }

  // --- Fetch Daily Tasks Logic ---
  Future<void> _fetchDailyTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      final today = DateTime.now();
      final currentDateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // 1. Ensure today's tasks are generated
      await Supabase.instance.client.rpc(
        'generate_daily_tasks_for_user',
        params: {'target_user_id': userId, 'target_date': currentDateString},
      );

      // 2. Fetch today's tasks with their descriptions
      final response = await Supabase.instance.client
          .from('daily_task_status')
          .select('''
            id, 
            is_completed,
            routine_task_id,
            routine_tasks!inner ( id, description ) 
          ''') // Use !inner join to only get statuses with matching routines
          .eq('user_id', userId)
          .eq('task_date', currentDateString);
          
      final List<Map<String, dynamic>> allTasks = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> todayList = [];
      final List<Map<String, dynamic>> doneList = [];

      for (var task in allTasks) {
        if (task['is_completed'] == true) {
          doneList.add(task);
        } else {
          todayList.add(task);
        }
      }

      if (mounted) { // Check if widget is still mounted before calling setState
         setState(() {
           _todayTasks = todayList;
           _doneTasks = doneList;
           _isLoading = false;
         });
      } else {
         // Widget not mounted after fetch, do nothing
      }

    } catch (e) {
       if (mounted) { // Check if widget is still mounted
         setState(() {
           _isLoading = false;
           _errorMessage = "Error fetching tasks: ${e.toString()}";
         });
       }
    }
  }

  // --- Update Task Completion Status ---
  Future<void> _updateTaskStatus(String dailyStatusId, bool isCompleted) async {
    // Optimistic UI update: Move the task immediately
    Map<String, dynamic>? taskToMove;
    int originalIndex = -1;
    List<Map<String, dynamic>> sourceList;
    List<Map<String, dynamic>> destinationList;

    if (isCompleted) {
        sourceList = _todayTasks;
        destinationList = _doneTasks;
        originalIndex = sourceList.indexWhere((task) => task['id'] == dailyStatusId);
    } else {
        sourceList = _doneTasks;
        destinationList = _todayTasks;
        originalIndex = sourceList.indexWhere((task) => task['id'] == dailyStatusId);
    }

    if (originalIndex != -1) {
       taskToMove = sourceList.removeAt(originalIndex);
       taskToMove['is_completed'] = isCompleted; // Update local state
       destinationList.add(taskToMove);
       // Trigger UI update
       if (mounted) setState(() {});
    } else {
       // Task not found locally, might be an issue or already moved.
       return; 
    }

    // Perform database update
    try {
       await Supabase.instance.client
        .from('daily_task_status')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null
        })
        .eq('id', dailyStatusId);
       // Update succeeded, UI is already updated optimistically
    } catch (e) {
       // Revert optimistic UI update on error
        if (mounted) {
          setState(() {
            // Move task back to original list
            destinationList.removeWhere((task) => task['id'] == dailyStatusId);
            if (taskToMove != null) {
               taskToMove['is_completed'] = !isCompleted; // Revert local state
               sourceList.insert(originalIndex, taskToMove); // Put it back where it was
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating task: ${e.toString()}"), backgroundColor: Colors.red),
          );
        }
    }
  }

  // --- Delete Routine Task Definition ---
  Future<void> _deleteRoutineTask(String routineTaskId, String description) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine Task?'),
        content: Text('Are you sure you want to permanently delete the routine task "$description"? This will remove it from all future daily lists.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Deleting the routine task will cascade delete related daily_task_status entries
      await Supabase.instance.client.from('routine_tasks').delete().eq('id', routineTaskId);
      // Refresh the list after delete
      _fetchDailyTasks(); 
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting task: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  // --- Navigate to Create/Edit Task Screen ---
  void _navigateToEditTask([String? routineTaskId]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditRoutineTaskScreen(taskId: routineTaskId)),
    );
    // If the edit screen returned true (meaning save occurred), refresh tasks.
    if (result == true && mounted) {
      _fetchDailyTasks();
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Routine"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditTask(), 
        tooltip: 'Add Routine Task',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, textTheme), // Extracted body logic
    );
  }

  // --- Build Body Helper ---
  Widget _buildBody(BuildContext context, TextTheme textTheme) {
     if (_isLoading) {
       return const Center(child: CircularProgressIndicator());
     } 
     if (_errorMessage != null) {
       // Provide a way to retry if there was an error
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
             const SizedBox(height: 10),
             ElevatedButton(onPressed: _fetchDailyTasks, child: const Text('Retry'))
           ],
         )
       );
     }
     if (_todayTasks.isEmpty && _doneTasks.isEmpty) {
        return _buildEmptyState(); // Show empty state with create prompt
     }
     
     // Main list view
     return RefreshIndicator( 
        onRefresh: _fetchDailyTasks, 
        child: ListView( 
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Today's Routine Section ---
            if (_todayTasks.isNotEmpty || _doneTasks.isNotEmpty) ...[
               Text("Today's Routine", style: textTheme.headlineSmall),
               const SizedBox(height: 8),
            ],
            if (_todayTasks.isEmpty && _doneTasks.isNotEmpty) ...[
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Text("All tasks done for today!", style: TextStyle(color: Colors.grey.shade600)),
               )
            ] else if (_todayTasks.isEmpty && _doneTasks.isEmpty) ...[
               // This case is handled by _buildEmptyState above
            ] else ...[
               Column(children: _todayTasks.map((task) => _buildTaskTile(task)).toList()),
            ],
            
            // --- Done and Dusted Section ---
            if (_doneTasks.isNotEmpty) ...[
               const SizedBox(height: 24), 
               const Divider(), 
               const SizedBox(height: 16),
               Text("Done and Dusted", style: textTheme.headlineSmall?.copyWith(color: Colors.grey)),
               const SizedBox(height: 8),
               Column(children: _doneTasks.map((task) => _buildTaskTile(task)).toList()),
            ],
          ],
        ),
      );
  }

  // --- Helper Widget: Build Empty State UI ---
  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.list_alt_rounded, size: 60, color: Colors.grey.shade400),
           const SizedBox(height: 16),
           const Text(
             "You haven't set up any routine tasks yet.",
             style: TextStyle(fontSize: 16, color: Colors.grey),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 8),
           ElevatedButton.icon(
             icon: const Icon(Icons.add),
             label: const Text("Create your first task"),
             onPressed: () => _navigateToEditTask(), 
           )
         ],
       ),
     );
   }

  // --- Helper Widget: Build Task Tile ---
  Widget _buildTaskTile(Map<String, dynamic> task) {
    // Safely access nested description and routine task ID
    final routineTaskInfo = task['routine_tasks'];
    final description = routineTaskInfo?['description'] ?? 'Task description missing';
    final routineTaskId = routineTaskInfo?['id']; 
    final bool isCompleted = task['is_completed'] ?? false;
    final String dailyStatusId = task['id']; // ID of the daily_task_status row

    return ListTile(
      contentPadding: EdgeInsets.zero, // Use padding within elements if needed
      leading: Checkbox(
        value: isCompleted,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            _updateTaskStatus(dailyStatusId, newValue);
          }
        },
      ),
      title: Text(
        description,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          color: isCompleted ? Colors.grey : null,
        ),
      ),
      trailing: (routineTaskId == null) ? null : Row( // Only show actions if we have the routine ID
        mainAxisSize: MainAxisSize.min, 
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
            onPressed: () => _navigateToEditTask(routineTaskId), 
            tooltip: 'Edit Routine Task',
            visualDensity: VisualDensity.compact, // Make icons tighter
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
            onPressed: () => _deleteRoutineTask(routineTaskId, description), 
            tooltip: 'Delete Routine Task',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
} 