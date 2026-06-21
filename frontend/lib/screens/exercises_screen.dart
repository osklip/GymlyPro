import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import 'exercise_details_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMuscleGroup = 'Wszystkie';

  final List<String> _muscleGroups = [
    'Wszystkie',
    'Klatka piersiowa',
    'Plecy',
    'Nogi',
    'Barki',
    'Triceps',
    'Biceps',
    'Brzuch',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseProvider>(context, listen: false).fetchExercises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    final filteredExercises = exerciseProvider.exercises.where((ex) {
      final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            ex.equipmentType.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesGroup = _selectedMuscleGroup == 'Wszystkie' || 
                           ex.targetMuscleGroup.toLowerCase().contains(_selectedMuscleGroup.toLowerCase());

      return matchesSearch && matchesGroup;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Ćwiczeń'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież katalog',
            onPressed: () => exerciseProvider.fetchExercises(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Wyszukaj ćwiczenie lub sprzęt...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = _selectedMuscleGroup == group;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(group, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    selectedColor: Colors.deepPurpleAccent,
                    backgroundColor: const Color(0xFF161620),
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedMuscleGroup = group;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          Expanded(
            child: exerciseProvider.isLoading && exerciseProvider.exercises.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : exerciseProvider.errorMessage != null && exerciseProvider.exercises.isEmpty
                    ? Center(child: Text('Błąd bazy: ${exerciseProvider.errorMessage}', style: const TextStyle(color: Colors.red)))
                    : filteredExercises.isEmpty
                        ? const Center(child: Text('Brak ćwiczeń spełniających wybrane kryteria.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final ex = filteredExercises[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                child: ListTile(
                                  // Zastosowano .withValues(alpha: ...) zamiast przestarzałego .withOpacity(...)
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                                    child: const Icon(Icons.fitness_center, color: Colors.deepPurpleAccent, size: 20),
                                  ),
                                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${ex.targetMuscleGroup} | Sprzęt: ${ex.equipmentType}'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailsScreen(exercise: ex),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}