import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/games/presentation/screens/tambola/tambola_engine.dart';

void main() {
  group('TambolaEngine', () {
    test('Generates a standard valid 3x9 ticket with exactly 15 numbers', () {
      final engine = TambolaEngine();

      expect(engine.ticket.length, 3);
      int totalNumbers = 0;

      for (int r = 0; r < 3; r++) {
        expect(engine.ticket[r].length, 9);
        final nonZero = engine.ticket[r].where((n) => n != 0).toList();
        expect(nonZero.length, 5, reason: 'Row $r should have exactly 5 numbers');
        totalNumbers += nonZero.length;
      }

      expect(totalNumbers, 15);
      expect(engine.allTicketNumbers.length, 15);
    });

    test('Ticket respects column ranges (1-9, 10-19, ..., 80-90) and sorted order', () {
      final engine = TambolaEngine();

      for (int c = 0; c < 9; c++) {
        int minAllowed = c == 0 ? 1 : c * 10;
        int maxAllowed = c == 8 ? 90 : (c * 10) + 9;

        int prev = 0;
        for (int r = 0; r < 3; r++) {
          int val = engine.ticket[r][c];
          if (val != 0) {
            expect(val >= minAllowed && val <= maxAllowed, true,
                reason: 'Number $val in col $c should be between $minAllowed and $maxAllowed');
            expect(val > prev, true, reason: 'Column $c numbers must be strictly ascending');
            prev = val;
          }
        }
      }
    });

    test('Number calling calls numbers between 1 and 90 without duplicates', () {
      final engine = TambolaEngine();

      for (int i = 0; i < 90; i++) {
        final ball = engine.callNextNumber();
        expect(ball, isNotNull);
        expect(ball! >= 1 && ball <= 90, true);
      }

      expect(engine.calledNumbers.length, 90);
      expect(engine.calledNumbers.toSet().length, 90);

      // 91st call should return null
      final extraBall = engine.callNextNumber();
      expect(extraBall, isNull);
    });

    test('Marking numbers validates against called numbers', () {
      final engine = TambolaEngine();
      final numOnTicket = engine.allTicketNumbers.first;

      // 1. Trying to mark before called should return -1
      expect(engine.markNumber(numOnTicket), -1);
      expect(engine.markedNumbers.contains(numOnTicket), false);

      // 2. Call numbers until numOnTicket is called
      while (!engine.calledNumbers.contains(numOnTicket)) {
        engine.callNextNumber();
      }

      // 3. Now marking should succeed (1)
      expect(engine.markNumber(numOnTicket), 1);
      expect(engine.markedNumbers.contains(numOnTicket), true);

      // 4. Marking again returns 0 (already marked)
      expect(engine.markNumber(numOnTicket), 0);
    });

    test('Pattern detection accurately checks Early 5, Lines, and Full House', () {
      final engine = TambolaEngine();

      // Initially no pattern is achieved
      expect(engine.isPatternAchieved(TambolaPattern.earlyFive), false);
      expect(engine.isPatternAchieved(TambolaPattern.topLine), false);
      expect(engine.isPatternAchieved(TambolaPattern.fullHouse), false);

      // Call and mark all numbers on Row 0
      final row0Nums = engine.ticket[0].where((n) => n != 0).toList();
      expect(row0Nums.length, 5);

      for (var n in row0Nums) {
        engine.calledNumbers.add(n);
        engine.markNumber(n);
      }

      // Now Early 5 and Top Line are achieved!
      expect(engine.isPatternAchieved(TambolaPattern.earlyFive), true);
      expect(engine.isPatternAchieved(TambolaPattern.topLine), true);

      // Claiming Early 5 succeeds
      expect(engine.claimPattern(TambolaPattern.earlyFive), true);
      expect(engine.claimedPatterns.contains(TambolaPattern.earlyFive), true);

      // Trying to claim Early 5 again returns false
      expect(engine.claimPattern(TambolaPattern.earlyFive), false);

      // Full House is not yet achieved
      expect(engine.isPatternAchieved(TambolaPattern.fullHouse), false);
      // Bogey attempt on Full House returns false
      expect(engine.claimPattern(TambolaPattern.fullHouse), false);

      // Mark all remaining numbers
      for (var n in engine.allTicketNumbers) {
        engine.calledNumbers.add(n);
        engine.markNumber(n);
      }

      // Full House achieved!
      expect(engine.isPatternAchieved(TambolaPattern.fullHouse), true);
      expect(engine.claimPattern(TambolaPattern.fullHouse), true);
    });
  });
}
