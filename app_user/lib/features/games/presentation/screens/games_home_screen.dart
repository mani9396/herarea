import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class GamesHomeScreen extends StatelessWidget {
  const GamesHomeScreen({super.key});

  final List<Map<String, dynamic>> _games = const [
    {'id': 'ludo', 'name': 'Ludo', 'icon': Icons.casino_outlined, 'color': Colors.red},
    {'id': 'tambola', 'name': 'Tambola', 'icon': Icons.grid_on_outlined, 'color': Colors.orange},
    {'id': 'jigsaw', 'name': 'Jigsaw Puzzle', 'icon': Icons.extension_outlined, 'color': Colors.amber},
    {'id': 'sudoku', 'name': 'Sudoku', 'icon': Icons.apps_outlined, 'color': Colors.blue},
    {'id': 'memory_match', 'name': 'Memory Match', 'icon': Icons.view_module_outlined, 'color': Colors.indigo},
    {'id': '2048', 'name': '2048 Number Puzzle', 'icon': Icons.format_list_numbered_outlined, 'color': Colors.purple},
    {'id': 'tic_tac_toe', 'name': 'Tic-Tac-Toe', 'icon': Icons.close_outlined, 'color': Colors.pink},
    {'id': 'snake', 'name': 'Snake', 'icon': Icons.gesture_outlined, 'color': Colors.lightGreen},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/games/history'),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/games/scorecard'),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
          ),
          itemCount: _games.length,
          itemBuilder: (context, index) {
            final game = _games[index];
            return InkWell(
              onTap: () => context.push('/games/${game['id']}'),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: (game['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: (game['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      game['icon'] as IconData,
                      size: 48,
                      color: game['color'] as Color,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      game['name'] as String,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
