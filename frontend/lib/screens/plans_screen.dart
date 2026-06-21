import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
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
        backgroundColor: Colors.white,
        title: const Text('Potwierdzenie usunięcia', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        content: Text('Czy na pewno chcesz trwale usunąć plan "$planName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Anuluj', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Provider.of<WorkoutProvider>(context, listen: false).removePlan(planId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan usunięty.'), backgroundColor: Color(0xFF10B981)));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: const Color(0xFFEF4444)));
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
      await sessionProvider.startWorkout(null); 
      if (!context.mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen(plan: null)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e'), backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() { _isStartingFreestyle = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centrum Treningu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: const Color(0xFF10B981),
            iconSize: 32,
            tooltip: 'Stwórz nowy szablon',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlanScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, workoutProvider),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutProvider provider) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    if (provider.isLoading && provider.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (provider.errorMessage != null && provider.plans.isEmpty) {
      return Center(child: Text('Błąd bazy: ${provider.errorMessage}'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // POPRAWKA: Dynamiczna zamiana banera w zależności od stanu w pamięci
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: sessionProvider.isActive
              ? _buildResumeWorkoutCard(context, sessionProvider, provider)
              : _buildFreestyleCard(context),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gotowe szablony (Przytrzymaj, by usunąć)', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 13)),
              Text('${provider.plans.length} zapisanych', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        Expanded(
          child: provider.plans.isEmpty
              ? const Center(child: Text('Brak zdefiniowanych planów.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: provider.plans.length,
                  itemBuilder: (context, index) {
                    final plan = provider.plans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan))),
                          onLongPress: plan.id == null ? null : () => _confirmDeletion(context, plan.id!, plan.name),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: plan.isActive ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    plan.isActive ? Icons.play_arrow : Icons.assignment_outlined,
                                    color: plan.isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      Text('${plan.exercises.length} przypisanych ruchów', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                if (plan.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                                    child: const Text('AKTYWNY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                                  )
                                else
                                  const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFreestyleCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isStartingFreestyle ? null : () => _startFreestyleWorkout(context),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: _isStartingFreestyle ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3)) : const Icon(Icons.bolt, color: Color(0xFF059669), size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trening Freestyle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      SizedBox(height: 2),
                      Text('Rozpocznij pusty trening ad-hoc i dobieraj ruchy w locie.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Baner wznawiania porzuconej sesji
  Widget _buildResumeWorkoutCard(BuildContext context, SessionProvider sessionProvider, WorkoutProvider workoutProvider) {
    final curr = sessionProvider.currentSession;
    WorkoutPlan? activePlan;
    if (curr?.planId != null) {
      try {
        activePlan = workoutProvider.plans.firstWhere((p) => p.id == curr!.planId);
      } catch (_) {}
    }

    final durationMins = curr?.startTime != null ? DateTime.now().difference(curr!.startTime).inMinutes : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(plan: activePlan))),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Color(0xFF0284C7), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('TRENING W TOKU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFD1FAE5), letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(activePlan?.name ?? 'Trening Freestyle', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text('Trwa $durationMins min • Wykonano ${curr?.sets.length ?? 0} serii', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}