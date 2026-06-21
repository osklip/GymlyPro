import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan.dart';
import '../models/workout_session.dart' as session_models;
import '../providers/session_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/ai_provider.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const ActiveWorkoutScreen({super.key, required this.plan});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, double?> _aiSuggestedWeightsCache = {};
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    for (var planEx in widget.plan.exercises) {
      _repsControllers[planEx.exerciseId] = TextEditingController(text: planEx.targetReps.toString());
      _weightControllers[planEx.exerciseId] = TextEditingController(
        text: planEx.targetWeight != null ? planEx.targetWeight.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _repsControllers.values) {
      controller.dispose();
    }
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _applyAiSuggestion(int exerciseId) async {
    final aiProvider = Provider.of<AiProvider>(context, listen: false);
    
    try {
      final recommendation = await aiProvider.fetchRecommendation(exerciseId);
      if (!mounted) return;

      if (recommendation.suggestedWeight != null) {
        // AI wygenerowało konkretną wartość na podstawie historii
        _weightControllers[exerciseId]?.text = recommendation.suggestedWeight.toString();
        _aiSuggestedWeightsCache[exerciseId] = recommendation.suggestedWeight;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI: ${recommendation.message}'), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Przypadek brzegowy: brak historii
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI: ${recommendation.message}'), 
            backgroundColor: Colors.blueGrey,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd modułu AI: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _saveSet(int exerciseId) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    final repsText = _repsControllers[exerciseId]?.text.trim() ?? '';
    final weightText = _weightControllers[exerciseId]?.text.trim().replaceAll(',', '.') ?? '';

    if (repsText.isEmpty || weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij powtórzenia i obciążenie przed zapisem.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final reps = int.tryParse(repsText) ?? 0;
    final weight = double.tryParse(weightText) ?? 0.0;

    final currentSession = sessionProvider.currentSession;
    final existingSetsCount = currentSession?.sets.where((s) => s.exerciseId == exerciseId).length ?? 0;

    final newSet = session_models.WorkoutSet(
      exerciseId: exerciseId,
      setNumber: existingSetsCount + 1,
      reps: reps,
      weight: weight,
      isSuccessful: true,
      aiSuggestedWeight: _aiSuggestedWeightsCache[exerciseId], // Sprzężenie zwrotne dla AI
    );

    try {
      await sessionProvider.logSet(newSet);
      // Czyszczenie cache dla predykcji po udanym zapisie
      _aiSuggestedWeightsCache.remove(exerciseId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seria zapisana.'), duration: Duration(seconds: 1), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    setState(() {
      _isFinishing = true;
    });

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    try {
      final finishedSession = await sessionProvider.finishWorkout();
      if (!mounted) return;
      
      Navigator.of(context).pop(); 
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Trening Zakończony', style: TextStyle(color: Colors.green)),
          content: Text(
            'Objętość całkowita: ${finishedSession?.totalVolume} kg\n'
            'Zdobyte punkty: ${finishedSession?.earnedPoints}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); 
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd przy zamykaniu treningu: $e'), backgroundColor: Colors.redAccent),
      );
      setState(() {
        _isFinishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final aiProvider = Provider.of<AiProvider>(context);

    if (sessionProvider.isLoading && sessionProvider.currentSession == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trwa Trening', style: TextStyle(color: Colors.greenAccent)),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: widget.plan.exercises.length,
        itemBuilder: (context, index) {
          final planEx = widget.plan.exercises[index];
          final exData = exerciseProvider.exercises.firstWhere(
            (e) => e.id == planEx.exerciseId,
            orElse: () => throw Exception('Nie znaleziono ćwiczenia o ID ${planEx.exerciseId}')
          );
          
          final loggedSets = sessionProvider.currentSession?.sets
              .where((s) => s.exerciseId == planEx.exerciseId).toList() ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${planEx.order}. ${exData.name}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Przycisk wywołujący moduł sztucznej inteligencji
                      IconButton(
                        icon: aiProvider.isLoading(planEx.exerciseId)
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome, color: Colors.amber),
                        tooltip: 'Pobierz rekomendację obciążenia od AI',
                        onPressed: aiProvider.isLoading(planEx.exerciseId) 
                            ? null 
                            : () => _applyAiSuggestion(planEx.exerciseId),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...loggedSets.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text('Seria ${s.setNumber}: ${s.reps}x ${s.weight}kg', style: const TextStyle(color: Colors.white70)),
                        if (s.aiSuggestedWeight != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                          ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _repsControllers[planEx.exerciseId],
                          decoration: const InputDecoration(labelText: 'Powt.', isDense: true, border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _weightControllers[planEx.exerciseId],
                          decoration: const InputDecoration(labelText: 'Kg', isDense: true, border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _saveSet(planEx.exerciseId),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isFinishing ? null : _finishWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isFinishing 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('ZAKOŃCZ TRENING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}