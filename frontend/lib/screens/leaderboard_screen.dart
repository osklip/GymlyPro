import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../providers/user_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchLeaderboard();
    });
  }

  Color _getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildPodiumColumn(
      LeaderboardEntry? user, int rank, double height) {
    final color = _getPodiumColor(rank);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (user != null) ...[
            CircleAvatar(
              radius: rank == 1 ? 32 : 26,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: rank == 1 ? 24 : 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A))),
            Text(
                '${user.statValue > user.statValue.toInt() ? user.statValue.toStringAsFixed(1) : user.statValue.toInt()} ${user.statLabel}',
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          Container(
            height: height,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(rank == 1 ? Icons.emoji_events : Icons.military_tech,
                    color: Colors.white, size: rank == 1 ? 36 : 28),
                const SizedBox(height: 2),
                Text('$rank',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final leaderboard = userProvider.leaderboard;
    final myRank = userProvider.myRank;
    final myEntry = userProvider.myLeaderboardEntry;

    final first = leaderboard.isNotEmpty ? leaderboard[0] : null;
    final second = leaderboard.length > 1 ? leaderboard[1] : null;
    final third = leaderboard.length > 2 ? leaderboard[2] : null;
    final listMembers = leaderboard.length > 3
        ? leaderboard.sublist(3)
        : <LeaderboardEntry>[];

    return Scaffold(
      appBar: AppBar(
          title: const Text('Ranking Użytkowników',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'points',
                          label: Text('Punkty Exp',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      ButtonSegment(
                          value: 'volume',
                          label: Text('Suma Ciężaru',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      ButtonSegment(
                          value: 'progression',
                          label: Text('Progresja Mies.',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                    selected: {userProvider.selectedCategory},
                    onSelectionChanged: (val) =>
                        userProvider.setCategory(val.first),
                    style: SegmentedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        selectedBackgroundColor: const Color(0xFF10B981),
                        selectedForegroundColor: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'all',
                          label: Text('Cały czas',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      ButtonSegment(
                          value: 'month',
                          label: Text('Ostatni miesiąc',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                      ButtonSegment(
                          value: 'week',
                          label: Text('Ostatni tydzień',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))),
                    ],
                    selected: {userProvider.selectedTimeframe},
                    onSelectionChanged: (val) =>
                        userProvider.setTimeframe(val.first),
                    style: SegmentedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        selectedBackgroundColor: const Color(0xFF0F172A),
                        selectedForegroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (userProvider.isLoadingLeaderboard)
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF10B981))))
          else ...[
            if (leaderboard.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  height: 210,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPodiumColumn(second, 2, 95),
                      _buildPodiumColumn(first, 1, 125),
                      _buildPodiumColumn(third, 3, 70),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: listMembers.isEmpty
                  ? const Center(
                      child: Text('Brak dalszych lokat.',
                          style: TextStyle(color: Color(0xFF94A3B8))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: listMembers.length,
                      itemBuilder: (context, index) {
                        final actualRank = index + 4;
                        final user = listMembers[index];
                        final isMe =
                            myEntry != null && user.id == myEntry.id;
                        final valFormatted = user.statValue >
                                user.statValue.toInt()
                            ? user.statValue.toStringAsFixed(1)
                            : user.statValue.toInt();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            color: isMe
                                ? const Color(0xFFECFDF5)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: isMe
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE2E8F0),
                                    width: isMe ? 2.0 : 1.0)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: SizedBox(
                                  width: 36,
                                  child: Text('$actualRank.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Color(0xFF64748B)))),
                              title: Row(
                                children: [
                                  Expanded(
                                      child: Text(user.displayName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: isMe
                                                  ? const Color(0xFF065F46)
                                                  : const Color(
                                                      0xFF0F172A)))),
                                  if (isMe)
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: const Text('TY',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w900))),
                                ],
                              ),
                              subtitle: Text('Poziom ${user.level}',
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              trailing: Text('$valFormatted ${user.statLabel}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Color(0xFF10B981))),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TWOJA POZYCJA W TYM FILTRZE',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                        Text(
                            myRank != null
                                ? 'Miejsce $myRank.'
                                : 'Poza zestawieniem',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15))
                      ]),
                ],
              ),
              Text(
                  myEntry != null
                      ? '${myEntry.statValue > myEntry.statValue.toInt() ? myEntry.statValue.toStringAsFixed(1) : myEntry.statValue.toInt()} ${myEntry.statLabel}'
                      : '0 pkt',
                  style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
            ],
          ),
        ),
      ),
    );
  }
}