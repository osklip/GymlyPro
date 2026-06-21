import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../providers/session_provider.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailsScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Zabezpieczenie przed brakiem zbuforowanej historii w sesji
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchHistory();
    });
  }

  // Algorytm szacowania ciężaru maksymalnego (1RM) formułą Epleya
  double _calculateOneRepMax(double weight, int reps) {
    if (reps == 0 || weight <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    
    final List<WorkoutSet> allHistoricalSets = [];
    final List<WorkoutSession> sessionsWithExercise = [];

    // Agregacja danych historycznych dla wyświetlanego ćwiczenia
    for (var session in sessionProvider.history) {
      final matchingSets = session.sets.where((s) => s.exerciseId == widget.exercise.id).toList();
      if (matchingSets.isNotEmpty) {
        allHistoricalSets.addAll(matchingSets);
        sessionsWithExercise.add(session);
      }
    }

    // Wyznaczenie bezwzględnego rekordu obciążenia
    allHistoricalSets.sort((a, b) => b.weight.compareTo(a.weight));
    final double maxHistoricalWeight = allHistoricalSets.isNotEmpty ? allHistoricalSets.first.weight : 0.0;

    // Wyznaczenie najlepszego teoretycznego 1RM
    double estimated1RM = 0.0;
    for (var s in allHistoricalSets) {
      final current1RM = _calculateOneRepMax(s.weight, s.reps);
      if (current1RM > estimated1RM) {
        estimated1RM = current1RM;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.deepPurpleAccent,
                      child: Icon(
                        widget.exercise.equipmentType.toLowerCase().contains('hant') 
                            ? Icons.fitness_center 
                            : Icons.sports_gymnastics,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.exercise.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Partia: ${widget.exercise.targetMuscleGroup}'),
                          backgroundColor: Colors.deepPurple.withOpacity(0.3),
                        ),
                        Chip(
                          label: Text('Sprzęt: ${widget.exercise.equipmentType}'),
                          backgroundColor: Colors.blue.withOpacity(0.3),
                        ),
                        Chip(
                          label: Text('Ruch: ${widget.exercise.movementType}'),
                          backgroundColor: Colors.amber.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Analityka Osiągnięć', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF1E1E2C),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Rekord Ciężaru', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            '${maxHistoricalWeight.toStringAsFixed(1)} kg', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: const Color(0xFF1E1E2C),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Szacowane 1RM', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            '${estimated1RM.toStringAsFixed(1)} kg', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Ostatnie sesje z tym ćwiczeniem', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            if (sessionProvider.isLoading && sessionsWithExercise.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            else if (sessionsWithExercise.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Brak wpisów w historii. Wykonaj to ćwiczenie podczas treningu, aby wygenerować wykres postępów.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ...sessionsWithExercise.take(5).map((session) {
                final sets = session.sets.where((s) => s.exerciseId == widget.exercise.id).toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data sesji: ${session.startTime.day.toString().padLeft(2, '0')}.${session.startTime.month.toString().padLeft(2, '0')}.${session.startTime.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        ...sets.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Seria ${s.setNumber}: ${s.reps} powtórzeń', style: const TextStyle(fontSize: 14)),
                              Text('${s.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}