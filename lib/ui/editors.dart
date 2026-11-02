import 'package:flutter/material.dart';
import '../integration/bloom_gateway.dart';
import 'widgets.dart';

class HabitEditor extends StatefulWidget {
  const HabitEditor({
    super.key,
    required this.gateway,
    this.existing,
    this.defaultTarget = 20,
    this.suggestedWeeklyTarget,
  });
  final BloomGateway gateway;
  final HabitView? existing;
  final int defaultTarget;
  final int? suggestedWeeklyTarget;
  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _category, _unit, _daily;
  late int _weekly;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final habit = widget.existing;
    _name = TextEditingController(text: habit?.title ?? '');
    _category = TextEditingController(
      text: habit?.category ?? 'Personal growth',
    );
    _unit = TextEditingController(text: habit?.unit ?? 'minutes');
    _daily = TextEditingController(
      text: '${habit?.dailyTarget ?? widget.defaultTarget}',
    );
    _weekly = widget.suggestedWeeklyTarget ?? habit?.weeklyTarget ?? 3;
  }

  @override
  void dispose() {
    for (final controller in [_name, _category, _unit, _daily]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final draft = HabitDraft(
        title: _name.text.trim(),
        category: _category.text.trim(),
        unit: _unit.text.trim(),
        dailyTarget: int.parse(_daily.text),
        weeklyTarget: _weekly,
      );
      final habit = widget.existing;
      if (habit == null) {
        await widget.gateway.createHabit(draft);
      } else {
        await widget.gateway.updateHabit(habit.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? text) => text == null || text.trim().isEmpty
      ? 'Enter a value before saving.'
      : null;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New habit' : 'Edit habit'),
      ),
      body: Form(
        key: _form,
        child: ContentColumn(
          children: [
            const Text('Give one small goal a name.', style: subheading),
            if (widget.suggestedWeeklyTarget != null)
              const SurfaceCard(
                child: Text(
                  'A suggested weekly goal is prefilled below. Nothing changes until you Save.',
                ),
              ),
            TextFormField(
              controller: _name,
              maxLength: 80,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Habit name'),
              validator: _required,
            ),
            TextFormField(
              controller: _category,
              maxLength: 60,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: _required,
            ),
            TextFormField(
              controller: _unit,
              maxLength: 30,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Measurement unit',
                hintText: 'minutes, pages, glasses',
              ),
              validator: _required,
            ),
            TextFormField(
              controller: _daily,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily target',
                helperText: 'Whole number from 1 to 100000',
              ),
              validator: (value) {
                final target = int.tryParse(value?.trim() ?? '');
                return target == null || target < 1 || target > 100000
                    ? 'Enter a whole number from 1 to 100000.'
                    : null;
              },
            ),
            Text('Weekly goal: $_weekly days', style: subheading),
            Slider(
              value: _weekly.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_weekly days per week',
              semanticFormatterCallback: (value) =>
                  '${value.round()} days per week',
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _weekly = value.round()),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save habit'),
            ),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CheckInEditor extends StatefulWidget {
  const CheckInEditor({
    super.key,
    required this.gateway,
    required this.snapshot,
    this.existing,
  });
  final BloomGateway gateway;
  final BloomSnapshot snapshot;
  final CheckInView? existing;
  @override
  State<CheckInEditor> createState() => _CheckInEditorState();
}

class _CheckInEditorState extends State<CheckInEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _progress, _note;
  late int _habitId;
  late DateTime _day;
  late CheckInStatus _status;
  bool _saving = false;
  HabitView get _habit =>
      widget.snapshot.habits.firstWhere((h) => h.id == _habitId);
  @override
  void initState() {
    super.initState();
    final record = widget.existing;
    _habitId = record?.habitId ?? widget.snapshot.habits.first.id;
    _day = localDay(record?.day ?? DateTime.now());
    _status = record?.status ?? CheckInStatus.started;
    _progress = TextEditingController(text: '${record?.progress ?? 0}');
    _note = TextEditingController(text: record?.note ?? '');
  }

  @override
  void dispose() {
    _progress.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _date() async {
    final now = localDay(DateTime.now());
    final first = localDay(_habit.createdAt);
    final last = now.isBefore(first) ? first : now;
    final selected = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(first)
          ? first
          : _day.isAfter(last)
          ? last
          : _day,
      firstDate: first,
      lastDate: last,
    );
    if (mounted && selected != null) setState(() => _day = localDay(selected));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    if (_day.isBefore(localDay(_habit.createdAt)) ||
        _day.isAfter(localDay(DateTime.now()))) {
      showError(
        context,
        'Choose a date from this habit’s creation date through today.',
      );
      return;
    }
    final progress = int.parse(_progress.text.trim());
    if (_status == CheckInStatus.completed && progress != _habit.dailyTarget) {
      showError(context, 'A completed check-in must reach the daily target.');
      return;
    }
    if (_status == CheckInStatus.started && progress != 0) {
      showError(context, 'Use In progress for a nonzero unfinished check-in.');
      return;
    }
    if (widget.snapshot.checkIns.any(
      (c) =>
          c.id != widget.existing?.id &&
          c.habitId == _habitId &&
          sameDay(c.day, _day),
    )) {
      showError(
        context,
        'This habit already has a check-in on that date. Correct the existing entry.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final draft = CheckInDraft(
        habitId: _habitId,
        day: _day,
        progress: progress,
        status: _status,
        note: _note.text.trim(),
      );
      final existing = widget.existing;
      if (existing == null) {
        await widget.gateway.createCheckIn(draft);
      } else {
        await widget.gateway.updateCheckIn(existing.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmAction(
      context,
      'Delete check-in?',
      'Only this check-in will be deleted. Your habit and its other history remain.',
      'Delete',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await widget.gateway.deleteCheckIn(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add check-in' : 'Correct check-in',
        ),
      ),
      body: Form(
        key: _form,
        child: ContentColumn(
          children: [
            const Text(
              'Keep your history honest. Changes save only when you confirm.',
            ),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _habitId,
              decoration: const InputDecoration(labelText: 'Habit'),
              items: widget.snapshot.habits
                  .map(
                    (h) => DropdownMenuItem(value: h.id, child: Text(h.title)),
                  )
                  .toList(),
              onChanged: _saving || widget.existing != null
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _habitId = value;
                        _progress.text = '0';
                        _status = CheckInStatus.started;
                      });
                    },
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _date,
              icon: const Icon(Icons.calendar_today),
              label: Text('Date: ${dateLabel(_day)}'),
            ),
            TextFormField(
              controller: _progress,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Progress (${_habit.unit})',
                helperText: '0–${_habit.dailyTarget}',
              ),
              validator: (value) {
                final number = int.tryParse(value?.trim() ?? '');
                return number == null ||
                        number < 0 ||
                        number > _habit.dailyTarget
                    ? 'Enter a whole number from 0 to ${_habit.dailyTarget}.'
                    : null;
              },
            ),
            DropdownButtonFormField<CheckInStatus>(
              isExpanded: true,
              key: ValueKey('status-$_habitId-$_status'),
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: CheckInStatus.values
                  .map(
                    (s) =>
                        DropdownMenuItem(value: s, child: Text(statusLabel(s))),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value!),
            ),
            TextFormField(
              controller: _note,
              enabled: !_saving,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save check-in'),
            ),
            if (widget.existing != null)
              OutlinedButton(
                onPressed: _saving ? null : _delete,
                child: const Text('Delete check-in'),
              ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}
