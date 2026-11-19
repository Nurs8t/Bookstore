import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_item.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

/// Баптаулар мен оқу жазбалары (Offline-First Settings & Notes Vault).
/// Барлығы shared_preferences-те сақталады және қолданбаны толық жауып
/// ашқанда (cold restart) бірден қалпына келеді.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final name = context.read<SettingsProvider>().displayName;
    _nameController = TextEditingController(
      text: name == SettingsProvider.defaultName ? '' : name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    await context.read<SettingsProvider>().setDisplayName(_nameController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Ат сақталды ✓')));
  }

  Future<void> _addNote() async {
    final text = _noteController.text;
    if (text.trim().isEmpty) return;
    await context.read<NotesProvider>().add(text);
    _noteController.clear();
  }

  Future<void> _deleteNote(NoteItem note) async {
    final notes = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await notes.delete(note.id);
    if (removed == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('«${note.title}» өшірілді'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => notes.restore(removed.$1, removed.$2),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Баптаулар мен жазбалар')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------- Тақырып (header): сақталған ат ----------
              _HeaderCard(
                name: settings.displayName,
                notesCount: notes.length,
                doneCount: notesProvider.doneCount,
              ),
              const SizedBox(height: 16),

              // ---------- 1. Қараңғы тақырып ----------
              _Section(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: context.accent,
                    ),
                    title: const Text('Қараңғы тақырып'),
                    subtitle: const Text('Қолданбаны қайта ашқанда да сақталады'),
                    value: settings.isDarkMode,
                    onChanged: settings.setDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------- 2. Көрсетілетін ат ----------
              const _SectionTitle('Көрсетілетін ат'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _saveName(),
                      decoration: const InputDecoration(
                        hintText: 'Атыңызды жазыңыз',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saveName,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сақтау'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- 3. Оқу жазбалары ----------
              const _SectionTitle('Оқу жазбалары'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addNote(),
                      decoration: const InputDecoration(
                        hintText: 'Мысалы: «Абай жолын» оқып шығу',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Жазба қосу',
                    onPressed: _addNote,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(56, 56),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.sticky_note_2_outlined, size: 56, color: Colors.brown.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Жазба әлі жоқ. Оқығыңыз келетін кітапты жазып көріңіз.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                _Section(
                  children: [
                    for (final note in notes)
                      _NoteTile(
                        key: ValueKey(note.id),
                        note: note,
                        onToggle: () => notesProvider.toggle(note.id),
                        onDelete: () => _deleteNote(note),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final int notesCount;
  final int doneCount;

  const _HeaderCard({required this.name, required this.notesCount, required this.doneCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.gold,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сәлем, $name!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Жазбалар: $notesCount · Орындалды: $doneCount',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NoteTile({super.key, required this.note, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: note.isCompleted,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        note.title,
        style: TextStyle(
          decoration: note.isCompleted ? TextDecoration.lineThrough : null,
          color: note.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: Text(note.dateText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
      trailing: IconButton(
        tooltip: 'Өшіру',
        icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
        onPressed: onDelete,
      ),
      onTap: onToggle,
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: context.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
