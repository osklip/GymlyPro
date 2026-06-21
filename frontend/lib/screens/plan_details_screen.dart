import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../providers/exercise_provider.dart';
import '../providers/session_provider.dart';
import '../providers/workout_provider.dart';
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

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia', style: TextStyle(color: Colors.redAccent)),
        content: Text('Czy na pewno chcesz usunąć plan "${widget.plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Anuluj')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (widget.plan.id != null) {
                try {
                  await Provider.of<WorkoutProvider>(context, listen: false).removePlan(widget.plan.id!);
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Powrót do listy planów
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan usunięty.'), backgroundColor: Colors.green));
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Znalezienie aktualnej instancji planu w Providerze (w celu odzwierciedlenia zmian is_active w czasie rzeczywistym)
    final currentPlan = workoutProvider.plans.firstWhere(
      (p) => p.id == widget.plan.id,
      orElse: () => widget.plan,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlan.name),
        actions: [
          IconButton(
            icon: Icon(currentPlan.isActive ? Icons.star : Icons.star_border),
            color: Colors.amber,
            tooltip: currentPlan.isActive ? 'Dezaktywuj plan' : 'Ustaw jako aktywny',
            onPressed: () async {
              if (currentPlan.id != null) {
                try {
                  await workoutProvider.toggleActiveStatus(currentPlan.id!);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.redAccent,
            tooltip: 'Usuń plan',
            onPressed: () => _confirmDeletion(context),
          ),
        ],
      ),
      body: exerciseProvider.isLoading && exerciseProvider.exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, exerciseProvider, currentPlan),
    );
  }

  Widget _buildBody(BuildContext context, ExerciseProvider provider, WorkoutPlan plan) {
    if (provider.errorMessage != null && provider.exercises.isEmpty) {
      return Center(child: Text('Błąd: ${provider.errorMessage}', style: const TextStyle(color: Colors.redAccent)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Przegląd ćwiczeń', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (plan.isActive)
                const Chip(label: Text('PLAN AKTYWNY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: plan.exercises.isEmpty
                ? const Center(child: Text('Ten plan nie zawiera żadnych ćwiczeń.'))
                : ListView.builder(
                    itemCount: plan.exercises.length,
                    itemBuilder: (context, index) {
                      final planEx = plan.exercises[index];
                      final matchedExercises = provider.exercises.where((e) => e.id == planEx.exerciseId).toList();
                      final exerciseName = matchedExercises.isNotEmpty ? matchedExercises.first.name : 'Nieznane ćwiczenie';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent,
                            child: Text('${planEx.order}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Serie: ${planEx.targetSets} | Powtórzenia: ${planEx.targetReps}'
                              '${planEx.targetWeight != null ? ' | Cel: ${planEx.targetWeight} kg' : ''}'),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (plan.exercises.isEmpty || _isStarting) ? null : _startWorkout,
            icon: _isStarting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.play_arrow),
            label: Text(_isStarting ? 'Inicjalizacja środowiska...' : 'Rozpocznij trening', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green, foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}