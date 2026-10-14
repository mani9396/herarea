import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'tic_tac_toe_screen.dart';
import 'tambola_screen.dart';
import 'ludo_screen.dart';
import 'jigsaw_screen.dart';
import 'sudoku_screen.dart';
import 'memory_match_screen.dart';
import 'twenty_forty_eight_screen.dart';
import 'snake_screen.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GamePlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  String? _sessionId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/api/v1/games/sessions/', body: {
        'game_type': widget.gameId,
        'is_multiplayer': false,
      });
      if (mounted) {
        setState(() {
          _sessionId = response['id'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start game session: $e';
        });
      }
    }
  }

  Widget _getGameContent() {
    if (_sessionId == null) return const SizedBox.shrink();
    
    switch (widget.gameId) {
      case 'tic_tac_toe':
        return TicTacToeScreen(sessionId: _sessionId!);
      case 'tambola':
        return TambolaScreen(sessionId: _sessionId!);
      case 'ludo':
        return LudoScreen(sessionId: _sessionId!);
      case 'jigsaw':
        return JigsawScreen(sessionId: _sessionId!);
      case 'sudoku':
        return SudokuScreen(sessionId: _sessionId!);
      case 'memory_match':
        return MemoryMatchScreen(sessionId: _sessionId!);
      case '2048':
        return TwentyFortyEightScreen(sessionId: _sessionId!);
      case 'snake':
        return SnakeScreen(sessionId: _sessionId!);
      default:
        return Center(child: Text('Game UI for ${widget.gameId} not implemented yet.'));
    }
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Exit Game?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to exit? A game is currently in progress. If you leave now, your current match progress will be lost.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Resume Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Exit Game'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(onPressed: _startSession, child: const Text('Retry'))
            ],
          ),
        ),
      );
    }

    if (_sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Starting ${widget.gameId}...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final bool shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Exit Game',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final bool shouldExit = await _showExitConfirmationDialog(context);
              if (shouldExit && mounted) {
                navigator.pop();
              }
            },
          ),
          title: Text(widget.gameId.replaceAll('_', ' ').toUpperCase()),
        ),
        body: _getGameContent(),
      ),
    );
  }
}
