import 'package:flutter/material.dart';
import '../integration/bloom_gateway.dart';

const forest = Color(0xFF285F4D);
const sage = Color(0xFFE6EFE5);
Route<T> bloomRoute<T>(BuildContext context, Widget page, bool reducedMotion) {
  final reduce = reducedMotion || MediaQuery.disableAnimationsOf(context);
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 180),
    reverseTransitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

const heading = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: Color(0xFF243C32),
);
const subheading = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Color(0xFF243C32),
);

DateTime localDay(DateTime date) => DateTime(date.year, date.month, date.day);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String statusLabel(CheckInStatus status) => switch (status) {
  CheckInStatus.started => 'Started',
  CheckInStatus.inProgress => 'In progress',
  CheckInStatus.completed => 'Completed',
};
String readableError(Object error) => error.toString().replaceFirst(
  RegExp(r'^(Bad state|Exception|StateError|ArgumentError):\s*'),
  '',
);
void showError(BuildContext context, Object error) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(readableError(error))));

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String explanation,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(bottom: 18), child: child),
          ],
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: sage,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD6E1D4)),
    ),
    child: child,
  );
}

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.checkIn,
    required this.onTap,
  });
  final HabitView habit;
  final CheckInView? checkIn;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      minVerticalPadding: 16,
      leading: Icon(
        checkIn?.status == CheckInStatus.completed
            ? Icons.check_circle
            : Icons.circle_outlined,
        color: forest,
      ),
      title: Text(habit.title, style: subheading),
      subtitle: Text(
        '${habit.category}\n${checkIn?.progress ?? 0} / ${habit.dailyTarget} '
        '${habit.unit} · ${habit.weeklyTarget} days/week',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class Garden extends StatelessWidget {
  const Garden({super.key, required this.completed});
  final int completed;
  @override
  Widget build(BuildContext context) {
    final stage = completed == 0
        ? 0
        : completed < 5
        ? 1
        : completed < 14
        ? 2
        : 3;
    final label = ['Seed', 'Sprout', 'Growing', 'Blooming'][stage];
    return Semantics(
      label: '$label garden. $completed saved completed check-ins.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 120,
              width: 180,
              child: CustomPaint(painter: _PlantPainter(stage)),
            ),
            Text('$label · $completed saved completions'),
          ],
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.stage);
  final int stage;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = forest
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, 108), width: 100, height: 12),
      Paint()..color = const Color(0xFFD0DDC8),
    );
    if (stage == 0) {
      canvas.drawCircle(Offset(x, 100), 7, paint);
      return;
    }
    final top = stage == 1 ? 62.0 : 30.0;
    canvas.drawLine(Offset(x, 103), Offset(x, top), paint);
    canvas.drawOval(Rect.fromLTWH(x - 34, 68, 34, 18), paint);
    canvas.drawOval(
      Rect.fromLTWH(x, 54, 32, 20),
      Paint()..color = const Color(0xFF78A887),
    );
    if (stage >= 2) canvas.drawOval(Rect.fromLTWH(x - 30, 35, 30, 18), paint);
    if (stage == 3) {
      final petal = Paint()..color = const Color(0xFFD99580);
      for (final offset in [
        const Offset(-12, 0),
        const Offset(12, 0),
        const Offset(0, -12),
        const Offset(0, 12),
      ]) {
        canvas.drawCircle(Offset(x, top) + offset, 10, petal);
      }
      canvas.drawCircle(
        Offset(x, top),
        8,
        Paint()..color = const Color(0xFFEACD85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      stage != oldDelegate.stage;
}
