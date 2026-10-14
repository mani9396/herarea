import 'dart:math';

enum TambolaPattern {
  earlyFive,
  topLine,
  middleLine,
  bottomLine,
  fourCorners,
  fullHouse,
}

class TambolaPatternInfo {
  final TambolaPattern pattern;
  final String title;
  final String description;
  final int points;

  const TambolaPatternInfo({
    required this.pattern,
    required this.title,
    required this.description,
    required this.points,
  });
}

const List<TambolaPatternInfo> kTambolaPrizes = [
  TambolaPatternInfo(
    pattern: TambolaPattern.earlyFive,
    title: 'Early 5 (Jaldi 5)',
    description: 'First 5 numbers struck anywhere on ticket',
    points: 50,
  ),
  TambolaPatternInfo(
    pattern: TambolaPattern.topLine,
    title: 'Top Line',
    description: 'All 5 numbers struck in Row 1',
    points: 75,
  ),
  TambolaPatternInfo(
    pattern: TambolaPattern.middleLine,
    title: 'Middle Line',
    description: 'All 5 numbers struck in Row 2',
    points: 75,
  ),
  TambolaPatternInfo(
    pattern: TambolaPattern.bottomLine,
    title: 'Bottom Line',
    description: 'All 5 numbers struck in Row 3',
    points: 75,
  ),
  TambolaPatternInfo(
    pattern: TambolaPattern.fourCorners,
    title: 'Four Corners',
    description: 'First & last numbers of top & bottom lines',
    points: 60,
  ),
  TambolaPatternInfo(
    pattern: TambolaPattern.fullHouse,
    title: 'Full House (Tambola)',
    description: 'All 15 numbers struck on ticket',
    points: 200,
  ),
];

class TambolaEngine {
  final Random _random = Random();

  /// 3 rows x 9 columns ticket matrix (0 denotes blank cell)
  late List<List<int>> ticket;

  /// Ordered sequence of called numbers
  final List<int> calledNumbers = [];

  /// User marked numbers
  final Set<int> markedNumbers = {};

  /// Set of successfully claimed patterns
  final Set<TambolaPattern> claimedPatterns = {};

  TambolaEngine() {
    generateTicket();
  }

  /// Generates a strictly standard Tambola/Housie ticket
  /// 3 rows x 9 columns
  /// Col 0: 1-9, Col 1: 10-19, ..., Col 8: 80-90
  /// Each row has exactly 5 numbers and 4 blanks
  /// Total 15 numbers
  /// Sorted in ascending order within each column
  void generateTicket() {
    ticket = List.generate(3, (_) => List.filled(9, 0));

    // Ranges for each column
    List<List<int>> colRanges = [
      List.generate(9, (i) => i + 1),       // 1 - 9
      List.generate(10, (i) => i + 10),     // 10 - 19
      List.generate(10, (i) => i + 20),     // 20 - 29
      List.generate(10, (i) => i + 30),     // 30 - 39
      List.generate(10, (i) => i + 40),     // 40 - 49
      List.generate(10, (i) => i + 50),     // 50 - 59
      List.generate(10, (i) => i + 60),     // 60 - 69
      List.generate(10, (i) => i + 70),     // 70 - 79
      List.generate(11, (i) => i + 80),     // 80 - 90
    ];

    List<int> rowCounts = List.filled(3, 0);
    List<int> colCounts = List.filled(9, 0);

    // 1. Ensure at least one number in each column
    for (int c = 0; c < 9; c++) {
      int num = colRanges[c].removeAt(_random.nextInt(colRanges[c].length));
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        attempts++;
        int r = _random.nextInt(3);
        if (ticket[r][c] == 0 && rowCounts[r] < 5) {
          ticket[r][c] = num;
          rowCounts[r]++;
          colCounts[c]++;
          placed = true;
        }
      }
    }

    // 2. Place remaining 6 numbers to make 15 total (5 per row)
    int remaining = 6;
    int safetyLoops = 0;
    while (remaining > 0 && safetyLoops < 300) {
      safetyLoops++;
      int c = _random.nextInt(9);
      if (colCounts[c] < 3) {
        List<int> validRows = [];
        for (int r = 0; r < 3; r++) {
          if (ticket[r][c] == 0 && rowCounts[r] < 5) {
            validRows.add(r);
          }
        }
        if (validRows.isNotEmpty) {
          int r = validRows[_random.nextInt(validRows.length)];
          int num = colRanges[c].removeAt(_random.nextInt(colRanges[c].length));
          ticket[r][c] = num;
          rowCounts[r]++;
          colCounts[c]++;
          remaining--;
        }
      }
    }

    // Fallback if random placement stalled
    if (remaining > 0) {
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 9; c++) {
          if (remaining > 0 && ticket[r][c] == 0 && rowCounts[r] < 5 && colCounts[c] < 3 && colRanges[c].isNotEmpty) {
            ticket[r][c] = colRanges[c].removeAt(0);
            rowCounts[r]++;
            colCounts[c]++;
            remaining--;
          }
        }
      }
    }

    // 3. Sort ascendingly by column
    for (int c = 0; c < 9; c++) {
      List<int> colNums = [];
      for (int r = 0; r < 3; r++) {
        if (ticket[r][c] != 0) colNums.add(ticket[r][c]);
      }
      colNums.sort();
      int idx = 0;
      for (int r = 0; r < 3; r++) {
        if (ticket[r][c] != 0) {
          ticket[r][c] = colNums[idx++];
        }
      }
    }
  }

  /// Total numbers on ticket (always 15)
  List<int> get allTicketNumbers {
    final list = <int>[];
    for (var row in ticket) {
      for (var n in row) {
        if (n != 0) list.add(n);
      }
    }
    return list;
  }

  /// Numbers remaining to be marked
  int get remainingTicketNumbersCount {
    return allTicketNumbers.where((n) => !markedNumbers.contains(n)).length;
  }

  /// Calls next random available number from 1 to 90
  int? callNextNumber() {
    final available = List.generate(90, (i) => i + 1)
        .where((n) => !calledNumbers.contains(n))
        .toList();
    if (available.isEmpty) return null;
    final int next = available[_random.nextInt(available.length)];
    calledNumbers.add(next);
    return next;
  }

  /// Attempts to mark a number
  /// Returns:
  /// 1 = marked successfully
  /// 0 = already marked
  /// -1 = not called yet (cannot mark uncalled)
  /// -2 = not on ticket or blank
  int markNumber(int number) {
    if (number == 0) return -2;
    if (!allTicketNumbers.contains(number)) return -2;
    if (markedNumbers.contains(number)) return 0;
    if (!calledNumbers.contains(number)) return -1;

    markedNumbers.add(number);
    return 1;
  }

  /// Check whether a pattern is legitimately completed
  bool isPatternAchieved(TambolaPattern pattern) {
    switch (pattern) {
      case TambolaPattern.earlyFive:
        return markedNumbers.length >= 5;

      case TambolaPattern.topLine:
        final row0 = ticket[0].where((n) => n != 0).toList();
        return row0.every((n) => markedNumbers.contains(n));

      case TambolaPattern.middleLine:
        final row1 = ticket[1].where((n) => n != 0).toList();
        return row1.every((n) => markedNumbers.contains(n));

      case TambolaPattern.bottomLine:
        final row2 = ticket[2].where((n) => n != 0).toList();
        return row2.every((n) => markedNumbers.contains(n));

      case TambolaPattern.fourCorners:
        final topRow = ticket[0].where((n) => n != 0).toList();
        final bottomRow = ticket[2].where((n) => n != 0).toList();
        if (topRow.isEmpty || bottomRow.isEmpty) return false;
        final c1 = topRow.first;
        final c2 = topRow.last;
        final c3 = bottomRow.first;
        final c4 = bottomRow.last;
        return markedNumbers.contains(c1) &&
            markedNumbers.contains(c2) &&
            markedNumbers.contains(c3) &&
            markedNumbers.contains(c4);

      case TambolaPattern.fullHouse:
        return allTicketNumbers.every((n) => markedNumbers.contains(n));
    }
  }

  /// Claims a pattern. Returns true if valid, false if invalid (bogey).
  bool claimPattern(TambolaPattern pattern) {
    if (claimedPatterns.contains(pattern)) return false;
    if (isPatternAchieved(pattern)) {
      claimedPatterns.add(pattern);
      return true;
    }
    return false;
  }
}
