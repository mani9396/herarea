import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class TwentyFortyEightScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const TwentyFortyEightScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TwentyFortyEightScreen> createState() => _TwentyFortyEightScreenState();
}

class _TwentyFortyEightScreenState extends ConsumerState<TwentyFortyEightScreen> {
  late List<List<int>> _grid;
  int _score = 0;
  bool _gameOver = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _gameOver = false;
    _spawnTile();
    _spawnTile();
    setState(() {});
  }

  void _spawnTile() {
    List<Point<int>> emptyCells = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) emptyCells.add(Point(r, c));
      }
    }
    if (emptyCells.isNotEmpty) {
      final p = emptyCells[Random().nextInt(emptyCells.length)];
      _grid[p.x][p.y] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _moveLeft() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = _grid[r].where((x) => x != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          _score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((x) => x != 0).toList();
      while (row.length < 4) {
        row.add(0);
      }
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] != row[c]) moved = true;
        _grid[r][c] = row[c];
      }
    }
    if (moved) _postMove();
  }

  void _moveRight() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = _grid[r].reversed.where((x) => x != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          _score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((x) => x != 0).toList();
      while (row.length < 4) {
        row.add(0);
      }
      row = row.reversed.toList();
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] != row[c]) moved = true;
        _grid[r][c] = row[c];
      }
    }
    if (moved) _postMove();
  }

  void _moveUp() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [];
      for (int r = 0; r < 4; r++) {
        if (_grid[r][c] != 0) col.add(_grid[r][c]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          _score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((x) => x != 0).toList();
      while (col.length < 4) {
        col.add(0);
      }
      for (int r = 0; r < 4; r++) {
        if (_grid[r][c] != col[r]) moved = true;
        _grid[r][c] = col[r];
      }
    }
    if (moved) _postMove();
  }

  void _moveDown() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [];
      for (int r = 3; r >= 0; r--) {
        if (_grid[r][c] != 0) col.add(_grid[r][c]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          _score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((x) => x != 0).toList();
      while (col.length < 4) {
        col.add(0);
      }
      col = col.reversed.toList();
      for (int r = 0; r < 4; r++) {
        if (_grid[r][c] != col[r]) moved = true;
        _grid[r][c] = col[r];
      }
    }
    if (moved) _postMove();
  }

  void _postMove() {
    _spawnTile();
    if (_checkGameOver()) {
      _endGame();
    } else {
      setState(() {});
    }
  }

  bool _checkGameOver() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) return false;
        if (c < 3 && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r < 3 && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  Future<void> _endGame() async {
    setState(() {
      _gameOver = true;
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
        'score': _score,
        'is_winner': _score > 2000,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game Over!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save score')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSubmitting) const LinearProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Score: $_score', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (_gameOver) return;
              if (details.velocity.pixelsPerSecond.dy > 0) {
                _moveDown();
              } else {
                _moveUp();
              }
            },
            onHorizontalDragEnd: (details) {
              if (_gameOver) return;
              if (details.velocity.pixelsPerSecond.dx > 0) {
                _moveRight();
              } else {
                _moveLeft();
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double boxSize = max(0.0, min(constraints.maxWidth - 32, constraints.maxHeight - 32)).clamp(0.0, 480.0);
                if (boxSize <= 0) return const SizedBox.shrink();

                return Center(
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.brown.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: 16,
                        itemBuilder: (context, index) {
                          final val = _grid[index ~/ 4][index % 4];
                          return Container(
                            decoration: BoxDecoration(
                              color: val == 0 ? Colors.brown.shade100 : Colors.orange.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                val == 0 ? '' : val.toString(),
                                style: TextStyle(
                                  fontSize: val > 100 ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade800,
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
        ),
        if (_gameOver)
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
