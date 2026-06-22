import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';

class EditPlanDraftExercise {
  Exercise? selectedExercise;
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  void dispose() {
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
}

class EditPlanScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const EditPlanScreen({super.key, required this.plan});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _planNameController;
  final List<EditPlanDraftExercise> _draftExercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _planNameController = TextEditingController(text: widget.plan.name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exProv = Provider.of<ExerciseProvider>(context, listen: false);
      if (exProv.exercises.isEmpty) {
        exProv.fetchExercises().then((_) => _populateForm(exProv));
      } else {
        _populateForm(exProv);
      }
    });
  }

  void _populateForm(ExerciseProvider provider) {
    _draftExercises.clear();
    for (var planEx in widget.plan.exercises) {
      final matches = provider.exercises.where((e) => e.id == planEx.exerciseId).toList();
      final draft = EditPlanDraftExercise();
      draft.selectedExercise = matches.isNotEmpty ? matches.first : null;
      draft.setsController.text = planEx.targetSets.toString();
      draft.repsController.text = planEx.targetReps.toString();
      draft.weightController.text = planEx.targetWeight != null ? planEx.targetWeight.toString() : '';
      _draftExercises.add(draft);
    }

    if (_draftExercises.isEmpty) {
      final emptyDraft = EditPlanDraftExercise();
      emptyDraft.setsController.text = '3';
      emptyDraft.repsController.text = '10';
      _draftExercises.add(emptyDraft);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _planNameController.dispose();
    for (var d in _draftExercises) {
      d.dispose();
    }
    super.dispose();
  }

  void _addExerciseRow() {
    final newDraft = EditPlanDraftExercise();
    newDraft.setsController.text = '3';
    newDraft.repsController.text = '10';
    setState(() => _draftExercises.add(newDraft));
  }

  void _removeExerciseRow(int idx) {
    setState(() {
      _draftExercises[idx].dispose();
      _draftExercises.removeAt(idx);
    });
  }

  Future<void> _submitUpdatedPlan() async {
    if (!(_formKey.currentState?.validate() ?? false) || _draftExercises.isEmpty) return;

    for (var d in _draftExercises) {
      if (d.selectedExercise == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz ćwiczenie w każdym wierszu.'), backgroundColor: Color(0xFFEF4444)),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final List<PlanExercise> exercises = [];
      for (int i = 0; i < _draftExercises.length; i++) {
        final d = _draftExercises[i];
        double? tw;
        final weightText = d.weightController.text.trim().replaceAll(',', '.');
        if (weightText.isNotEmpty) {
          tw = double.tryParse(weightText);
        }
        exercises.add(PlanExercise(
          id: widget.plan.exercises.length > i ? widget.plan.exercises[i].id : null,
          planId: widget.plan.id,
          exerciseId: d.selectedExercise!.id,
          order: i + 1,
          targetSets: int.parse(d.setsController.text.trim()),
          targetReps: int.parse(d.repsController.text.trim()),
          targetWeight: tw,
        ));
      }

      final updatedPlan = WorkoutPlan(
        id: widget.plan.id,
        userId: widget.plan.userId,
        name: _planNameController.text.trim(),
        isActive: widget.plan.isActive,
        createdAt: widget.plan.createdAt,
        exercises: exercises,
      );

      await Provider.of<WorkoutProvider>(context, listen: false).updatePlan(updatedPlan);
      if (!mounted) return;
      Navigator.of(context).pop(); // Zamknij kreator edycji
      Navigator.of(context).pop(); // Zamknij stary widok szczegółów planu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Szablon zaktualizowany pomyślnie!'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProv = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edycja Planu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF10B981), size: 28),
            onPressed: _isSaving ? null : _submitUpdatedPlan,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: exerciseProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _buildForm(exerciseProv.exercises),
    );
  }

  Widget _buildForm(List<Exercise> available) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          TextFormField(
            controller: _planNameController,
            decoration: const InputDecoration(labelText: 'Nazwa planu'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wymagane' : null,
          ),
          const SizedBox(height: 24),
          const Text('PRZYPISANE RUCHY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ..._draftExercises.asMap().entries.map((e) => _buildCard(e.key, e.value, available)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addExerciseRow,
            icon: const Icon(Icons.add, color: Color(0xFF10B981)),
            label: const Text('DODAJ KOLEJNE ĆWICZENIE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard(int idx, EditPlanDraftExercise draft, List<Exercise> available) {
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
                Text('POZYCJA #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0EA5E9))),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeExerciseRow(idx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Exercise>(
              decoration: const InputDecoration(labelText: 'Wybierz z Atlasu'),
              value: available.any((e) => e.id == draft.selectedExercise?.id) ? available.firstWhere((e) => e.id == draft.selectedExercise?.id) : null,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15),
              items: available.map((ex) => DropdownMenuItem<Exercise>(value: ex, child: Text(ex.name))).toList(),
              onChanged: (v) => setState(() => draft.selectedExercise = v),
              validator: (v) => v == null ? 'Wybierz' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: draft.setsController, decoration: const InputDecoration(labelText: 'Serie'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: draft.repsController, decoration: const InputDecoration(labelText: 'Powt.'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: draft.weightController, decoration: const InputDecoration(labelText: 'Kg (Opcj.)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}