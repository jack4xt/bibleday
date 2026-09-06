import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bookmarks_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _bookmarks = BookmarksService();
  List<BookmarkGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final groups = await _bookmarks.getBookmarkGroups();
    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  Future<void> _remove(BookmarkGroup group) async {
    await _bookmarks.removeBookmarkGroup(group);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.bookmarks),
        actions: [
          if (_groups.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.goldColor(context)),
              onPressed: _load,
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.goldColor(context)))
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline,
                          color: AppTheme.textSecondaryColor(context), size: 64),
                      SizedBox(height: 16),
                      Text(l.noBookmarks,
                          style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 8),
                      Text(l.noBookmarksDesc,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 14),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return _BookmarkGroupCard(
                      group: group,
                      onRemove: () => _remove(group),
                    ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
                  },
                ),
    );
  }
}

class _BookmarkGroupCard extends StatefulWidget {
  final BookmarkGroup group;
  final VoidCallback onRemove;

  const _BookmarkGroupCard({required this.group, required this.onRemove});

  @override
  State<_BookmarkGroupCard> createState() => _BookmarkGroupCardState();
}

class _BookmarkGroupCardState extends State<_BookmarkGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.group.verseNumbers.length > 1;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded
                ? AppTheme.goldColor(context).withValues(alpha: 0.5)
                : AppTheme.goldColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _expanded
                      // Rozbalené — zobraz verše jeden pod druhým s číslem
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.group.verseNumbers.asMap().entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontStyle: FontStyle.italic, height: 1.5),
                                  children: [
                                    TextSpan(
                                      text: '${widget.group.verseNumbers[e.key]}  ',
                                      style: GoogleFonts.cinzel(
                                          color: AppTheme.goldColor(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: '"${widget.group.texts[e.key]}"'),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      // Collapsed — první verš zkrácený
                      : Text(
                          '"${widget.group.texts.first}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic, height: 1.5),
                        ),
                ),
                SizedBox(width: 8),
                Column(
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textSecondaryColor(context),
                      size: 18,
                    ),
                    if (isGroup && !_expanded)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.purpleColor(context).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.group.verseNumbers.length}',
                          style: GoogleFonts.cinzel(
                              color: AppTheme.purpleColor(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    widget.group.reference,
                    style: GoogleFonts.cinzel(
                        color: AppTheme.goldColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.bookmark_remove,
                        color: AppTheme.textSecondaryColor(context), size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
