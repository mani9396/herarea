import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:intl/intl.dart';

final gameHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/api/v1/games/history/');
  return (response['results'] as List<dynamic>?) ?? [];
});

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(gameHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
      ),
      body: historyState.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('No game history found.'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateStr = session['created_at'] ?? '';
              final date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
              final formattedDate = date != null ? DateFormat('MMM d, yyyy - h:mm a').format(date.toLocal()) : 'Unknown Date';
              
              return ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primaryRuby),
                title: Text(session['game_type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formattedDate),
                trailing: Text(session['status']),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load history: $err')),
      ),
    );
  }
}
