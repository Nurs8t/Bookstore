import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/book.dart';
import '../utils/app_theme.dart';

/// Deep Link бөлісу беті (modal bottom sheet): narxoz://store/product/{id}
class ShareLinkSheet extends StatelessWidget {
  final Book book;

  const ShareLinkSheet({super.key, required this.book});

  /// Бетті ашу үшін ыңғайлы әдіс.
  static Future<void> show(BuildContext context, Book book) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareLinkSheet(book: book),
    );
  }

  Future<void> _copy(BuildContext context) async {
    // Бет жабылғаннан кейін context жарамсыз болады, сондықтан алдын ала аламыз.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await Clipboard.setData(ClipboardData(text: book.deepLink));

    navigator.pop(); // бетті жабу
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Сілтеме көшірілді ✓')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кітаппен бөлісу',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Deep Link',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: context.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      book.deepLink,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Көшіру',
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Сілтемені көшіру'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
