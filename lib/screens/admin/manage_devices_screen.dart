import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/app_controller.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_text_field.dart';

class ManageDevicesScreen extends StatefulWidget {
  const ManageDevicesScreen({super.key});

  @override
  State<ManageDevicesScreen> createState() => _ManageDevicesScreenState();
}

class _ManageDevicesScreenState extends State<ManageDevicesScreen> {
  static const List<String> _validCategories = [
    'Smartphones',
    'Laptops',
    'Home Appliances',
    'TV & Audio',
    'Gaming Consoles',
    'Other',
  ];

  void _showAddEditDeviceDialog({Product? existingDevice}) {
    final isEditing = existingDevice != null;

    final titleController = TextEditingController(text: isEditing ? existingDevice.title : '');
    final brandController = TextEditingController(text: isEditing ? existingDevice.brand : '');
    final priceController = TextEditingController(text: isEditing ? existingDevice.price.toString() : '');
    final descriptionController = TextEditingController(text: isEditing ? existingDevice.description : '');

    String selectedCategory = isEditing && _validCategories.contains(existingDevice.category)
        ? existingDevice.category
        : 'Smartphones';

    String? formError;
    File? selectedImage;
    String? currentThumbnail = isEditing ? existingDevice.thumbnail : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Device' : 'Add New Device'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (formError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          formError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    // Image Picker Widget
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() {
                            selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, fit: BoxFit.cover),
                              )
                            : currentThumbnail != null && currentThumbnail!.isNotEmpty && !currentThumbnail!.startsWith('http')
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(currentThumbnail!), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Text('Invalid Image'))),
                                  )
                                : currentThumbnail != null && currentThumbnail!.startsWith('http')
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(currentThumbnail!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Text('Invalid URL'))),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Add Product Photo', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                      ),
                    ),
                    if (selectedImage != null || currentThumbnail != null)
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            selectedImage = null;
                            currentThumbnail = null;
                          });
                        },
                        child: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                      ),
                    CustomTextField(
                        label: 'Device Name (Title)',
                        controller: titleController,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Brand',
                        controller: brandController,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _validCategories.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Price',
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Description',
                        controller: descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              String title = titleController.text.trim();
                              String brand = brandController.text.trim();
                              String priceText = priceController.text.trim();
                              String desc = descriptionController.text.trim();

                              if (title.isEmpty) {
                                setStateDialog(() => formError = 'Device Name is required'); return;
                              }
                              if (brand.isEmpty) {
                                setStateDialog(() => formError = 'Brand is required'); return;
                              }
                              if (priceText.isEmpty || double.tryParse(priceText) == null) {
                                setStateDialog(() => formError = 'Valid Price is required'); return;
                              }
                              if (desc.isEmpty) {
                                setStateDialog(() => formError = 'Description is required'); return;
                              }

                              setStateDialog(() => formError = null);

                              final newProduct = Product(
                                id: isEditing ? existingDevice.id : DateTime.now().millisecondsSinceEpoch,
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: selectedCategory,
                                price: double.parse(priceController.text.trim()),
                                discountPercentage: isEditing ? existingDevice.discountPercentage : 0.0,
                                rating: isEditing ? existingDevice.rating : 5.0,
                                stock: isEditing ? existingDevice.stock : 100,
                                brand: brandController.text.trim(),
                                thumbnail: selectedImage?.path ?? currentThumbnail ?? 'https://cdn.dummyjson.com/product-images/1/thumbnail.jpg',
                                images: selectedImage != null ? [selectedImage!.path] : (isEditing ? existingDevice.images : []),
                                tags: isEditing ? existingDevice.tags : [],
                              );

                              if (isEditing) {
                                AppController.instance.updateProduct(existingDevice.id, newProduct);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device updated'), backgroundColor: Colors.green));
                              } else {
                                AppController.instance.addProduct(newProduct);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device added'), backgroundColor: Colors.green));
                              }

                              Navigator.of(context).pop();
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            );
          },
        );
      },
    );
  }

  void _deleteDevice(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Device'),
          content: Text('Are you sure you want to delete ${product.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                AppController.instance.deleteProduct(product.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device deleted'), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devices'),
      ),
      body: AnimatedBuilder(
        animation: AppController.instance,
        builder: (context, _) {
          final products = AppController.instance.products;

          if (products.isEmpty) {
            return const Center(child: Text('No devices found.', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.thumbnail,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Icon(Icons.devices, size: 40, color: Colors.grey),
                    ),
                  ),
                  title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${product.brand} · ${product.category} · \$${product.price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDeviceDialog(existingDevice: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDevice(product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDeviceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
