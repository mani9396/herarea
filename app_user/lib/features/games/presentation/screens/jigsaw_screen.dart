import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class JigsawScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const JigsawScreen({super.key, required this.sessionId});

  @override
  ConsumerState<JigsawScreen> createState() => _JigsawScreenState();
}

class _JigsawScreenState extends ConsumerState<JigsawScreen> {
  static const int size = 3;
  late List<int> _tiles;
  bool _isSubmitting = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _tiles = List.generate(size * size, (i) => i);
    _tiles.shuffle();
    
    // Ensure it's solvable
    int inversions = 0;
    for (int i = 0; i < _tiles.length - 1; i++) {
      for (int j = i + 1; j < _tiles.length; j++) {
        if (_tiles[i] != 0 && _tiles[j] != 0 && _tiles[i] > _tiles[j]) {
          inversions++;
        }
      }
    }
    
    if (inversions % 2 != 0) {
      // Swap first two non-zero tiles to make it solvable
      int idx1 = _tiles[0] == 0 ? 2 : 0;
      int idx2 = _tiles[1] == 0 ? 2 : 1;
      int temp = _tiles[idx1];
      _tiles[idx1] = _tiles[idx2];
      _tiles[idx2] = temp;
    }
    
    _moves = 0;
    setState(() {});
  }

  void _onTileTap(int index) {
    int emptyIndex = _tiles.indexOf(0);
    
    int r1 = index ~/ size;
    int c1 = index % size;
    int r2 = emptyIndex ~/ size;
    int c2 = emptyIndex % size;
    
    // Check if adjacent
    if ((r1 == r2 && (c1 - c2).abs() == 1) || (c1 == c2 && (r1 - r2).abs() == 1)) {
      setState(() {
        _tiles[emptyIndex] = _tiles[index];
        _tiles[index] = 0;
        _moves++;
      });
      _checkWin();
    }
  }

  Future<void> _checkWin() async {
    bool isWon = true;
    for (int i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) {
        isWon = false;
        break;
      }
    }
    if (_tiles.last != 0) isWon = false;

    if (isWon) {
      setState(() => _isSubmitting = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
          'score': max(0, 1000 - (_moves * 10)),
          'is_winner': true,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Puzzle Solved in $_moves moves!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save score')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWon = true;
    for (int i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) isWon = false;
    }
    if (_tiles.last != 0) isWon = false;

    return Column(
      children: [
        if (_isSubmitting) const LinearProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Moves: $_moves', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double boxSize = max(0.0, min(constraints.maxWidth - 32, constraints.maxHeight - 32)).clamp(0.0, 480.0);
              if (boxSize <= 0) return const SizedBox.shrink();

              return Center(
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size,
                      ),
                      itemCount: size * size,
                      itemBuilder: (context, index) {
                        int val = _tiles[index];
                        if (val == 0) return const SizedBox.shrink();
                        
                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                val.toString(),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (isWon)
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _startNewGame,
              child: const Text('Play Again'),
            ),
          )
      ],
    );
  }
}
