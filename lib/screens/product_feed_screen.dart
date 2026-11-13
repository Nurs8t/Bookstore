import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api_service.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/error_state.dart';
import '../widgets/product_list_tile.dart';
import 'product_detail_screen.dart';

/// UI-дың 3 күйі. Бір уақытта тек біреуі ғана белсенді.
enum LoadStatus { loading, success, error }

/// LAB 10: Cloud Product Explorer — fakestoreapi.com/products тізімі.
class ProductFeedScreen extends StatefulWidget {
  const ProductFeedScreen({super.key});

  @override
  State<ProductFeedScreen> createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends State<ProductFeedScreen> {
  final ProductApiService _api = ProductApiService();

  LoadStatus _status = LoadStatus.loading;
  List<Product> _products = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  /// Алғашқы жүктеу және "Қайта қосылу" батырмасы: толық экранды спиннер.
  Future<void> _loadProducts() async {
    // initState кезінде күй бұрыннан loading — setState шақыру қажет емес (әрі рұқсат етілмейді).
    if (_status != LoadStatus.loading) {
      setState(() => _status = LoadStatus.loading);
    }

    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _status = LoadStatus.error;
      });
    }
  }

  /// Pull-to-Refresh: тізім экранда қала береді, тек RefreshIndicator айналады.
  /// Жаңарту сәтсіз болса, ескі тізім жоғалмайды — тек SnackBar шығады.
  Future<void> _refresh() async {
    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_products.isEmpty) {
        setState(() {
          _errorMessage = e.message;
          _status = LoadStatus.error;
        });
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Қайталау',
              textColor: Colors.white,
              onPressed: _refresh,
            ),
          ));
      }
    }
  }

  void _openDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Онлайн дүкен'),
        actions: const [CartBadgeButton()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      // 1) Loading
      case LoadStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Тауарлар жүктелуде...'),
            ],
          ),
        );

      // 2) Error with Retry
      case LoadStatus.error:
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ErrorState(message: _errorMessage, onRetry: _loadProducts),
        );

      // 3) Success
      case LoadStatus.success:
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _products.isEmpty
              ? ErrorState(message: 'Сервер бос тізім қайтарды.', onRetry: _loadProducts)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductListTile(
                      product: product,
                      onTap: () => _openDetail(product),
                    );
                  },
                ),
        );
    }
  }
}
