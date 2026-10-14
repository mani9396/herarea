import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class MemoryMatchScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const MemoryMatchScreen({super.key, required this.sessionId});

  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  final List<String> _emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];
  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  
  int _score = 0;
  bool _isSubmitting = false;
  int? _firstFlippedIndex;
  bool _canFlip = true;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _score = 0;
    _firstFlippedIndex = null;
    _canFlip = true;
    setState(() {});
  }

  void _onCardTap(int index) {
    if (!_canFlip || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _canFlip = false;
      if (_cards[_firstFlippedIndex!] == _cards[index]) {
        // Match found
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _matched[_firstFlippedIndex!] = true;
            _matched[index] = true;
            _score += 20;
            _firstFlippedIndex = null;
            _canFlip = true;
            _checkWin();
          });
        });
      } else {
        // No match
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _flipped[_firstFlippedIndex!] = false;
            _flipped[index] = false;
            _firstFlippedIndex = null;
            _canFlip = true;
          });
        });
      }
    }
  }

  Future<void> _checkWin() async {
    if (!_matched.contains(false)) {
      setState(() => _isSubmitting = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/api/v1/games/sessions/${widget.sessionId}/complete/', body: {
          'score': _score,
          'is_winner': true,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You Won!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save score')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWon = !_matched.contains(false);
    return Column(
      children: [
        if (_isSubmitting) const LinearProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Score: $_score', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              bool isFlipped = _flipped[index] || _matched[index];
              return GestureDetector(
                onTap: () => _onCardTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isFlipped ? Colors.white : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      isFlipped ? _cards[index] : '❓',
                      style: const TextStyle(fontSize: 32),
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
