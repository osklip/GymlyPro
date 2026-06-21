import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan.dart';
import '../models/workout_session.dart' as session_models;
import '../providers/session_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/ai_provider.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutPlan? plan;

  const ActiveWorkoutScreen({super.key, this.plan});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, double?> _aiSuggestedWeightsCache = {};
  final Map<int, int?> _rpeSelectedCache = {};
  final List<int> _activeExerciseIds = [];
  
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(context, listen: false).fetchExercises();
    });

    if (widget.plan != null) {
      for (var planEx in widget.plan!.exercises) {
        _initControllersForExercise(
          planEx.exerciseId, 
          defaultReps: planEx.targetReps, 
          defaultWeight: planEx.targetWeight,
        );
      }
    }
  }

  void _initControllersForExercise(int exId, {int? defaultReps, double? defaultWeight}) {
    if (!_activeExerciseIds.contains(exId)) {
      _activeExerciseIds.add(exId);
    }
    _repsControllers[exId] ??= TextEditingController(text: defaultReps != null ? defaultReps.toString() : '10');
    _weightControllers[exId] ??= TextEditingController(text: defaultWeight != null ? defaultWeight.toString() : '');
    // Usunięto niepotrzebne przypisanie 'null' do _rpeSelectedCache[exId]
  }

  void _startRestTimer({int seconds = 90}) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = 0;
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
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
        _weightControllers[exerciseId]?.text = recommendation.suggestedWeight.toString();
        _aiSuggestedWeightsCache[exerciseId] = recommendation.suggestedWeight;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI: ${recommendation.message}'), backgroundColor: Colors.green, duration: const Duration(seconds: 4)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI: ${recommendation.message}'), backgroundColor: Colors.blueGrey, duration: const Duration(seconds: 4)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd modułu AI: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _saveSet(int exerciseId) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    final repsText = _repsControllers[exerciseId]?.text.trim() ?? '';
    final weightText = _weightControllers[exerciseId]?.text.trim().replaceAll(',', '.') ?? '';

    if (repsText.isEmpty || weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uzupełnij powtórzenia i obciążenie.'), backgroundColor: Colors.redAccent));
      return;
    }

    final reps = int.tryParse(repsText) ?? 0;
    final weight = double.tryParse(weightText) ?? 0.0;
    final rpe = _rpeSelectedCache[exerciseId];

    final currentSession = sessionProvider.currentSession;
    final existingSetsCount = currentSession?.sets.where((s) => s.exerciseId == exerciseId).length ?? 0;

    final newSet = session_models.WorkoutSet(
      exerciseId: exerciseId, setNumber: existingSetsCount + 1, reps: reps, weight: weight,
      rpe: rpe, isSuccessful: true, aiSuggestedWeight: _aiSuggestedWeightsCache[exerciseId], 
    );

    try {
      await sessionProvider.logSet(newSet);
      _aiSuggestedWeightsCache.remove(exerciseId);
      
      _startRestTimer(seconds: 90);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seria zapisana. Uruchomiono stoper.'), duration: Duration(seconds: 1), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showAddExerciseModal(BuildContext context, ExerciseProvider provider) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (ctx, scrollController) {
          final availableExercises = provider.exercises.where((ex) => !_activeExerciseIds.contains(ex.id)).toList();
          return Column(
            children: [
              Padding(padding: const EdgeInsets.all(16.0), child: Text('Dodaj ćwiczenie z Atlasu', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
              const Divider(height: 1),
              Expanded(
                child: availableExercises.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Wszystkie dostępne ćwiczenia z bazy zostały już dodane do tego treningu.', textAlign: TextAlign.center)))
                    : ListView.builder(
                        controller: scrollController, itemCount: availableExercises.length,
                        itemBuilder: (ctx, idx) {
                          final ex = availableExercises[idx];
                          return ListTile(
                            // Zastosowanie .withValues() zamiast przestarzałego .withOpacity()
                            leading: CircleAvatar(backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.3), child: const Icon(Icons.fitness_center, size: 18, color: Colors.white)),
                            title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${ex.targetMuscleGroup} | Sprzęt: ${ex.equipmentType}'), trailing: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 24),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              setState(() { _initControllersForExercise(ex.id); });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finishWorkout() async {
    _stopRestTimer();
    setState(() { _isFinishing = true; });
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    try {
      final finishedSession = await sessionProvider.finishWorkout();
      if (!mounted) return;
      Navigator.of(context).pop(); 
      showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Trening Zakończony', style: TextStyle(color: Colors.green)),
          content: Text('Objętość całkowita: ${finishedSession?.totalVolume} kg\nZdobyte punkty: ${finishedSession?.earnedPoints}'),
          actions: [TextButton(onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); }, child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent));
      setState(() { _isFinishing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final aiProvider = Provider.of<AiProvider>(context);

    if (sessionProvider.isLoading && sessionProvider.currentSession == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFreestyle = widget.plan == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFreestyle ? 'Trening Freestyle' : 'Trening: ${widget.plan!.name}', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.add_task, color: Colors.amberAccent), tooltip: 'Dodaj ćwiczenie', onPressed: () => _showAddExerciseModal(context, exerciseProvider))],
      ),
      body: Column(
        children: [
          if (_restSecondsRemaining > 0)
            Container(
              color: Colors.amber.shade900,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.black, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Odpoczynek: ${_restSecondsRemaining ~/ 60}:${(_restSecondsRemaining % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black), visualDensity: VisualDensity.compact),
                        onPressed: () => _startRestTimer(seconds: _restSecondsRemaining + 30),
                        child: const Text('+30s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.close, color: Colors.black), visualDensity: VisualDensity.compact, onPressed: _stopRestTimer),
                    ],
                  )
                ],
              ),
            ),

          Expanded(
            child: _activeExerciseIds.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, size: 80, color: Colors.amberAccent), const SizedBox(height: 16),
                          const Text('Trening Freestyle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                          const Text('Brak przypisanych ruchów. Wybieraj ćwiczenia z Atlasu w trakcie treningu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)), const SizedBox(height: 32),
                          ElevatedButton.icon(icon: const Icon(Icons.add, color: Colors.black), label: const Text('Dodaj pierwsze ćwiczenie', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent), onPressed: () => _showAddExerciseModal(context, exerciseProvider))
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0), itemCount: _activeExerciseIds.length,
                    itemBuilder: (context, index) {
                      final exerciseId = _activeExerciseIds[index];
                      final matchedExercises = exerciseProvider.exercises.where((e) => e.id == exerciseId).toList();
                      final exData = matchedExercises.isNotEmpty ? matchedExercises.first : null;
                      final loggedSets = sessionProvider.currentSession?.sets.where((s) => s.exerciseId == exerciseId).toList() ?? [];
                      final exerciseName = exData?.name ?? 'Ładowanie...';

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
                                  Expanded(child: Text('${index + 1}. $exerciseName', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                  IconButton(icon: aiProvider.isLoading(exerciseId) ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.amber), onPressed: aiProvider.isLoading(exerciseId) ? null : () => _applyAiSuggestion(exerciseId)),
                                ],
                              ),
                              const Divider(),
                              ...loggedSets.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18), const SizedBox(width: 8),
                                    Expanded(child: Row(children: [Text('Seria ${s.setNumber}: ${s.reps}x ${s.weight}kg${s.rpe != null ? ' @ RPE ${s.rpe}' : ''}', style: const TextStyle(color: Colors.white70)), if (s.aiSuggestedWeight != null) const Padding(padding: EdgeInsets.only(left: 6.0), child: Icon(Icons.auto_awesome, color: Colors.amber, size: 14))])),
                                    IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), visualDensity: VisualDensity.compact, onPressed: s.id == null ? null : () async { try { await sessionProvider.removeSet(s.id!); } catch (_) {} }),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(flex: 12, child: TextFormField(controller: _repsControllers[exerciseId], decoration: const InputDecoration(labelText: 'Powt.', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])), const SizedBox(width: 6),
                                  Expanded(flex: 12, child: TextFormField(controller: _weightControllers[exerciseId], decoration: const InputDecoration(labelText: 'Kg', isDense: true, border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))), const SizedBox(width: 6),
                                  Expanded(
                                    flex: 11,
                                    child: DropdownButtonFormField<int?>(
                                      // Zastosowanie initialValue zamiast przestarzałego value
                                      initialValue: _rpeSelectedCache[exerciseId],
                                      decoration: const InputDecoration(labelText: 'RPE', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12), border: OutlineInputBorder()), dropdownColor: const Color(0xFF1E1E2C), icon: const Icon(Icons.arrow_drop_down, size: 16), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      items: const [DropdownMenuItem(value: null, child: Text('-')), DropdownMenuItem(value: 6, child: Text('6')), DropdownMenuItem(value: 7, child: Text('7')), DropdownMenuItem(value: 8, child: Text('8')), DropdownMenuItem(value: 9, child: Text('9')), DropdownMenuItem(value: 10, child: Text('10'))],
                                      onChanged: (val) { setState(() { _rpeSelectedCache[exerciseId] = val; }); },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(onPressed: () => _saveSet(exerciseId), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)), child: const Icon(Icons.add, color: Colors.white)),
                                ],
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('DODAJ ĆWICZENIE Z ATLASU'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Colors.amberAccent, side: const BorderSide(color: Colors.amberAccent)), onPressed: () => _showAddExerciseModal(context, exerciseProvider)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _isFinishing ? null : _finishWorkout, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16)), child: _isFinishing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('ZAKOŃCZ TRENING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }
}