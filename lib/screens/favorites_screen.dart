import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/empty_state.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().books;

    return Scaffold(
      appBar: AppBar(title: const Text('Таңдаулы кітаптар')),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'Таңдаулылар тізімі бос',
              message:
                  'Каталогтағы ♡ белгісін басып, ұнаған кітаптарды осында сақтаңыз.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final book = favorites[index];
                    return BookListTile(
                      book: book,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BookDetailScreen(book: book)),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
