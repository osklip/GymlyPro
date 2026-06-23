import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with WidgetsBindingObserver {
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, double?> _aiSuggestedWeightsCache = {};
  final Map<int, int?> _rpeSelectedCache = {};
  final List<int> _activeExerciseIds = [];
  
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isFinishing = false;

  static const String _draftKey = 'gymlypro_workout_draft';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<ExerciseProvider>(context, listen: false).fetchExercises();
      if (widget.plan != null) {
        for (var planEx in widget.plan!.exercises) {
          _initControllersForExercise(planEx.exerciseId, defaultReps: planEx.targetReps, defaultWeight: planEx.targetWeight);
        }
      }
      await _restoreDraftFromDisk();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _saveDraftToDisk();
    }
  }

  void _initControllersForExercise(int exId, {int? defaultReps, double? defaultWeight}) {
    if (!_activeExerciseIds.contains(exId)) _activeExerciseIds.add(exId);
    if (!_repsControllers.containsKey(exId)) {
      final ctrl = TextEditingController(text: defaultReps != null ? defaultReps.toString() : '10');
      ctrl.addListener(_debouncedSaveDraft);
      _repsControllers[exId] = ctrl;
    }
    if (!_weightControllers.containsKey(exId)) {
      final ctrl = TextEditingController(text: defaultWeight != null ? defaultWeight.toString() : '');
      ctrl.addListener(_debouncedSaveDraft);
      _weightControllers[exId] = ctrl;
    }
  }

  void _debouncedSaveDraft() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _saveDraftToDisk);
  }

  Future<void> _saveDraftToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repsMap = _repsControllers.map((k, v) => MapEntry(k.toString(), v.text));
      final weightsMap = _weightControllers.map((k, v) => MapEntry(k.toString(), v.text));
      final rpesMap = _rpeSelectedCache.map((k, v) => MapEntry(k.toString(), v));

      final draftData = {
        'active_ids': _activeExerciseIds, 'reps': repsMap, 'weights': weightsMap, 'rpes': rpesMap,
        'timer_sec': _restSecondsRemaining, 'timer_timestamp': _restSecondsRemaining > 0 ? DateTime.now().millisecondsSinceEpoch : null,
      };
      await prefs.setString(_draftKey, json.encode(draftData));
    } catch (_) {}
  }

  Future<void> _restoreDraftFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_draftKey);
      if (jsonStr == null) return;
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final savedIds = (data['active_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [];
      for (var id in savedIds) {
        _initControllersForExercise(id);
      }

      final repsMap = data['reps'] as Map<String, dynamic>? ?? {};
      final weightsMap = data['weights'] as Map<String, dynamic>? ?? {};
      final rpesMap = data['rpes'] as Map<String, dynamic>? ?? {};

      for (var id in _activeExerciseIds) {
        final idStr = id.toString();
        if (repsMap.containsKey(idStr)) _repsControllers[id]?.text = repsMap[idStr].toString();
        if (weightsMap.containsKey(idStr)) _weightControllers[id]?.text = weightsMap[idStr].toString();
        if (rpesMap.containsKey(idStr)) _rpeSelectedCache[id] = rpesMap[idStr] as int?;
      }

      final targetSec = data['timer_sec'] as int? ?? 0;
      final startMs = data['timer_timestamp'] as int?;
      if (targetSec > 0 && startMs != null) {
        final diffSec = ((DateTime.now().millisecondsSinceEpoch - startMs) / 1000).floor();
        final realSecRemaining = targetSec - diffSec;
        if (realSecRemaining > 0) _startRestTimer(seconds: realSecRemaining);
      }
      setState(() {});
    } catch (_) {}
  }

  void _startRestTimer({int seconds = 90}) {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _saveDraftToDisk();
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
        _saveDraftToDisk();
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = 0);
    _saveDraftToDisk();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _restTimer?.cancel();
    for (var c in _repsControllers.values) { c.dispose(); }
    for (var c in _weightControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _applyAiSuggestion(int exerciseId) async {
    final aiProvider = Provider.of<AiProvider>(context, listen: false);
    try {
      final rec = await aiProvider.fetchRecommendation(exerciseId);
      if (!mounted) return;
      if (rec.suggestedWeight != null) {
        _weightControllers[exerciseId]?.text = rec.suggestedWeight.toString();
        _aiSuggestedWeightsCache[exerciseId] = rec.suggestedWeight;
        _saveDraftToDisk();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI: ${rec.message}', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF0EA5E9), duration: const Duration(seconds: 3)));
      }
    } catch (_) {}
  }

  Future<void> _showAiGuidanceModal(int exerciseId) async {
    final aiProvider = Provider.of<AiProvider>(context, listen: false);
    try {
      final guidance = await aiProvider.fetchGuidance(exerciseId);
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 28), SizedBox(width: 12),
                  Text('Porady AI Trenera', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFE2E8F0)),
              const Text('KLUCZOWE WSKAZÓWKI:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ...guidance.tips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)), Expanded(child: Text(t, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)))]))),
              const SizedBox(height: 16),
              const Text('PUNKTY SKUPIENIA BŁĘDÓW:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ...guidance.focusAreas.map((f) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)), const SizedBox(width: 6), Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)))]))),
              const SizedBox(height: 24),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: () => Navigator.of(ctx).pop(), child: const Text('ZROZUMIANO', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white))),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _saveSet(int exerciseId) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final repsText = _repsControllers[exerciseId]?.text.trim() ?? '';
    final weightText = _weightControllers[exerciseId]?.text.trim().replaceAll(',', '.') ?? '';

    if (repsText.isEmpty || weightText.isEmpty) return;

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
    } catch (_) {}
  }

  void _showAddExerciseModal(BuildContext context, ExerciseProvider provider) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (ctx, scrollController) {
          final available = provider.exercises.where((ex) => !_activeExerciseIds.contains(ex.id)).toList();
          return Column(
            children: [
              const Padding(padding: EdgeInsets.all(20.0), child: Text('Dodaj ćwiczenie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController, itemCount: available.length,
                  itemBuilder: (ctx, idx) {
                    final ex = available[idx];
                    return ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fitness_center, color: Color(0xFF10B981), size: 20)),
                      title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))), subtitle: Text('${ex.targetMuscleGroup} | Sprzęt: ${ex.equipmentType}', style: const TextStyle(color: Color(0xFF64748B))), trailing: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 28),
                      onTap: () { Navigator.of(ctx).pop(); setState(() { _initControllersForExercise(ex.id); }); _saveDraftToDisk(); },
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
    setState(() => _isFinishing = true);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    try {
      final session = await sessionProvider.finishWorkout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey); 
      if (!mounted) return;
      Navigator.of(context).pop(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zapisano! Punkty Exp: +${session?.earnedPoints}', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF10B981)));
    } catch (_) {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final aiProvider = Provider.of<AiProvider>(context);
    final isFreestyle = widget.plan == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFreestyle ? 'Freestyle' : widget.plan!.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        automaticallyImplyLeading: false,
        actions: [
          OutlinedButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Ćwiczenie', style: TextStyle(fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981), side: const BorderSide(color: Color(0xFF10B981), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)), onPressed: () => _showAddExerciseModal(context, exerciseProvider)),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (_restSecondsRemaining > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.timer, color: Colors.white, size: 24), const SizedBox(width: 10), Text('Odpoczynek: ${_restSecondsRemaining ~/ 60}:${(_restSecondsRemaining % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16))]),
                    Row(children: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0EA5E9), minimumSize: const Size(50, 32), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _startRestTimer(seconds: _restSecondsRemaining + 30), child: const Text('+30s', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), visualDensity: VisualDensity.compact, onPressed: _stopRestTimer)])
                  ],
                ),
              ),
            ),
          Expanded(
            child: _activeExerciseIds.isEmpty
                ? Center(child: Text('Dodaj pierwsze ćwiczenie z górnego paska.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _activeExerciseIds.length,
                    itemBuilder: (context, index) {
                      final exerciseId = _activeExerciseIds[index];
                      final matched = exerciseProvider.exercises.where((e) => e.id == exerciseId).toList();
                      final exData = matched.isNotEmpty ? matched.first : null;
                      final loggedSets = sessionProvider.currentSession?.sets.where((s) => s.exerciseId == exerciseId).toList() ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('${index + 1}. ${exData?.name ?? 'Ładowanie...'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)))),
                                    Row(
                                      children: [
                                        IconButton(icon: aiProvider.isLoading(exerciseId) ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 2)) : const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B)), tooltip: 'Porady AI Trenera', onPressed: aiProvider.isLoading(exerciseId) ? null : () => _showAiGuidanceModal(exerciseId)),
                                        IconButton(icon: aiProvider.isLoading(exerciseId) ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Color(0xFF0EA5E9)), tooltip: 'Rekomendacja Ciężaru', onPressed: aiProvider.isLoading(exerciseId) ? null : () => _applyAiSuggestion(exerciseId)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(color: Color(0xFFF1F5F9), height: 16),
                                ...loggedSets.map((s) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.check, color: Color(0xFF10B981), size: 14)), const SizedBox(width: 10),
                                      Expanded(child: Text('Seria ${s.setNumber}: ${s.reps}x ${s.weight} kg${s.rpe != null ? ' @ RPE ${s.rpe}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155), fontSize: 14))),
                                      IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18), visualDensity: VisualDensity.compact, onPressed: s.id == null ? null : () => sessionProvider.removeSet(s.id!)),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(flex: 12, child: TextFormField(controller: _repsControllers[exerciseId], decoration: const InputDecoration(labelText: 'Powt.', isDense: true), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => _debouncedSaveDraft())), const SizedBox(width: 8),
                                    Expanded(
                                      flex: 12, 
                                      child: TextFormField(
                                        controller: _weightControllers[exerciseId], 
                                        decoration: const InputDecoration(
                                          labelText: 'Kg', isDense: true,
                                        ), 
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                                        onChanged: (_) => _debouncedSaveDraft(),
                                      ),
                                    ), 
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 11,
                                      child: DropdownButtonFormField<int?>(
                                        initialValue: _rpeSelectedCache[exerciseId], decoration: const InputDecoration(labelText: 'RPE', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16)), dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down, size: 16), style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                                        items: const [DropdownMenuItem(value: null, child: Text('-')), DropdownMenuItem(value: 6, child: Text('6')), DropdownMenuItem(value: 7, child: Text('7')), DropdownMenuItem(value: 8, child: Text('8')), DropdownMenuItem(value: 9, child: Text('9')), DropdownMenuItem(value: 10, child: Text('10'))],
                                        onChanged: (v) { setState(() => _rpeSelectedCache[exerciseId] = v); _saveDraftToDisk(); },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () => _saveSet(exerciseId), child: const Icon(Icons.add, color: Colors.white, size: 22)),
                                  ],
                                ),
                              ],
                            ),
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
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: _isFinishing ? null : _finishWorkout,
            child: _isFinishing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('ZAKOŃCZ TRENING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }
}