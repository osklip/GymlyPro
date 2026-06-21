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

  Widget _buildWeightChart(List<BodyMeasurement> measurements) {
    if (measurements.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Text(
          'Zarejestruj co najmniej 2 pomiary wagi w różnych dniach, aby wygenerować wektorowy wykres wahań masy ciała.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
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
            gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                        style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
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
                    return Text('${value.toInt()} kg', style: const TextStyle(color: Colors.white54, fontSize: 10));
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
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.amberAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  // Zastosowanie nowoczesnego API eliminującego błąd utraty precyzji
                  color: Colors.amberAccent.withValues(alpha: 0.15),
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
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16.0, right: 16.0, top: 24.0,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Rejestracja pomiaru', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Waga (kg)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => (val == null || val.trim().isEmpty || double.tryParse(val.replaceAll(',', '.')) == null) ? 'Błąd formatu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Wzrost (cm)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => (val == null || val.trim().isEmpty || double.tryParse(val.replaceAll(',', '.')) == null) ? 'Błąd formatu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bfController,
                decoration: const InputDecoration(labelText: 'Tkanka tłuszczowa % (Opcjonalnie)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final weight = double.parse(weightController.text.replaceAll(',', '.'));
                    final height = double.parse(heightController.text.replaceAll(',', '.'));
                    final bfText = bfController.text.trim();
                    final bf = bfText.isNotEmpty ? double.parse(bfText.replaceAll(',', '.')) : null;

                    try {
                      await measurementProvider.addMeasurement(BodyMeasurement(
                        weight: weight, height: height, bodyFatPercentage: bf,
                      ));
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pomiar zapisany pomyślnie.'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: const Text('Zapisz pomiar'),
              ),
              const SizedBox(height: 24),
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
        title: const Text('Profil i Analityka'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      body: _buildBody(context, userProvider, measurementProvider, achievementProvider),
    );
  }

  Widget _buildBody(BuildContext context, UserProvider uProvider, MeasurementProvider mProvider, AchievementProvider aProvider) {
    if (uProvider.isLoading && uProvider.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = uProvider.profile;
    
    return RefreshIndicator(
      onRefresh: () async {
        await uProvider.refreshProfile();
        await mProvider.fetchMeasurements();
        await aProvider.fetchAchievements();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (profile != null) ...[
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 46,
              backgroundColor: Colors.deepPurpleAccent,
              child: Text(
                profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 36),
                    const SizedBox(height: 4),
                    Text('POZIOM ${profile.level}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    const SizedBox(height: 2),
                    Text('Punkty doświadczenia: ${profile.totalPoints}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF221C35),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [Icon(Icons.trending_down, color: Colors.amberAccent), SizedBox(width: 8), Text('Trend Masy Ciała', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                      TextButton.icon(onPressed: () => _showAddMeasurementDialog(context), icon: const Icon(Icons.add, size: 16, color: Colors.amberAccent), label: const Text('Dodaj pomiar', style: TextStyle(color: Colors.amberAccent, fontSize: 12))),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  if (mProvider.isLoading && mProvider.measurements.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())) else _buildWeightChart(mProvider.measurements),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text('Gablota Osiągnięć', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 12),
          if (aProvider.isLoading && aProvider.allAchievements.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else if (aProvider.allAchievements.isEmpty)
            const Text('Brak zdefiniowanych osiągnięć w systemie.')
          else
            ...aProvider.allAchievements.map((ach) {
              final isUnlocked = aProvider.isUnlocked(ach.id);
              final earnedDate = aProvider.getEarnedDate(ach.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                color: isUnlocked ? const Color(0xFF252238) : const Color(0xFF161620),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isUnlocked ? Colors.amber.withValues(alpha: 0.5) : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnlocked ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                    child: Icon(
                      _getIcon(ach.iconUrl),
                      color: isUnlocked ? Colors.amber : Colors.white30,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ach.name,
                          style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.white54),
                        ),
                      ),
                      if (isUnlocked)
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16)
                      else
                        const Icon(Icons.lock_outline, color: Colors.white30, size: 16),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(ach.description, style: TextStyle(color: isUnlocked ? Colors.white70 : Colors.white30, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (isUnlocked && earnedDate != null)
                        Text(
                          'Zdobyto: ${earnedDate.day.toString().padLeft(2, '0')}.${earnedDate.month.toString().padLeft(2, '0')}.${earnedDate.year}',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      else
                        Text('Wymagane: ${ach.requiredPoints} pkt', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          Text('Historia wpisów wagowych', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          if (mProvider.measurements.isEmpty)
            const Text('Brak zarejestrowanych pomiarów.', style: TextStyle(color: Colors.white54))
          else
            ...mProvider.measurements.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 6.0),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.monitor_weight, color: Colors.deepPurpleAccent, size: 20),
                title: Text('${m.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Wzrost: ${m.height} cm ${m.bodyFatPercentage != null ? '| BF: ${m.bodyFatPercentage}%' : ''}'),
                trailing: m.measuredAt != null 
                    ? Text('${m.measuredAt!.day.toString().padLeft(2, '0')}.${m.measuredAt!.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12))
                    : null,
              ),
            )),
        ],
      ),
    );
  }
}