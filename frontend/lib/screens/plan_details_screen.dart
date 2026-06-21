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
    setState(() => _isStarting = true);
    try {
      await Provider.of<SessionProvider>(context, listen: false).startWorkout(widget.plan.id);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(plan: widget.plan)));
    } catch (e) {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    // POPRAWKA: Zmiana "orelse" na poprawne "orElse"
    final currentPlan = workoutProvider.plans.firstWhere((p) => p.id == widget.plan.id, orElse: () => widget.plan);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlan.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(currentPlan.isActive ? Icons.star : Icons.star_border, size: 28), color: const Color(0xFF10B981),
            tooltip: currentPlan.isActive ? 'Dezaktywuj plan' : 'Ustaw jako aktywny',
            onPressed: () async { if (currentPlan.id != null) await workoutProvider.toggleActiveStatus(currentPlan.id!); },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: exerciseProvider.isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))) : _buildBody(context, exerciseProvider, currentPlan),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: (currentPlan.exercises.isEmpty || _isStarting) ? null : _startWorkout,
            child: _isStarting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('ROZPOCZNIJ TEN TRENING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExerciseProvider provider, WorkoutPlan plan) {
    if (provider.errorMessage != null) return Center(child: Text('Błąd: ${provider.errorMessage}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PRZYPISANE ĆWICZENIA', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 12)),
              if (plan.isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)), child: const Text('PLAN DOMYŚLNY', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 10))),
            ],
          ),
        ),
        Expanded(
          child: plan.exercises.isEmpty
              ? const Center(child: Text('Ten plan nie zawiera ćwiczeń.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  itemCount: plan.exercises.length,
                  itemBuilder: (context, index) {
                    final planEx = plan.exercises[index];
                    final matched = provider.exercises.where((e) => e.id == planEx.exerciseId).toList();
                    final exName = matched.isNotEmpty ? matched.first.name : 'Ładowanie...';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: Text('${planEx.order}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 15))),
                          title: Text(exName, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16)),
                          subtitle: Text('Serie: ${planEx.targetSets} | Powt.: ${planEx.targetReps}${planEx.targetWeight != null ? ' | Cel: ${planEx.targetWeight} kg' : ''}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}