import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/routes/route_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/role_routing.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthProvider _auth = Get.find<AuthProvider>();
  bool _navigated = false;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    for (var i = 1; i < _slides.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() => _currentIndex = i);
      await _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _routeFromAuth();
  }

  Future<void> _routeFromAuth() async {
    if (!mounted || _navigated) return;
    if (!_auth.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      return _routeFromAuth();
    }

    late final String route;
    if (!_auth.isAuthenticated) {
      route = RouteConstants.login;
    } else if (_auth.requiresEmailVerification) {
      route = RouteConstants.verifyEmail;
    } else {
      route = landingRouteForRole(_auth.role);
    }

    _navigated = true;
    if (!mounted) return;
    Get.offNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F52D6), Color(0xFF13A8D9), Color(0xFF3CC6E8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pageHeight = (constraints.maxHeight * 0.72)
                      .clamp(220.0, 320.0)
                      .toDouble();
                  final indicatorGap = constraints.maxHeight < 430
                      ? 12.0
                      : 20.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: pageHeight,
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _slides.length,
                          itemBuilder: (context, index) {
                            return _SplashSlideCard(slide: _slides[index]);
                          },
                        ),
                      ),
                      SizedBox(height: indicatorGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentIndex ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(
                                alpha: index == _currentIndex ? 0.95 : 0.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashSlideData {
  const _SplashSlideData({
    required this.title,
    required this.subtitle,
    this.icon,
    this.isLogo = false,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isLogo;
}

const List<_SplashSlideData> _slides = [
  _SplashSlideData(
    title: AppConstants.appName,
    subtitle: 'Smart school operations in one platform',
    isLogo: true,
  ),
  _SplashSlideData(
    title: 'Students First',
    subtitle: 'Attendance, results, and progress at a glance',
    icon: Icons.groups_rounded,
  ),
  _SplashSlideData(
    title: 'Education Tools',
    subtitle: 'Timetable, classes, library, and learning support',
    icon: Icons.menu_book_rounded,
  ),
];

class _SplashSlideCard extends StatelessWidget {
  const _SplashSlideCard({required this.slide});

  final _SplashSlideData slide;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconBox = (constraints.maxHeight * 0.46)
                .clamp(78.0, 122.0)
                .toDouble();
            final iconSize = (iconBox * 0.5).clamp(38.0, 62.0).toDouble();
            final titleSize = (constraints.maxHeight * 0.12)
                .clamp(24.0, 31.0)
                .toDouble();
            final subtitleSize = constraints.maxHeight < 250 ? 13.0 : 14.0;
            final gapLarge = constraints.maxHeight < 250 ? 10.0 : 16.0;
            final gapSmall = constraints.maxHeight < 250 ? 6.0 : 8.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: slide.isLogo
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.school_rounded,
                                size: iconSize,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : Icon(slide.icon, size: iconSize, color: Colors.white),
                ),
                SizedBox(height: gapLarge),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: gapSmall),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.3,
                    fontSize: subtitleSize,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
