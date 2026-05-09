import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'create_request_screen.dart';
import '../../theme/app_theme.dart';
import '../../controllers/app_controller.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel or Thumbnail
            if (product.images.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.images[index].startsWith('http')
                          ? Image.network(
                              product.images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                            )
                          : Image.file(
                              File(product.images[index]),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                            ),
                    );
                  },
                ),
              )
            else
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.thumbnail.startsWith('http')
                      ? Image.network(
                          product.thumbnail,
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                        )
                      : Image.file(
                          File(product.thumbnail),
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                        ),
                ),
              ),
            
            const SizedBox(height: 24),
            Text(
              product.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    product.brand,
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (product.discountPercentage > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${product.discountPercentage}% OFF',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              )
            ],
            const Divider(height: 32),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (AppController.instance.authService.currentUserRole == 'client')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRequestScreen(initialDevice: product.title),
                    ),
                  );
                },
                icon: const Icon(Icons.build),
                label: const Text('Request Repair for this Device'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
