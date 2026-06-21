import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchHistory();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<SessionProvider>(context, listen: false).fetchMoreHistory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            tooltip: 'Odśwież od początku',
            onPressed: () => sessionProvider.fetchHistory(refresh: true),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchHistory(refresh: true),
                child: const Text('Spróbuj ponownie'),
              ),
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

    return RefreshIndicator(
      onRefresh: () => provider.fetchHistory(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        // Zwiększamy licznik o 1, jeśli w toku jest dociąganie kolejnej strony
        itemCount: provider.history.length + (provider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.history.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }

          final session = provider.history[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
                child: const Icon(Icons.timeline, color: Colors.deepPurpleAccent),
              ),
              title: Text(
                _formatDate(session.startTime),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text('Objętość: ${session.totalVolume.toStringAsFixed(1)} kg | Punkty: +${session.earnedPoints}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Zarejestrowane serie w tej sesji:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      ...session.sets.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ćwiczenie ID ${s.exerciseId} (Seria ${s.setNumber})', style: const TextStyle(fontSize: 13)),
                            Text('${s.reps}x ${s.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )),
                      const Divider(),
                      if (session.endTime != null)
                        Text('Czas trwania sesji: ${session.endTime!.difference(session.startTime).inMinutes} min', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}