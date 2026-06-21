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
        title: const Text('Dziennik Aktywności', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF10B981)), tooltip: 'Odśwież', onPressed: () => sessionProvider.fetchHistory(refresh: true)), const SizedBox(width: 8)],
      ),
      body: _buildBody(sessionProvider),
    );
  }

  Widget _buildBody(SessionProvider provider) {
    if (provider.isLoading && provider.history.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    if (provider.errorMessage != null && provider.history.isEmpty) return Center(child: Text('Błąd: ${provider.errorMessage}'));
    if (provider.history.isEmpty) return const Center(child: Text('Brak zapisanych sesji.', style: TextStyle(color: Color(0xFF94A3B8))));

    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () => provider.fetchHistory(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: provider.history.length + (provider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.history.length) return const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2))));

          final session = provider.history[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ExpansionTile(
                  // POPRAWKA: Przekazanie instancji ShapeBorder usuwającej linie podziału
                  shape: const RoundedRectangleBorder(), 
                  collapsedShape: const RoundedRectangleBorder(),
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.fitness_center, color: Color(0xFF0EA5E9), size: 20)),
                  title: Text(_formatDate(session.startTime), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  subtitle: Text('Objętość: ${session.totalVolume.toStringAsFixed(0)} kg | Punkty: +${session.earnedPoints}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('ZAREJESTROWANE SERIE:', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11)), const SizedBox(height: 8),
                          ...session.sets.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 3.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ćwiczenie ID ${s.exerciseId} (Seria ${s.setNumber})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))), Text('${s.reps}x ${s.weight} kg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)))]))),
                          const Divider(color: Color(0xFFF1F5F9), height: 20),
                          if (session.endTime != null) Text('Czas trwania sesji: ${session.endTime!.difference(session.startTime).inMinutes} min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}