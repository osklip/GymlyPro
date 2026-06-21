import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchHistory();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia Treningów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież historię',
            onPressed: () => sessionProvider.fetchHistory(),
          )
        ],
      ),
      body: _buildBody(sessionProvider),
    );
  }

  Widget _buildBody(SessionProvider provider) {
    if (provider.isLoading && provider.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              const Text('Błąd ładowania historii:', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (provider.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Twój dziennik treningowy jest pusty. Wykonaj pierwszy trening, aby zobaczyć tutaj swoje wyniki.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: provider.history.length,
      itemBuilder: (context, index) {
        final session = provider.history[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.timeline, color: Colors.white),
            ),
            title: Text(
              _formatDate(session.startTime),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Objętość: ${session.totalVolume} kg | Punkty: +${session.earnedPoints}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Szczegóły sesji:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Ilość zarejestrowanych serii: ${session.sets.length}'),
                    if (session.endTime != null)
                      Text('Czas trwania: ${session.endTime!.difference(session.startTime).inMinutes} min'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}