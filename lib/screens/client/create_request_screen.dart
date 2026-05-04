import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class CreateRequestScreen extends StatefulWidget {
  final String? initialDevice;
  const CreateRequestScreen({super.key, this.initialDevice});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Smartphones';
  bool _isGettingLocation = false;
  final List<File> _selectedImages = [];
  
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 images only')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          pickedFiles.take(5 - _selectedImages.length).map((file) => File(file.path)),
        );
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.initialDevice != null) {
      _deviceController.text = widget.initialDevice!;
    }
  }

  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    // Simulate GPS fetch
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isGettingLocation = false;
        _locationController.text = '123 Main Street, Cairo, Egypt'; // Simulated GPS Address
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location determined automatically!'), 
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    
    AppController.instance.createRequest(
      device: _deviceController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      imagePaths: _selectedImages.map((f) => f.path).toList(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request created successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Device Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Device Name / Brand',
                controller: _deviceController,
                prefixIcon: Icons.devices_other,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Device name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Device Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Smartphones', child: Text('Smartphones')),
                  DropdownMenuItem(value: 'Laptops', child: Text('Laptops')),
                  DropdownMenuItem(value: 'Home Appliances', child: Text('Home Appliances')),
                  DropdownMenuItem(value: 'Washing Machines', child: Text('Washing Machines')),
                  DropdownMenuItem(value: 'Refrigerators', child: Text('Refrigerators')),
                  DropdownMenuItem(value: 'TV & Audio', child: Text('TV & Audio')),
                  DropdownMenuItem(value: 'Gaming Consoles', child: Text('Gaming Consoles')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description of the problem',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Your Location',
                controller: _locationController,
                prefixIcon: Icons.location_on_outlined,
                suffixIcon: _isGettingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.blue),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Get current location',
                      ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Location is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Image Picker Section
              const Text('Add Photos (Up to 5)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Add', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Submit Request',
                icon: Icons.send_rounded,
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
