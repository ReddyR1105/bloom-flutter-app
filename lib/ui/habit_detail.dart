import 'dart:async';
import 'package:flutter/material.dart';
import '../integration/bloom_gateway.dart';
import 'editors.dart';
import 'widgets.dart';

class HabitDetail extends StatefulWidget {
  const HabitDetail({super.key, required this.gateway, required this.habitId});
  final BloomGateway gateway;
  final int habitId;
  @override
  State<HabitDetail> createState() => _HabitDetailState();
}

class _HabitDetailState extends State<HabitDetail> {
  BloomSnapshot? _data;
  GoalSuggestionView? _suggestion;
  String? _error, _helperError;
  bool _loading = true, _busy = false, _helperDismissed = false;
  int _draftProgress = 0;
  DateTime _day = localDay(DateTime.now());
  HabitView? get _habit {
    final matches = _data?.habits.where((h) => h.id == widget.habitId);
    return matches == null || matches.isEmpty ? null : matches.first;
  }

  CheckInView? get _entry {
    final matches = _data?.checkIns.where(
      (c) => c.habitId == widget.habitId && sameDay(c.day, _day),
    );
    return matches == null || matches.isEmpty ? null : matches.first;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await widget.gateway.load();
      if (!mounted) return;
      final day = localDay(DateTime.now());
      final entries = data.checkIns.where(
        (c) => c.habitId == widget.habitId && sameDay(c.day, day),
      );
      setState(() {
        _data = data;
        _day = day;
        _draftProgress = entries.isEmpty ? 0 : entries.first.progress;
        _loading = false;
      });
      try {
        final suggestion = await widget.gateway.suggestGoal(
          widget.habitId,
          day,
        );
        if (mounted) {
          setState(() {
            _suggestion = suggestion;
            _helperError = null;
          });
        }
      } catch (error) {
        if (mounted) setState(() => _helperError = readableError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = readableError(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    if (!sameDay(_day, DateTime.now())) {
      await _load();
      if (mounted) {
        showError(
          context,
          'The date changed. Review today’s check-in and try again.',
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit({int? weekly}) async {
    final habit = _habit;
    if (habit == null) return;
    await Navigator.push<void>(
      context,
      bloomRoute<void>(
        context,
        HabitEditor(
          gateway: widget.gateway,
          existing: habit,
          suggestedWeeklyTarget: weekly,
        ),
        _data?.settings.reducedMotion ?? false,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    if (!await confirmAction(
      context,
      'Delete habit and history?',
      'This permanently removes this habit and ALL its saved check-ins. This cannot be undone.',
      'Delete all',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.gateway.deleteHabit(widget.habitId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!await confirmAction(
      context,
      'Reset today’s progress?',
      'Today’s saved check-in will return to 0 and Started. Other dates remain unchanged.',
      'Reset today',
    )) {
      return;
    }
    if (mounted) await _act(() => widget.gateway.reset(widget.habitId, _day));
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;
    final entry = _entry;
    final suggestion = _suggestion;
    final changed = _draftProgress != (entry?.progress ?? 0);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Habit activity')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ContentColumn(
                children: [
                  Text(_error!),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Try again'),
                  ),
                ],
              )
            : habit == null
            ? const ContentColumn(
                children: [Text('This habit is no longer available.')],
              )
            : ContentColumn(
                children: [
                  Text(habit.title, style: heading),
                  Text(
                    '${habit.category} · ${habit.dailyTarget} ${habit.unit}/day · ${habit.weeklyTarget} days/week',
                  ),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today · ${dateLabel(_day)}', style: subheading),
                        Text(
                          entry == null
                              ? 'Not started'
                              : statusLabel(entry.status),
                        ),
                        Text(
                          '${entry?.progress ?? 0} / ${habit.dailyTarget} ${habit.unit} saved',
                          style: heading,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: ((entry?.progress ?? 0) / habit.dailyTarget)
                              .clamp(0, 1),
                        ),
                      ],
                    ),
                  ),
                  if (entry == null)
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => widget.gateway.start(habit.id, _day),
                            ),
                      child: const Text('Start today'),
                    ),
                  if (entry != null) ...[
                    Text(
                      'Progress: $_draftProgress ${habit.unit}${changed ? " (not saved)" : ""}',
                      style: subheading,
                    ),
                    Slider(
                      value: _draftProgress
                          .clamp(0, habit.dailyTarget)
                          .toDouble(),
                      min: 0,
                      max: habit.dailyTarget.toDouble(),
                      divisions: habit.dailyTarget <= 1000
                          ? habit.dailyTarget
                          : null,
                      label: '$_draftProgress ${habit.unit}',
                      semanticFormatterCallback: (value) =>
                          '${value.round()} ${habit.unit}',
                      onChanged: _busy
                          ? null
                          : (value) =>
                                setState(() => _draftProgress = value.round()),
                    ),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Decrease progress',
                          onPressed: _busy || _draftProgress == 0
                              ? null
                              : () => setState(() => _draftProgress--),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          tooltip: 'Increase progress',
                          onPressed:
                              _busy || _draftProgress >= habit.dailyTarget
                              ? null
                              : () => setState(() => _draftProgress++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: _busy || !changed
                          ? null
                          : () => _act(
                              () => widget.gateway.updateProgress(
                                habit.id,
                                _day,
                                _draftProgress,
                              ),
                            ),
                      child: const Text('Save progress'),
                    ),
                    FilledButton(
                      onPressed: _busy || _draftProgress != habit.dailyTarget
                          ? null
                          : () => _act(() async {
                              if (changed) {
                                await widget.gateway.updateProgress(
                                  habit.id,
                                  _day,
                                  _draftProgress,
                                );
                              }
                              await widget.gateway.finish(habit.id, _day);
                            }),
                      child: const Text('Finish for today'),
                    ),
                    if (_draftProgress != habit.dailyTarget)
                      const Text('Reach your daily target before finishing.'),
                    OutlinedButton(
                      onPressed: _busy ? null : _reset,
                      child: const Text('Reset today’s progress'),
                    ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await Navigator.push<void>(
                                context,
                                bloomRoute<void>(
                                  context,
                                  CheckInEditor(
                                    gateway: widget.gateway,
                                    snapshot: _data!,
                                    existing: entry,
                                  ),
                                  _data!.settings.reducedMotion,
                                ),
                              );
                              if (mounted) await _load();
                            },
                      child: const Text('Correct today’s check-in'),
                    ),
                  ],
                  if (_busy) const LinearProgressIndicator(),
                  if (!_helperDismissed)
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gentle Goal Suggestion',
                            style: subheading,
                          ),
                          Text(
                            _helperError ??
                                suggestion?.explanation ??
                                'Loading your local history…',
                          ),
                          Text(
                            'Fixed baseline: ${suggestion?.baselineDaysPerWeek ?? 3} days/week. Offline rules, not a trained model.',
                          ),
                          Wrap(
                            spacing: 12,
                            children: [
                              FilledButton(
                                onPressed:
                                    _busy || suggestion?.daysPerWeek == null
                                    ? null
                                    : () => _edit(
                                        weekly: suggestion!.daysPerWeek,
                                      ),
                                child: const Text('Apply'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _helperDismissed = true),
                                child: const Text('Not now'),
                              ),
                            ],
                          ),
                          const Text(
                            'Apply opens the form. Only Save changes your weekly goal.',
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton(
                    onPressed: _busy ? null : _edit,
                    child: const Text('Edit habit'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: const Text('Delete habit and history'),
                  ),
                ],
              ),
      ),
    );
  }
}
