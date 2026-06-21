import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/session_provider.dart';
import 'create_plan_screen.dart';
import 'plan_details_screen.dart';
import 'active_workout_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _isStartingFreestyle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchPlans();
    });
  }

  void _confirmDeletion(BuildContext context, int planId, String planName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia', style: TextStyle(color: Colors.redAccent)),
        content: Text('Czy na pewno chcesz trwale usunąć plan "$planName"? Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Anuluj')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Provider.of<WorkoutProvider>(context, listen: false).removePlan(planId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan usunięty.'), backgroundColor: Colors.green));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd podczas usuwania: $e'), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  Future<void> _startFreestyleWorkout(BuildContext context) async {
    setState(() { _isStartingFreestyle = true; });
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    try {
      await sessionProvider.startWorkout(null); // planId = null oznacza Freestyle
      if (!context.mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen(plan: null)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd inicjalizacji sesji: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) {
        setState(() { _isStartingFreestyle = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centrum Treningowe'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Odśwież dane', onPressed: () => workoutProvider.fetchPlans()),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Wyloguj', onPressed: () async { await authProvider.logout(); })
        ],
      ),
      body: _buildBody(context, workoutProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePlanScreen()));
        },
        tooltip: 'Stwórz nowy plan', child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutProvider provider) {
    if (provider.isLoading && provider.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text('Wystąpił błąd ładowania danych:', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GŁÓWNY BANER: Trening Freestyle
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Card(
            elevation: 6, shadowColor: Colors.amberAccent.withOpacity(0.15), color: const Color(0xFF28213E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amberAccent.withOpacity(0.6), width: 1.5)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isStartingFreestyle ? null : () => _startFreestyleWorkout(context),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(12)),
                      child: _isStartingFreestyle ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)) : const Icon(Icons.bolt, color: Colors.black, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trening Freestyle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Rozpocznij pusty trening ad-hoc i dodawaj ćwiczenia w locie.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.amberAccent, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Twoje Szablony Treningowe', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white54, fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: provider.plans.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Brak zapisanych planów. Kliknij + w rogu, aby stworzyć szablon.', textAlign: TextAlign.center)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: provider.plans.length,
                  itemBuilder: (context, index) {
                    final plan = provider.plans[index];
                    return Card(
                      elevation: 2, margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: plan.isActive ? Colors.greenAccent.withOpacity(0.4) : Colors.transparent, width: 1.5)),
                      child: ListTile(
                        leading: Icon(plan.isActive ? Icons.play_circle_fill : Icons.assignment, color: plan.isActive ? Colors.greenAccent : Colors.white70, size: 36),
                        title: Row(
                          children: [
                            Expanded(child: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (plan.isActive) const Chip(label: Text('AKTYWNY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.greenAccent, visualDensity: VisualDensity.compact),
                          ],
                        ),
                        subtitle: Text('Ćwiczenia w planie: ${plan.exercises.length}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle') {
                              try { await provider.toggleActiveStatus(plan.id!); } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent));
                              }
                            } else if (value == 'delete') {
                              if (plan.id != null) _confirmDeletion(context, plan.id!, plan.name);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'toggle', child: Row(children: [Icon(plan.isActive ? Icons.star_border : Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 8), Text(plan.isActive ? 'Oznacz jako nieaktywny' : 'Ustaw jako aktywny')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text('Usuń plan', style: TextStyle(color: Colors.redAccent))])),
                          ],
                        ),
                        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => PlanDetailsScreen(plan: plan))); },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}