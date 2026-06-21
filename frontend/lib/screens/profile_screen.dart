import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/measurement_provider.dart';
import '../providers/achievement_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchProfile();
      Provider.of<MeasurementProvider>(context, listen: false).fetchMeasurements();
      Provider.of<AchievementProvider>(context, listen: false).fetchAchievements();
    });
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'emoji_events': return Icons.emoji_events;
      case 'fitness_center': return Icons.fitness_center;
      case 'military_tech': return Icons.military_tech;
      case 'diamond': return Icons.diamond;
      default: return Icons.stars;
    }
  }

  // Wektorowy render wykresu dopasowany do jasnego motywu
  Widget _buildWeightChart(List<BodyMeasurement> measurements) {
    if (measurements.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Text(
          'Zarejestruj co najmniej 2 pomiary wagi w różnych dniach, aby wygenerować wektorowy wykres wahań masy ciała.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    final ascList = List<BodyMeasurement>.from(measurements).reversed.toList();

    final List<FlSpot> spots = [];
    double minW = ascList.first.weight;
    double maxW = ascList.first.weight;

    for (int i = 0; i < ascList.length; i++) {
      final w = ascList[i].weight;
      spots.add(FlSpot(i.toDouble(), w));
      if (w < minW) minW = w;
      if (w > maxW) maxW = w;
    }

    final minY = (minW - 1.5).floorToDouble();
    final maxY = (maxW + 1.5).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 4.0, top: 16.0, bottom: 8.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true, 
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= ascList.length) return const SizedBox.shrink();
                    final date = ascList[idx].measuredAt;
                    if (date == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()} kg', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (ascList.length - 1).toDouble(),
            minY: minY < 0 ? 0 : minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => const Color(0xFF0F172A),
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y} kg', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF10B981),
                barWidth: 3.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4.5, color: const Color(0xFF10B981), strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF10B981).withValues(alpha: 0.25), const Color(0xFF10B981).withValues(alpha: 0.0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final bfController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);
    if (measurementProvider.measurements.isNotEmpty) {
      heightController.text = measurementProvider.measurements.first.height.toString();
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24.0, right: 24.0, top: 24.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nowy pomiar ciała', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), const SizedBox(height: 16),
              TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Waga (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v == null || v.trim().isEmpty || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Błąd' : null), const SizedBox(height: 12),
              TextFormField(controller: heightController, decoration: const InputDecoration(labelText: 'Wzrost (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v == null || v.trim().isEmpty || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Błąd' : null), const SizedBox(height: 12),
              TextFormField(controller: bfController, decoration: const InputDecoration(labelText: 'Tkanka tłuszczowa % (Opcjonalnie)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)), const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final w = double.parse(weightController.text.replaceAll(',', '.'));
                    final h = double.parse(heightController.text.replaceAll(',', '.'));
                    final bfText = bfController.text.trim();
                    final bf = bfText.isNotEmpty ? double.parse(bfText.replaceAll(',', '.')) : null;
                    try {
                      await measurementProvider.addMeasurement(BodyMeasurement(weight: w, height: h, bodyFatPercentage: bf));
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                    } catch (_) {}
                  }
                },
                child: const Text('ZAPISZ POMIAR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ), const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final measurementProvider = Provider.of<MeasurementProvider>(context);
    final achievementProvider = Provider.of<AchievementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Analityka', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Color(0xFFEF4444)), tooltip: 'Wyloguj', onPressed: () async { await Provider.of<AuthProvider>(context, listen: false).logout(); }), const SizedBox(width: 8)],
      ),
      body: _buildBody(context, userProvider, measurementProvider, achievementProvider),
    );
  }

  Widget _buildBody(BuildContext context, UserProvider uProvider, MeasurementProvider mProvider, AchievementProvider aProvider) {
    if (uProvider.isLoading && uProvider.profile == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    final profile = uProvider.profile;
    
    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () async { await uProvider.refreshProfile(); await mProvider.fetchMeasurements(); await aProvider.fetchAchievements(); },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (profile != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 2.5)),
                child: CircleAvatar(radius: 46, backgroundColor: const Color(0xFFD1FAE5), child: Text(profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF065F46)))),
              ),
            ),
            const SizedBox(height: 12),
            Text(profile.displayName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF0F172A),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text('POZIOM', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('${profile.level}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.w900))]),
                    Container(height: 40, width: 1, color: const Color(0xFF334155)),
                    Column(children: [const Text('PUNKTY EXP', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('${profile.totalPoints}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // KARTA WYKRESU WAGI
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [Icon(Icons.monitor_weight, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Masa Ciała', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))]),
                      TextButton.icon(onPressed: () => _showAddMeasurementDialog(context), icon: const Icon(Icons.add, size: 18, color: Color(0xFF10B981)), label: const Text('Dodaj', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  if (mProvider.isLoading && mProvider.measurements.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Color(0xFF10B981)))) else _buildWeightChart(mProvider.measurements),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Gablota Osiągnięć', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          if (aProvider.isLoading && aProvider.allAchievements.isEmpty) const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))) else ...aProvider.allAchievements.map((ach) {
            final isUnlocked = aProvider.isUnlocked(ach.id);
            final earnedDate = aProvider.getEarnedDate(ach.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Card(
                color: isUnlocked ? const Color(0xFFECFDF5) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isUnlocked ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0), width: isUnlocked ? 1.5 : 1.0)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  leading: CircleAvatar(backgroundColor: isUnlocked ? const Color(0xFF10B981) : const Color(0xFFF1F5F9), child: Icon(_getIcon(ach.iconUrl), color: isUnlocked ? Colors.white : const Color(0xFF94A3B8))),
                  title: Row(children: [Expanded(child: Text(ach.name, style: TextStyle(fontWeight: FontWeight.w900, color: isUnlocked ? const Color(0xFF065F46) : const Color(0xFF64748B)))), if (isUnlocked) const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text(ach.description, style: TextStyle(color: isUnlocked ? const Color(0xFF065F46).withValues(alpha: 0.8) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)), if (isUnlocked && earnedDate != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('Zdobyto: ${earnedDate.day.toString().padLeft(2, '0')}.${earnedDate.month.toString().padLeft(2, '0')}.${earnedDate.year}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800))) else Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('Wymagane: ${ach.requiredPoints} pkt', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)))]),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          const Text('Historia wpisów wagowych', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF64748B))), const SizedBox(height: 8),
          ...mProvider.measurements.map((m) => Card(margin: const EdgeInsets.only(bottom: 8.0), child: ListTile(dense: true, leading: const Icon(Icons.scale, color: Color(0xFF10B981)), title: Text('${m.weight} kg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))), subtitle: Text('Wzrost: ${m.height} cm ${m.bodyFatPercentage != null ? '| BF: ${m.bodyFatPercentage}%' : ''}', style: const TextStyle(color: Color(0xFF64748B))), trailing: m.measuredAt != null ? Text('${m.measuredAt!.day.toString().padLeft(2, '0')}.${m.measuredAt!.month.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))) : null))),
        ],
      ),
    );
  }
}