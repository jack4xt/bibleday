import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, String>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes = raw.map((n) {
        final parts = n.split('|||');
        return {
          'title': parts.isNotEmpty ? parts[0] : '',
          'text': parts.length > 1 ? parts[1] : '',
          'date': parts.length > 2 ? parts[2] : '',
        };
      }).toList();
      _loading = false;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _notes.map((n) => '${n['title']}|||${n['text']}|||${n['date']}').toList();
    await prefs.setStringList('notes', raw);
  }

  String _formatDate(String isoDate, AppLocalizations l) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = [
        l.january, l.february, l.march, l.april, l.may, l.june,
        l.july, l.august, l.september, l.october, l.november, l.december
      ];
      return '${dt.day}. ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _showNoteDialog(AppLocalizations l, {Map<String, String>? existing, int? index}) {
    final titleController = TextEditingController(text: existing?['title'] ?? '');
    final textController = TextEditingController(text: existing?['text'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceElevatedColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing != null ? l.editNote : l.newNote,
                    style: Theme.of(context).textTheme.displayMedium),
                SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.cinzel(color: AppTheme.textPrimaryColor(context), fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l.noteTitle,
                    hintStyle: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context)),
                    filled: true, fillColor: AppTheme.surfaceColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldColor(context))),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 6,
                  style: GoogleFonts.crimsonText(color: AppTheme.textPrimaryColor(context), fontSize: 17),
                  decoration: InputDecoration(
                    hintText: l.noteText,
                    hintStyle: GoogleFonts.crimsonText(color: AppTheme.textSecondaryColor(context)),
                    filled: true, fillColor: AppTheme.surfaceColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldColor(context))),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    if (existing != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          setState(() => _notes.removeAt(index!));
                          _saveNotes();
                          Navigator.pop(context);
                        },
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.cancel,
                          style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context))),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final text = textController.text.trim();
                        if (text.isEmpty) return;
                        final note = {
                          'title': title.isEmpty ? l.notes : title,
                          'text': text,
                          'date': DateTime.now().toIso8601String(),
                        };
                        setState(() {
                          if (existing != null) {
                            _notes[index!] = note;
                          } else {
                            _notes.insert(0, note);
                          }
                        });
                        _saveNotes();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor(context),
                        foregroundColor: AppTheme.backgroundColorOf(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l.save, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.notes)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(l),
        backgroundColor: AppTheme.goldColor(context),
        foregroundColor: AppTheme.backgroundColorOf(context),
        child: Icon(Icons.add),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.goldColor(context)))
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, color: AppTheme.textSecondaryColor(context), size: 64),
                      SizedBox(height: 16),
                      Text(l.noNotes, style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 8),
                      Text(l.noNotesDesc,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor(context)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(note['title'] ?? '',
                            style: GoogleFonts.cinzel(
                                color: AppTheme.goldColor(context), fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(note['text'] ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.crimsonText(
                                    color: AppTheme.textPrimaryColor(context), fontSize: 16, height: 1.5)),
                            SizedBox(height: 8),
                            Text(_formatDate(note['date'] ?? '', l),
                                style: GoogleFonts.cinzel(
                                    color: AppTheme.textSecondaryColor(context), fontSize: 11)),
                          ],
                        ),
                        onTap: () => _showNoteDialog(l, existing: note, index: index),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
                  },
                ),
    );
  }
}
