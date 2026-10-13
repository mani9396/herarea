import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

final scorecardProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/api/v1/games/statistics/');
  return (response['results'] as List<dynamic>?) ?? [];
});

class GameScorecardScreen extends ConsumerWidget {
  const GameScorecardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorecardState = ref.watch(scorecardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scorecard'),
      ),
      body: scorecardState.when(
        data: (stats) {
          if (stats.isEmpty) {
            return const Center(child: Text('No game statistics yet. Play some games!'));
          }
          return ListView.builder(
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text(stat['game_type'].toString().toUpperCase()),
                subtitle: Text('Played: ${stat['games_played']} | Wins: ${stat['total_wins']}'),
                trailing: Text('Best: ${stat['highest_score']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load scorecard: $err')),
      ),
    );
  }
}
