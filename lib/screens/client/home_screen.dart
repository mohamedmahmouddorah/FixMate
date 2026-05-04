import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/product_card.dart';
import 'create_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppController.instance.products.isEmpty) {
        AppController.instance.fetchProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, _) {
        final allProducts = AppController.instance.products;
        final isLoading = AppController.instance.isLoadingProducts;
        final error = AppController.instance.productsError;
        
        // Extract unique categories dynamically
        final categories = ['All', ...allProducts.map((p) => p.category).where((c) => c.isNotEmpty).toSet()];
        
        final displayProducts = _selectedCategory == 'All' 
            ? allProducts 
            : allProducts.where((p) => p.category == _selectedCategory).toList();

        final isClient = AppController.instance.authService.currentUserRole == 'client' || AppController.instance.authService.currentUserRole == null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Devices'),
          ),
          body: Column(
            children: [
              if (!isLoading && allProducts.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text('Error: $error'))
                        : displayProducts.isEmpty
                            ? const Center(child: Text('No devices found in this category'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: displayProducts.length,
                                itemBuilder: (context, index) {
                                  final product = displayProducts[index];
                                  return ProductCard(
                                    product: product,
                                    isFavorite: AppController.instance.isFavorite(product.id),
                                    onTap: () {},
                                    onFavoriteToggle: () {
                                      AppController.instance.toggleFavorite(product.id);
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
          floatingActionButton: isClient ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
              );
            },
            child: const Icon(Icons.add),
          ) : null,
        );
      },
    );
  }
}
