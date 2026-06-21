import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';

class DraftPlanExercise {
  Exercise? selectedExercise;
  final TextEditingController setsController = TextEditingController(text: '3');
  final TextEditingController repsController = TextEditingController(text: '10');
  final TextEditingController weightController = TextEditingController();

  void dispose() { setsController.dispose(); repsController.dispose(); weightController.dispose(); }
}

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _planNameController = TextEditingController();
  final List<DraftPlanExercise> _draftExercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { Provider.of<ExerciseProvider>(context, listen: false).fetchExercises(); });
    _addExerciseRow();
  }

  @override
  void dispose() { _planNameController.dispose(); for (var d in _draftExercises) { d.dispose(); } super.dispose(); }
  void _addExerciseRow() => setState(() => _draftExercises.add(DraftPlanExercise()));
  void _removeExerciseRow(int idx) => setState(() { _draftExercises.removeAt(idx).dispose(); });

  Future<void> _submitPlan() async {
    if (!(_formKey.currentState?.validate() ?? false) || _draftExercises.isEmpty) return;
    for (var d in _draftExercises) { if (d.selectedExercise == null) return; }
    setState(() => _isSaving = true);

    try {
      final List<PlanExercise> exercises = [];
      for (int i = 0; i < _draftExercises.length; i++) {
        final d = _draftExercises[i];
        double? tw;
        if (d.weightController.text.trim().isNotEmpty) tw = double.tryParse(d.weightController.text.trim().replaceAll(',', '.'));
        exercises.add(PlanExercise(exerciseId: d.selectedExercise!.id, order: i + 1, targetSets: int.parse(d.setsController.text.trim()), targetReps: int.parse(d.repsController.text.trim()), targetWeight: tw));
      }
      final newPlan = WorkoutPlan(name: _planNameController.text.trim(), isActive: false, exercises: exercises);
      await Provider.of<WorkoutProvider>(context, listen: false).addPlan(newPlan);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan utworzony!'), backgroundColor: Color(0xFF10B981)));
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kreator Planu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [IconButton(icon: const Icon(Icons.check, color: Color(0xFF10B981), size: 28), onPressed: _isSaving ? null : _submitPlan), const SizedBox(width: 12)],
      ),
      body: exerciseProvider.isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))) : _buildForm(exerciseProvider.exercises),
    );
  }

  Widget _buildForm(List<Exercise> available) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          TextFormField(controller: _planNameController, decoration: const InputDecoration(labelText: 'Nazwa planu (np. Upper Heavy)'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagane' : null),
          const SizedBox(height: 24),
          const Text('SKONFIGURUJ RUCHY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ..._draftExercises.asMap().entries.map((e) => _buildCard(e.key, e.value, available)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _addExerciseRow, icon: const Icon(Icons.add, color: Color(0xFF10B981)), label: const Text('DODAJ ĆWICZENIE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFF10B981), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard(int idx, DraftPlanExercise draft, List<Exercise> available) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ĆWICZENIE #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF10B981))),
                IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20), visualDensity: VisualDensity.compact, onPressed: () => _removeExerciseRow(idx)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Exercise>(
              decoration: const InputDecoration(labelText: 'Wybierz z Atlasu'), initialValue: draft.selectedExercise, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15),
              items: available.map((ex) => DropdownMenuItem<Exercise>(value: ex, child: Text(ex.name))).toList(),
              onChanged: (v) => setState(() => draft.selectedExercise = v), validator: (v) => v == null ? 'Wybierz' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: draft.setsController, decoration: const InputDecoration(labelText: 'Serie'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])), const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: draft.repsController, decoration: const InputDecoration(labelText: 'Powt.'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])), const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: draft.weightController, decoration: const InputDecoration(labelText: 'Kg (Opcjonalne)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}