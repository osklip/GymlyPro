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
        title: const Text('Atlas Ćwiczeń', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            tooltip: 'Odśwież katalog',
            onPressed: () => exerciseProvider.fetchExercises(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Wyszukaj ćwiczenie lub sprzęt...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // POZIOMY PASEK FILTRÓW PARTII MIĘŚNIOWYCH
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = _selectedMuscleGroup == group;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      group, 
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B), 
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (_) => setState(() => _selectedMuscleGroup = group),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0), height: 1),

          // WYNIKI WYSZUKIWANIA Z DOLNYM MARGINESEM 120px NA BELKĘ
          Expanded(
            child: exerciseProvider.isLoading && exerciseProvider.exercises.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : exerciseProvider.errorMessage != null && exerciseProvider.exercises.isEmpty
                    ? Center(child: Text('Błąd: ${exerciseProvider.errorMessage}', style: const TextStyle(color: Color(0xFFEF4444))))
                    : filteredExercises.isEmpty
                        ? const Center(child: Text('Brak ćwiczeń spełniających kryteria.', style: TextStyle(color: Color(0xFF94A3B8))))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final ex = filteredExercises[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.fitness_center, color: Color(0xFF10B981), size: 22),
                                    ),
                                    title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                                    subtitle: Text('${ex.targetMuscleGroup} | Sprzęt: ${ex.equipmentType}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailsScreen(exercise: ex))),
                                  ),
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