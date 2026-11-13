import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../utils/app_theme.dart';

/// LAB 10: Deep Link бөлісу беті (modal bottom sheet).
class ShareLinkSheet extends StatelessWidget {
  final Product product;

  const ShareLinkSheet({super.key, required this.product});

  /// Бетті ашу үшін ыңғайлы әдіс.
  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareLinkSheet(product: product),
    );
  }

  Future<void> _copy(BuildContext context) async {
    // Бет жабылғаннан кейін context жарамсыз болады, сондықтан алдын ала аламыз.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await Clipboard.setData(ClipboardData(text: product.deepLink));

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
              'Тауармен бөлісу',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.title,
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
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      product.deepLink,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
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
