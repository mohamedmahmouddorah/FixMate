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
  File? _selectedImage;
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
      imagePath: _selectedImage?.path,
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add an optional photo', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              if (_selectedImage != null)
                TextButton(
                  onPressed: () => setState(() => _selectedImage = null),
                  child: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
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
