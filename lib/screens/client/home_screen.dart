import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';
import 'create_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        
        List<Product> displayProducts = _selectedCategory == 'All' 
            ? allProducts 
            : allProducts.where((p) => p.category == _selectedCategory).toList();

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          displayProducts = displayProducts.where((p) =>
              p.title.toLowerCase().contains(query) ||
              p.brand.toLowerCase().contains(query)).toList();
        }

        final isClient = AppController.instance.authService.currentUserRole == 'client' || AppController.instance.authService.currentUserRole == null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Devices'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
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
                            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
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
                                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.60 : 0.52,
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
