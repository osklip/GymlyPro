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

  void dispose() {
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(context, listen: false).fetchExercises();
    });
    _addExerciseRow();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    for (var draft in _draftExercises) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addExerciseRow() {
    setState(() {
      _draftExercises.add(DraftPlanExercise());
    });
  }

  void _removeExerciseRow(int index) {
    setState(() {
      final removed = _draftExercises.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submitPlan() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_draftExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan musi zawierać co najmniej jedno ćwiczenie.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    for (var draft in _draftExercises) {
      if (draft.selectedExercise == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Należy wybrać ćwiczenie w każdym dodanym wierszu.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<PlanExercise> exercises = [];
      for (int i = 0; i < _draftExercises.length; i++) {
        final draft = _draftExercises[i];
        
        double? targetWeight;
        if (draft.weightController.text.trim().isNotEmpty) {
          targetWeight = double.tryParse(draft.weightController.text.trim().replaceAll(',', '.'));
        }

        exercises.add(PlanExercise(
          exerciseId: draft.selectedExercise!.id,
          order: i + 1,
          targetSets: int.parse(draft.setsController.text.trim()),
          targetReps: int.parse(draft.repsController.text.trim()),
          targetWeight: targetWeight,
        ));
      }

      final newPlan = WorkoutPlan(
        name: _planNameController.text.trim(),
        isActive: false,
        exercises: exercises,
      );

      await Provider.of<WorkoutProvider>(context, listen: false).addPlan(newPlan);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan treningowy został pomyślnie utworzony.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wystąpił błąd podczas zapisywania: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kreator Planu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _submitPlan,
            tooltip: 'Zapisz plan',
          ),
        ],
      ),
      body: exerciseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : exerciseProvider.errorMessage != null
              ? Center(child: Text('Błąd: ${exerciseProvider.errorMessage}'))
              : _buildForm(exerciseProvider.exercises),
    );
  }

  Widget _buildForm(List<Exercise> availableExercises) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _planNameController,
            decoration: const InputDecoration(
              labelText: 'Nazwa planu (np. Push Hypertrophy)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nazwa planu jest wymagana.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Konfiguracja ćwiczeń:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._draftExercises.asMap().entries.map((entry) {
            final index = entry.key;
            final draft = entry.value;
            return _buildExerciseCard(index, draft, availableExercises);
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addExerciseRow,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj kolejne ćwiczenie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int index, DraftPlanExercise draft, List<Exercise> availableExercises) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kolejność: ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeExerciseRow(index),
                  tooltip: 'Usuń ćwiczenie',
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Exercise>(
              decoration: const InputDecoration(
                labelText: 'Wybierz ćwiczenie',
                border: OutlineInputBorder(),
              ),
              value: draft.selectedExercise,
              items: availableExercises.map((Exercise ex) {
                return DropdownMenuItem<Exercise>(
                  value: ex,
                  child: Text(ex.name),
                );
              }).toList(),
              onChanged: (Exercise? newValue) {
                setState(() {
                  draft.selectedExercise = newValue;
                });
              },
              validator: (value) => value == null ? 'Pole wymagane' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.setsController,
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Brak';
                      if (int.parse(value) <= 0) return '> 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: draft.repsController,
                    decoration: const InputDecoration(
                      labelText: 'Powtórzenia',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Brak';
                      if (int.parse(value) <= 0) return '> 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: draft.weightController,
                    decoration: const InputDecoration(
                      labelText: 'Ciężar (kg)',
                      border: OutlineInputBorder(),
                      hintText: 'Opcjonalne',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}