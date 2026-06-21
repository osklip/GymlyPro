import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../providers/session_provider.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailsScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchHistory();
    });
  }

  double _calculateOneRepMax(double weight, int reps) {
    if (reps == 0 || weight <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  // Wektorowy render wykresu 1RM dopasowany do jasnej palety
  Widget _build1RmChart(List<WorkoutSession> sessions) {
    final matchingSessions = sessions.where((sess) => sess.sets.any((s) => s.exerciseId == widget.exercise.id)).toList();

    if (matchingSessions.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Text(
          'Do wygenerowania wektorowej krzywej progresji siłowej 1RM wymagane są co najmniej 2 odbyte sesje treningowe z tym ćwiczeniem.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    final ascSessions = matchingSessions.reversed.toList();
    final List<FlSpot> spots = [];
    double minRm = 999.0;
    double maxRm = 0.0;

    for (int i = 0; i < ascSessions.length; i++) {
      final sess = ascSessions[i];
      final exSets = sess.sets.where((s) => s.exerciseId == widget.exercise.id);
      double maxInSess = 0.0;
      for (var st in exSets) {
        final rm = _calculateOneRepMax(st.weight, st.reps);
        if (rm > maxInSess) maxInSess = rm;
      }
      final roundedRm = double.parse(maxInSess.toStringAsFixed(1));
      spots.add(FlSpot(i.toDouble(), roundedRm));
      if (roundedRm < minRm) minRm = roundedRm;
      if (roundedRm > maxRm) maxRm = roundedRm;
    }

    final minY = (minRm - 2.5).floorToDouble();
    final maxY = (maxRm + 2.5).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 4.0, top: 16.0, bottom: 8.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= ascSessions.length) return const SizedBox.shrink();
                    final date = ascSessions[idx].startTime;
                    return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()} kg', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: (ascSessions.length - 1).toDouble(),
            minY: minY < 0 ? 0 : minY, maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => const Color(0xFF0F172A),
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y} kg', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: true, color: const Color(0xFF0EA5E9), barWidth: 3.5, isStrokeCapRound: true,
                dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4.5, color: const Color(0xFF0EA5E9), strokeWidth: 2, strokeColor: Colors.white)),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [const Color(0xFF0EA5E9).withValues(alpha: 0.25), const Color(0xFF0EA5E9).withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final List<WorkoutSet> allHistoricalSets = [];
    final List<WorkoutSession> sessionsWithExercise = [];

    for (var session in sessionProvider.history) {
      final matchingSets = session.sets.where((s) => s.exerciseId == widget.exercise.id).toList();
      if (matchingSets.isNotEmpty) {
        allHistoricalSets.addAll(matchingSets);
        sessionsWithExercise.add(session);
      }
    }

    allHistoricalSets.sort((a, b) => b.weight.compareTo(a.weight));
    final double maxHistoricalWeight = allHistoricalSets.isNotEmpty ? allHistoricalSets.first.weight : 0.0;

    double estimated1RM = 0.0;
    for (var s in allHistoricalSets) {
      final current1RM = _calculateOneRepMax(s.weight, s.reps);
      if (current1RM > estimated1RM) estimated1RM = current1RM;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(widget.exercise.equipmentType.toLowerCase().contains('hant') ? Icons.fitness_center : Icons.sports_gymnastics, size: 40, color: const Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.exercise.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, 
                      children: [
                        Chip(label: Text('Partia: ${widget.exercise.targetMuscleGroup}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), backgroundColor: const Color(0xFFF1F5F9), side: BorderSide.none), 
                        Chip(label: Text('Sprzęt: ${widget.exercise.equipmentType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), backgroundColor: const Color(0xFFF1F5F9), side: BorderSide.none), 
                        Chip(label: Text('Ruch: ${widget.exercise.movementType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), backgroundColor: const Color(0xFFF1F5F9), side: BorderSide.none),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: Card(color: const Color(0xFFF1F5F9), child: Padding(padding: const EdgeInsets.all(18.0), child: Column(children: [const Text('REKORD CIĘŻARU', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${maxHistoricalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)))])))),
                const SizedBox(width: 12),
                Expanded(child: Card(color: const Color(0xFFF1F5F9), child: Padding(padding: const EdgeInsets.all(18.0), child: Column(children: [const Text('SZACOWANE 1RM', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${estimated1RM.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0EA5E9)))])))),
              ],
            ),
            const SizedBox(height: 20),

            // KARTA WYKRESU 1RM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(children: [Icon(Icons.trending_up, color: Color(0xFF0EA5E9)), SizedBox(width: 8), Text('Progresja Siłowa (1RM)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))]),
                    const Divider(color: Color(0xFFF1F5F9), height: 16),
                    if (sessionProvider.isLoading && sessionsWithExercise.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))) else _build1RmChart(sessionProvider.history),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Ostatnie sesje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF64748B))), const SizedBox(height: 8),
            ...sessionsWithExercise.take(5).map((session) {
              final sets = session.sets.where((s) => s.exerciseId == widget.exercise.id).toList();
              return Card(margin: const EdgeInsets.only(bottom: 10.0), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Data sesji: ${session.startTime.day.toString().padLeft(2, '0')}.${session.startTime.month.toString().padLeft(2, '0')}.${session.startTime.year}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 13)), const SizedBox(height: 8), ...sets.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Seria ${s.setNumber}: ${s.reps} powtórzeń', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))), Text('${s.weight} kg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)))])))])));
            }),
          ],
        ),
      ),
    );
  }
}