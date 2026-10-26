import 'dart:convert';
import 'dart:io';
import 'package:bloom/helper/goal_suggestion.dart';
import 'package:bloom/integration/bloom_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 10, 26);
HabitView habit({DateTime? created, int target = 20}) => HabitView(
  id: 1,
  title: 'Read',
  category: 'Learning',
  unit: 'pages',
  dailyTarget: target,
  weeklyTarget: 3,
  createdAt: created ?? DateTime(2026, 9, 1),
);
List<CheckInView> entries(int tracked, Set<int> completed, {DateTime? end}) {
  final last = end ?? today;
  return List.generate(
    tracked,
    (i) => CheckInView(
      id: i + 1,
      habitId: 1,
      day: DateTime(last.year, last.month, last.day - i),
      progress: completed.contains(i) ? 20 : 0,
      status: completed.contains(i)
          ? CheckInStatus.completed
          : CheckInStatus.started,
    ),
  );
}

GoalSuggestion result(int tracked, int completed) => calculateGoal(
  habit: habit(),
  checkIns: entries(tracked, Set.from(List.generate(completed, (i) => i))),
  today: today,
);

void main() {
  test('empty/new and six tracked days abstain, seven unfinished qualify', () {
    expect(result(0, 0).daysPerWeek, isNull);
    expect(result(6, 6).daysPerWeek, isNull);
    expect(result(7, 0).daysPerWeek, 1);
    expect(result(7, 0).explanation, contains('unreliable'));
    expect(result(7, 0).trackedDays, 7);
    expect(
      calculateGoal(
        habit: habit(created: today),
        checkIns: [],
        today: today,
      ).daysPerWeek,
      isNull,
    );
    // Age alone is not tracked history.
    expect(result(0, 0).explanation, contains('Not enough history'));
  });
  test('eight completions gives four; all ties round upward and clamp', () {
    expect(result(14, 8).daysPerWeek, 4);
    for (var completed = 0; completed <= 14; completed++) {
      expect(
        result(14, completed).daysPerWeek,
        [1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7][completed],
      );
      expect(result(14, completed).completedDays, completed);
    }
  });
  test('inclusive today-minus-13 through today excludes older records', () {
    final value = calculateGoal(
      habit: habit(),
      checkIns: entries(15, {0, 13, 14}),
      today: today,
    );
    expect(value.completedDays, 2);
    expect(value.trackedDays, 14);
    expect(value.windowStart, DateTime(2026, 10, 13));
    expect(value.windowEnd, today);
  });
  test('calendar windows cross leap day, year and DST boundaries', () {
    for (final pair in [
      (DateTime(2024, 3, 10), DateTime(2024, 2, 26)),
      (DateTime(2026, 1, 5), DateTime(2025, 12, 23)),
      (DateTime(2026, 11, 5), DateTime(2026, 10, 23)),
    ]) {
      final value = calculateGoal(
        habit: habit(created: DateTime(2020)),
        checkIns: entries(14, {0, 13}, end: pair.$1),
        today: pair.$1,
      );
      expect(value.windowStart, pair.$2);
      expect(value.trackedDays, 14);
    }
  });
  test('corrupt/wrong-habit/duplicate/future/pre-creation inputs rejected', () {
    final base = entries(7, {});
    for (final bad in [
      CheckInView(
        id: 9,
        habitId: 2,
        day: today,
        progress: 0,
        status: CheckInStatus.started,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: today,
        progress: -1,
        status: CheckInStatus.started,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: today,
        progress: 21,
        status: CheckInStatus.inProgress,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: today,
        progress: 1,
        status: CheckInStatus.completed,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: today,
        progress: 0,
        status: CheckInStatus.inProgress,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: DateTime(2026, 10, 27),
        progress: 0,
        status: CheckInStatus.started,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: DateTime(2026, 8, 1),
        progress: 0,
        status: CheckInStatus.started,
      ),
      CheckInView(
        id: 9,
        habitId: 1,
        day: DateTime.utc(2026, 10, 26),
        progress: 0,
        status: CheckInStatus.started,
      ),
      CheckInView(
        id: 0,
        habitId: 1,
        day: today,
        progress: 0,
        status: CheckInStatus.started,
      ),
    ]) {
      expect(
        () => calculateGoal(habit: habit(), checkIns: [bad], today: today),
        throwsArgumentError,
      );
    }
    expect(
      () => calculateGoal(
        habit: habit(),
        checkIns: [...base, base.first],
        today: today,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateGoal(habit: habit(target: 0), checkIns: [], today: today),
      throwsArgumentError,
    );
    expect(
      () => calculateGoal(
        habit: habit(created: DateTime(2027)),
        checkIns: [],
        today: today,
      ),
      throwsArgumentError,
    );
  });
  test(
    'counterexample: perfect recent history does not predict an exam week',
    () {
      final prediction = result(14, 14).daysPerWeek!;
      const syntheticFollowingWeek = 1;
      expect((prediction - syntheticFollowingWeek).abs(), 6);
      expect((3 - syntheticFollowingWeek).abs(), 2);
    },
  );
  test('held-out synthetic paired MAE, no fitting', () {
    final fixture =
        jsonDecode(File('test/fixtures/held_out_goals.json').readAsStringSync())
            as Map<String, dynamic>;
    var helperError = 0;
    var baselineError = 0;
    var count = 0;
    var abstained = 0;
    for (final value in fixture['cases'] as List<dynamic>) {
      final c = value as Map<String, dynamic>;
      final prediction = calculateGoal(
        habit: habit(),
        checkIns: entries(
          c['trackedDays'] as int,
          (c['completedOffsets'] as List<dynamic>).cast<int>().toSet(),
        ),
        today: today,
      ).daysPerWeek;
      if (prediction == null) {
        abstained++;
        continue;
      }
      final outcome = c['followingWeek'] as int;
      helperError += (prediction - outcome).abs();
      baselineError += (3 - outcome).abs();
      count++;
      // Actual evaluation output, retained in DATA_TEST_LOG evidence.
      // ignore: avoid_print
      print('${c['name']}: helper=$prediction baseline=3 outcome=$outcome');
    }
    expect(count, 8);
    expect(abstained, 1);
    expect(helperError, 15);
    expect(baselineError, 13);
    // ignore: avoid_print
    print(
      'SYNTHETIC paired n=$count; abstained=$abstained; helper MAE=${helperError / count}; baseline MAE=${baselineError / count} days/week',
    );
  });
}
