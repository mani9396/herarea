import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SudokuScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  // A simple hardcoded valid puzzle and solution for demonstration
  final List<List<int>> _initialGrid = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];
  
  late List<List<int>> _currentGrid;
  int? _selectedRow;
  int? _selectedCol;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _currentGrid = List.generate(9, (r) => List.generate(9, (c) => _initialGrid[r][c]));
    _selectedRow = null;
    _selectedCol = null;
    setState(() {});
  }

  void _onCellTap(int row, int col) {
    if (_initialGrid[row][col] == 0) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _onNumberInput(int number) {
    if (_selectedRow != null && _selectedCol != null) {
      setState(() {
        _currentGrid[_selectedRow!][_selectedCol!] = number;
      });
      _checkWin();
    }
  }

  Future<void> _checkWin() async {
    // Basic completion check (no zeros and no dupes in rows/cols)
    bool isComplete = true;
    for (int r = 0; r < 9; r++) {
      Set<int> rowSet = {};
      Set<int> colSet = {};
      for (int c = 0; c < 9; c++) {
        if (_currentGrid[r][c] == 0) isComplete = false;
        rowSet.add(_currentGrid[r][c]);
        colSet.add(_currentGrid[c][r]);
      }
      if (rowSet.length < 9 || colSet.length < 9) isComplete = false;
    }

    if (isComplete) {
      setState(() => _isSubmitting = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
          'score': 500,
          'is_winner': true,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sudoku Solved!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save score')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double boardSize = min(screenWidth - 32, 400.0);
    final double keyBtnWidth = ((min(screenWidth, 500.0) - 32 - (8 * 4)) / 9).clamp(30.0, 44.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          if (_isSubmitting) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemCount: 81,
                  itemBuilder: (context, index) {
                    int r = index ~/ 9;
                    int c = index % 9;
                    int val = _currentGrid[r][c];
                    bool isInitial = _initialGrid[r][c] != 0;
                    bool isSelected = _selectedRow == r && _selectedCol == c;

                    return GestureDetector(
                      onTap: () => _onCellTap(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.black, width: c % 3 == 2 ? 2 : 0.5),
                            bottom: BorderSide(color: Colors.black, width: r % 3 == 2 ? 2 : 0.5),
                            top: BorderSide(color: Colors.black, width: r == 0 ? 2 : 0),
                            left: BorderSide(color: Colors.black, width: c == 0 ? 2 : 0),
                          ),
                          color: isSelected ? Colors.blue.shade100 : (isInitial ? Colors.grey.shade200 : Colors.white),
                        ),
                        child: Center(
                          child: Text(
                            val == 0 ? '' : val.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isInitial ? FontWeight.bold : FontWeight.w600,
                              color: isInitial ? Colors.black : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Adaptive Number Keypad (1 - 9)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(9, (index) {
                int num = index + 1;
                return SizedBox(
                  width: keyBtnWidth,
                  height: keyBtnWidth * 1.15,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _onNumberInput(num),
                    child: Text(num.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _onNumberInput(0),
            icon: const Icon(Icons.backspace_outlined, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            label: const Text('Clear Selected Cell'),
          ),
        ],
      ),
    );
  }
}
