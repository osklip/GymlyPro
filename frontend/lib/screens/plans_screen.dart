import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import 'create_plan_screen.dart';
import 'plan_details_screen.dart'; // Dodany import ekranu szczegółów

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoje Plany Treningowe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież dane',
            onPressed: () => workoutProvider.fetchPlans(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj',
            onPressed: () async {
              await authProvider.logout();
            },
          )
        ],
      ),
      body: _buildBody(workoutProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlanScreen()),
          );
        },
        tooltip: 'Dodaj nowy plan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(WorkoutProvider provider) {
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
              Text(
                'Wystąpił błąd ładowania danych:',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (provider.plans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Brak zdefiniowanych planów treningowych. Kliknij przycisk +, aby utworzyć pierwszy plan.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: provider.plans.length,
      itemBuilder: (context, index) {
        final plan = provider.plans[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: ListTile(
            leading: Icon(
              plan.isActive ? Icons.play_circle_fill : Icons.assignment,
              color: plan.isActive ? Colors.greenAccent : Colors.white70,
              size: 36,
            ),
            title: Text(
              plan.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Ilość ćwiczeń w planie: ${plan.exercises.length}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanDetailsScreen(plan: plan),
                ),
              );
            },
          ),
        );
      },
    );
  }
}