import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../providers/exercise_provider.dart';
import '../providers/session_provider.dart';
import 'active_workout_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const PlanDetailsScreen({super.key, required this.plan});

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(context, listen: false).fetchExercises();
    });
  }

  Future<void> _startWorkout() async {
    setState(() {
      _isStarting = true;
    });

    try {
      await Provider.of<SessionProvider>(context, listen: false).startWorkout(widget.plan.id);
      
      if (!mounted) return;
      
      // Przekierowanie do ekranu aktywnego treningu z usunięciem historii nawigacji
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(plan: widget.plan)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się rozpocząć sesji: $e'), backgroundColor: Colors.redAccent),
      );
      setState(() {
        _isStarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
      ),
      body: exerciseProvider.isLoading && exerciseProvider.exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, exerciseProvider),
    );
  }

  Widget _buildBody(BuildContext context, ExerciseProvider provider) {
    if (provider.errorMessage != null && provider.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Błąd ładowania danych ćwiczeń: ${provider.errorMessage}',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Przegląd ćwiczeń',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.plan.exercises.isEmpty
                ? const Center(child: Text('Ten plan nie zawiera żadnych ćwiczeń.'))
                : ListView.builder(
                    itemCount: widget.plan.exercises.length,
                    itemBuilder: (context, index) {
                      final planEx = widget.plan.exercises[index];
                      final matchedExercises = provider.exercises.where((e) => e.id == planEx.exerciseId).toList();
                      final exerciseName = matchedExercises.isNotEmpty 
                          ? matchedExercises.first.name 
                          : 'Nieznane ćwiczenie (ID: ${planEx.exerciseId})';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent,
                            child: Text('${planEx.order}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Serie: ${planEx.targetSets} | Powtórzenia: ${planEx.targetReps}'
                            '${planEx.targetWeight != null ? ' | Cel: ${planEx.targetWeight} kg' : ''}'
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (widget.plan.exercises.isEmpty || _isStarting) ? null : _startWorkout,
            icon: _isStarting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_isStarting ? 'Inicjalizacja środowiska...' : 'Rozpocznij trening', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}