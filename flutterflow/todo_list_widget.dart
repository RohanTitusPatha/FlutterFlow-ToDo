// FlutterFlow custom widget: TodoListWidget
// Keep FlutterFlow's automatic imports above these imports.
// Dependency: shared_preferences: ^2.3.0 (or an existing compatible 2.x version).
// Set both width and height in FlutterFlow. See START_HERE.md.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoListWidget extends StatefulWidget {
  const TodoListWidget({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  static const _storageKey = 'rohan_todo_list_v1';
  static const _green = Color(0xFF235B43);
  static const _ink = Color(0xFF202C25);
  static const _muted = Color(0xFF69766D);
  static const _background = Color(0xFFF7F8F2);

  final _storage = SharedPreferencesAsync();
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  List<_TodoTask> _tasks = [];
  String _filter = 'All';
  String? _editingId;
  String? _error;
  bool _loading = true;
  bool _loaded = false;
  bool _saving = false;
  int _idCounter = 0;

  bool get _busy => _loading || _saving || !_loaded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _storage.getString(_storageKey);
      final List<_TodoTask> loaded;
      if (raw == null) {
        loaded = [];
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException('Invalid task list');
        loaded = decoded.map((value) => _TodoTask.fromJson(value)).toList();
        if (loaded.map((task) => task.id).toSet().length != loaded.length) {
          throw const FormatException('Duplicate task IDs');
        }
      }
      if (!mounted) return;
      setState(() {
        _tasks = loaded;
        _loaded = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loaded = false;
        _error = 'Could not open your saved tasks. Please try again.';
      });
    }
  }

  // Await each write before accepting another change, so saves cannot race.
  // Only update the displayed list after storage accepts the write.
  Future<bool> _commit(List<_TodoTask> next) async {
    if (_busy) return false;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setString(
        _storageKey,
        jsonEncode(next.map((task) => task.toJson()).toList()),
      );
      if (!mounted) return false;
      setState(() {
        _tasks = next;
        _saving = false;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _error = 'Could not save that change. Please try again.';
      });
      return false;
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final title = _input.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Write a task first.');
      _inputFocus.requestFocus();
      return;
    }
    final editingId = _editingId;
    final List<_TodoTask> next;
    if (editingId == null) {
      next = [
        _TodoTask(
          id: '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
          title: title,
          done: false,
        ),
        ..._tasks,
      ];
    } else {
      next = _tasks.map((task) {
        return task.id == editingId ? task.copyWith(title: title) : task;
      }).toList();
    }
    final saved = await _commit(next);
    if (!mounted || !saved) return;
    _input.clear();
    _inputFocus.unfocus();
    setState(() {
      _editingId = null;
      if (editingId == null && _filter == 'Done') _filter = 'Active';
    });
  }

  void _edit(_TodoTask task) {
    if (_busy) return;
    setState(() {
      _editingId = task.id;
      _error = null;
      _input.text = task.title;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    if (_busy) return;
    _input.clear();
    _inputFocus.unfocus();
    setState(() => _editingId = null);
  }

  Future<void> _toggle(_TodoTask task) async {
    await _commit(_tasks.map((current) {
      return current.id == task.id
          ? current.copyWith(done: !current.done)
          : current;
    }).toList());
  }

  Future<void> _delete(_TodoTask task) async {
    final saved = await _commit(
      _tasks.where((current) => current.id != task.id).toList(),
    );
    if (!mounted || !saved) return;
    if (_editingId == task.id) _cancelEdit();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task.done).length;
    final remaining = _tasks.length - completed;
    final visible = _tasks.where((task) {
      if (_filter == 'Active') return !task.done;
      if (_filter == 'Done') return task.done;
      return true;
    }).toList();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: _green),
          scaffoldBackgroundColor: _background,
        ),
        child: Material(
          color: _background,
          child: SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ONE THING AT A TIME',
                          style: TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'My tasks',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Make room for what matters.',
                          style: TextStyle(color: _muted, fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !_loaded
                                    ? 'Your progress'
                                    : _tasks.isEmpty
                                        ? 'A fresh start.'
                                        : remaining == 0
                                            ? 'All done. Nicely done.'
                                            : '$remaining ${remaining == 1 ? 'task' : 'tasks'} to go',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: _tasks.isEmpty ? 0 : completed / _tasks.length,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFF537D68),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFCDEDA3),
                                  ),
                                  semanticsLabel: 'Completed tasks',
                                  semanticsValue: '$completed of ${_tasks.length}',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _loaded
                                    ? '$completed of ${_tasks.length} completed'
                                    : 'Opening your list…',
                                style: const TextStyle(color: Color(0xFFDDE9DF)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_editingId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Expanded(child: Text('Editing task')),
                                TextButton(
                                  onPressed: _busy ? null : _cancelEdit,
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                focusNode: _inputFocus,
                                enabled: !_busy,
                                maxLength: 160,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'What needs doing?',
                                  labelText: _editingId == null ? 'New task' : 'Task title',
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD9E0D5)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _green,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        _editingId == null ? Icons.add : Icons.check,
                                        semanticLabel: _editingId == null ? 'Add task' : 'Save task',
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_error!, style: const TextStyle(color: Color(0xFF9B2C2C))),
                                  if (!_loaded && !_loading)
                                    TextButton(onPressed: _load, child: const Text('Try again')),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['All', 'Active', 'Done'].map((label) {
                            final count = label == 'All'
                                ? _tasks.length
                                : label == 'Active' ? remaining : completed;
                            return ChoiceChip(
                              label: Text('$label  $count'),
                              selected: _filter == label,
                              selectedColor: const Color(0xFFDCEBCB),
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _filter = label),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_loaded && visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          const Icon(Icons.checklist_rounded, size: 48, color: _muted),
                          const SizedBox(height: 12),
                          Text(
                            _tasks.isEmpty
                                ? 'Your list starts here'
                                : _filter == 'Active' ? 'You’re all caught up!' : 'No completed tasks yet',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _tasks.isEmpty ? 'Add your first task above.' : 'Small steps still count.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = visible[index];
                          return Container(
                            key: ValueKey(task.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE4E8DD)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: task.done,
                                  onChanged: _busy ? null : (_) => _toggle(task),
                                  semanticLabel: task.done
                                      ? 'Mark ${task.title} incomplete'
                                      : 'Complete ${task.title}',
                                  activeColor: _green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        color: task.done ? _muted : _ink,
                                        fontSize: 15,
                                        decoration: task.done ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  enabled: !_busy,
                                  tooltip: 'Task options',
                                  onSelected: (action) {
                                    if (action == 'edit') _edit(task);
                                    if (action == 'delete') _delete(task);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),
                  ),
                if (_loaded)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 18, 24, 28),
                      child: Text(
                        'Saved on this device',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoTask {
  const _TodoTask({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  final bool done;

  _TodoTask copyWith({String? title, bool? done}) =>
      _TodoTask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory _TodoTask.fromJson(dynamic value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['title'] is! String ||
        value['done'] is! bool) {
      throw const FormatException('Invalid task');
    }
    final id = value['id'] as String;
    final title = value['title'] as String;
    if (id.isEmpty || title.trim().isEmpty) {
      throw const FormatException('Invalid task');
    }
    return _TodoTask(id: id, title: title, done: value['done'] as bool);
  }
}
