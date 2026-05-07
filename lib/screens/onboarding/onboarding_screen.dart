import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to FixMate',
      description: 'Your one-stop solution for all home appliance repairs.',
      image: 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=500&auto=format',
      icon: Icons.build_circle_outlined,
    ),
    OnboardingData(
      title: 'Expert Technicians',
      description: 'Get your devices fixed by certified professionals quickly.',
      image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format',
      icon: Icons.engineering_outlined,
    ),
    OnboardingData(
      title: 'Easy Tracking',
      description: 'Track your repair status in real-time from anywhere.',
      image: 'https://images.unsplash.com/photo-1551288049-bbbda536ad0a?w=500&auto=format',
      icon: Icons.track_changes_outlined,
    ),
  ];

  void _finishOnboarding() {
    AppController.instance.completeOnboarding();
    // No need for Navigator.pushReplacement here,
    // main.dart will rebuild and switch home automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final data = _pages[index];
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(data.icon, size: 120, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(height: 50),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Navigation Bottom
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dots
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 5),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Skip
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
