import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCategory;
  const HomeScreen({super.key, this.initialCategory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.all_inclusive},
    {'name': 'Phones', 'icon': Icons.phone_android},
    {'name': 'Laptops', 'icon': Icons.laptop},
    {'name': 'Refrigerators', 'icon': Icons.kitchen},
    {'name': 'Washing Machines', 'icon': Icons.wash},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppController.instance.products.isEmpty) {
        AppController.instance.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to request a repair.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, _) {
        final allProducts = AppController.instance.products;
        final isLoading = AppController.instance.isLoadingProducts;

        List<Product> displayProducts = _selectedCategory == 'All'
            ? allProducts
            : allProducts
                  .where((p) => p.category == _selectedCategory)
                  .toList();

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          displayProducts = displayProducts
              .where(
                (p) =>
                    p.title.toLowerCase().contains(query) ||
                    p.brand.toLowerCase().contains(query),
              )
              .toList();
        }

        return Scaffold(
          drawer: Drawer(
            child: Container(
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF161B22)
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.blueGrey[800]
                            : Colors.grey[400],
                        backgroundImage:
                            AuthService.instance.currentUserImage != null
                            ? FileImage(
                                File(AuthService.instance.currentUserImage!),
                              )
                            : null,
                        child: AuthService.instance.currentUserImage == null
                            ? Icon(
                                Icons.person,
                                color: isDark ? Colors.white70 : Colors.white,
                                size: 40,
                              )
                            : null,
                      ),
                      accountName: Text(
                        AuthService.instance.currentUserName ?? 'Guest User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      accountEmail: Text(
                        AuthService.instance.currentUserEmail ??
                            'Welcome to FixMate',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildDrawerSectionTitle(context, 'CATEGORIES'),
                        ..._categories.map((cat) {
                          final isSelected = _selectedCategory == cat['name'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white12 : Colors.grey[200])
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                cat['icon'],
                                color: isSelected
                                    ? (isDark ? Colors.amber : Colors.black87)
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black54),
                              ),
                              title: Text(
                                cat['name'],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? (isDark ? Colors.amber : Colors.black)
                                      : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                ),
                              ),
                              onTap: () {
                                setState(() => _selectedCategory = cat['name']);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                        _buildDrawerSectionTitle(context, 'ACCOUNT'),
                        ListTile(
                          leading: Icon(
                            AuthService.instance.isGuest
                                ? Icons.login
                                : Icons.logout,
                            color: AuthService.instance.isGuest
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                          title: Text(
                            AuthService.instance.isGuest
                                ? 'Sign In / Login'
                                : 'Logout',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            AuthService.instance.logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'v1.2.0 • Fixed Edition',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: isDark
                    ? const Color(0xFF161B22)
                    : Colors.white,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'FixMate - $_selectedCategory',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    color: isDark ? const Color(0xFF0D1117) : Colors.grey[50],
                    child: Center(
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(
                          _categories.firstWhere(
                            (c) => c['name'] == _selectedCategory,
                            orElse: () => _categories[0],
                          )['icon'],
                          size: 150,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF21262D)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for devices...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedCategory = cat['name']),
                          borderRadius: BorderRadius.circular(25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.amber : Colors.black)
                                  : (isDark
                                        ? const Color(0xFF21262D)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.amber : Colors.black)
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey[300]!),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (displayProducts.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No devices found')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 4
                          : 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = displayProducts[index];
                      return ProductCard(
                        product: product,
                        isFavorite: AppController.instance.isFavorite(
                          product.id,
                        ),
                        onTap: () {},
                        onFavoriteToggle: () =>
                            AppController.instance.toggleFavorite(product.id),
                      );
                    }, childCount: displayProducts.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          floatingActionButton:
              (AuthService.instance.isAdmin ||
                  AuthService.instance.isTechnician)
              ? null
              : FloatingActionButton(
                  backgroundColor: const Color(0xFF1A237E),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (AuthService.instance.isGuest) {
                      _showGuestDialog(context);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateRequestScreen(),
                        ),
                      );
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildDrawerSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white38
              : Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
