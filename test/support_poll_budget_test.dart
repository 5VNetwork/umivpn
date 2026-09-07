import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umivpn/app/support/support_poll_budget.dart';

void main() {
  const userId = 'user-1';

  late SharedPreferences prefs;
  late DateTime now;
  late SupportPollBudget budget;

  SupportPollBudget makeBudget({
    int maxPollCount = SupportPollBudget.defaultMaxPollCount,
    List<Duration>? delays,
  }) {
    return SupportPollBudget(
      preferences: prefs,
      userId: userId,
      clock: () => now,
      maxPollCount: maxPollCount,
      delays: delays,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 9, 7, 12);
    budget = makeBudget();
    budget.load();
  });

  group('needPoll', () {
    test('defaults to false and persists', () async {
      expect(budget.needPoll, isFalse);

      await budget.setNeedPoll(true);
      expect(budget.needPoll, isTrue);

      final reloaded = makeBudget()..load();
      expect(reloaded.needPoll, isTrue);
    });
  });

  group('nextWait', () {
    test('uses the first delay with no prior poll', () {
      expect(budget.nextWait(), SupportPollBudget.defaultDelays.first);
    });

    test('returns remaining time when last poll was recent', () async {
      await budget.recordPoll(); // step -> 1 (5s), lastAt = now
      expect(budget.step, 1);

      now = now.add(const Duration(seconds: 2));
      expect(budget.nextWait(), const Duration(seconds: 3));
    });

    test('returns zero when the current delay is overdue', () async {
      await budget.recordPoll(); // step 1, delay 5s
      now = now.add(const Duration(seconds: 10));
      expect(budget.nextWait(), Duration.zero);
    });

    test('survives process restart without resetting the schedule', () async {
      await budget.setNeedPoll(true);
      await budget.recordPoll(); // step 1
      await budget.recordPoll(); // step 2, delay 10s, lastAt = now

      now = now.add(const Duration(seconds: 4));

      final reopened = makeBudget()..load();
      expect(reopened.step, 2);
      expect(reopened.count, 2);
      expect(reopened.nextWait(), const Duration(seconds: 6));
    });
  });

  group('recordPoll', () {
    test('advances through the backoff schedule', () async {
      for (var i = 0; i < SupportPollBudget.defaultDelays.length - 1; i++) {
        expect(budget.step, i);
        await budget.recordPoll();
        now = now.add(const Duration(seconds: 1));
      }
      expect(budget.step, SupportPollBudget.defaultDelays.length - 1);

      // Last delay repeats instead of walking off the end.
      await budget.recordPoll();
      expect(budget.step, SupportPollBudget.defaultDelays.length - 1);
      expect(
        budget.nextWait(),
        SupportPollBudget.defaultDelays.last,
      );
    });

    test('stops after maxPollCount even if conversation still exists', () async {
      final short = makeBudget(
        maxPollCount: 3,
        delays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(hours: 24),
        ],
      )..load();

      await short.recordPoll();
      expect(short.isExhausted, isFalse);
      await short.recordPoll();
      expect(short.isExhausted, isFalse);
      await short.recordPoll();
      expect(short.isExhausted, isTrue);
      expect(short.count, 3);
    });

    test('default budget is exhausted after 15 polls', () async {
      for (var i = 0; i < 15; i++) {
        expect(budget.isExhausted, isFalse);
        await budget.recordPoll();
        now = now.add(const Duration(minutes: 1));
      }
      expect(budget.count, 15);
      expect(budget.isExhausted, isTrue);
    });
  });

  group('reset', () {
    test('clears step, count, and last poll time', () async {
      await budget.recordPoll();
      await budget.recordPoll();
      now = now.add(const Duration(seconds: 3));

      await budget.reset();

      expect(budget.step, 0);
      expect(budget.count, 0);
      expect(budget.isExhausted, isFalse);
      expect(budget.nextWait(), SupportPollBudget.defaultDelays.first);

      final reloaded = makeBudget()..load();
      expect(reloaded.step, 0);
      expect(reloaded.count, 0);
      expect(reloaded.nextWait(), SupportPollBudget.defaultDelays.first);
    });

    test('agent reply style reset restores the fast schedule', () async {
      // Walk deep into the schedule as if nothing happened for a while.
      for (var i = 0; i < 8; i++) {
        await budget.recordPoll();
        now = now.add(const Duration(hours: 1));
      }
      expect(budget.step, greaterThan(5));

      // New agent message: start over.
      await budget.reset();
      expect(budget.step, 0);
      expect(budget.count, 0);
      expect(budget.nextWait(), SupportPollBudget.defaultDelays.first);
    });
  });

  group('load clamping', () {
    test('clamps an out-of-range persisted step', () async {
      await prefs.setInt('$supportPollStepPreferenceKeyPrefix$userId', 99);
      await prefs.setInt('$supportPollCountPreferenceKeyPrefix$userId', 4);

      final reloaded = makeBudget()..load();
      expect(reloaded.step, SupportPollBudget.defaultDelays.length - 1);
      expect(reloaded.count, 4);
    });
  });

  group('controller poll loop (simulated)', () {
    /// Mirrors SupportUnreadBadgeController._onPollTimer / _startPoll without
    /// pulling in main.dart / Supabase.
    Future<int> runPollLoop({
      required SupportPollBudget b,
      required bool Function(int pollIndex) conversationExists,
      required bool Function(int pollIndex) agentReplied,
      int safetyLimit = 50,
    }) async {
      await b.setNeedPoll(true);
      b.load();
      if (b.isExhausted) {
        await b.setNeedPoll(false);
        await b.reset();
        return 0;
      }

      var polls = 0;
      while (b.needPoll && !b.isExhausted && polls < safetyLimit) {
        final wait = b.nextWait();
        now = now.add(wait);
        polls += 1;

        final exists = conversationExists(polls);
        final replied = agentReplied(polls);

        if (!exists) {
          await b.setNeedPoll(false);
          await b.reset();
          break;
        }
        if (replied) {
          await b.reset();
        }

        await b.recordPoll();
        if (b.isExhausted) {
          await b.setNeedPoll(false);
          await b.reset();
          break;
        }
      }
      return polls;
    }

    test('stops when the conversation is deleted', () async {
      final polls = await runPollLoop(
        b: budget,
        conversationExists: (i) => i < 4,
        agentReplied: (_) => false,
      );

      expect(polls, 4);
      expect(budget.needPoll, isFalse);
      expect(budget.count, 0); // reset on stop
    });

    test('stops after 15 polls while conversation still exists', () async {
      final polls = await runPollLoop(
        b: budget,
        conversationExists: (_) => true,
        agentReplied: (_) => false,
      );

      expect(polls, 15);
      expect(budget.needPoll, isFalse);
    });

    test('agent reply resets count so polling can continue', () async {
      final short = makeBudget(
        maxPollCount: 3,
        delays: const [Duration(seconds: 1), Duration(seconds: 2)],
      )..load();

      final polls = await runPollLoop(
        b: short,
        conversationExists: (_) => true,
        // Reply on the 2nd poll of the first cycle → count resets, then 3 more.
        agentReplied: (i) => i == 2,
        safetyLimit: 20,
      );

      // poll1, poll2(+reset+record=1), poll3(count=2), poll4(count=3 stop)
      expect(polls, 4);
      expect(short.needPoll, isFalse);
    });

    test('reopen continues remaining wait instead of restarting', () async {
      await budget.setNeedPoll(true);
      await budget.recordPoll(); // step 1 = 5s
      now = now.add(const Duration(seconds: 2));

      final reopened = makeBudget()..load();
      expect(reopened.needPoll, isTrue);
      expect(reopened.nextWait(), const Duration(seconds: 3));

      // Finish the remaining wait and poll once more.
      now = now.add(reopened.nextWait());
      await reopened.recordPoll();
      expect(reopened.step, 2);
      expect(reopened.count, 2);
    });
  });
}
