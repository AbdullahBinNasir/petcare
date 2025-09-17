import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/pet_care_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  
  const SplashScreen({super.key, this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late AnimationController _progressAnimationController;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;
  
  bool _showProgressBar = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Fade animation controller
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Slide animation controller
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Pulse animation controller
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Rotation animation controller
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Progress animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.linear,
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startSplashSequence() async {
    // Start logo animation
    _logoAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start text fade and slide animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Start pulsing effect
    _pulseAnimationController.repeat(reverse: true);
    
    // Start rotation animation
    _rotationAnimationController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 700));
    
    // Show progress bar
    setState(() {
      _showProgressBar = true;
    });
    
    // Start progress animation
    _progressAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Animation completed
    setState(() {
      _animationCompleted = true;
    });
    
    // Navigate to next screen after a brief pause
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (widget.child != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.child!,
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo section
              _buildLogoSection(),
              
              const SizedBox(height: 60),
              
              // App name and tagline
              _buildAppNameSection(),
              
              const SizedBox(height: 80),
              
              // Loading section
              _buildLoadingSection(),
              
              const Spacer(flex: 1),
              
              // Footer section
              _buildFooterSection(),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: PetCareTheme.primaryGradient,
                      ),
                      boxShadow: [
                        PetCareTheme.elevatedShadow,
                        BoxShadow(
                          color: PetCareTheme.accentGold.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating background ring
                        AnimatedBuilder(
                          animation: _rotationAnimationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: PetCareTheme.primaryBrown.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: _CirclePainter(),
                                ),
                              ),
                            );
                          },
                        ),
                        // Pet icon
                        Icon(
                          Icons.pets_rounded,
                          size: 60,
                          color: PetCareTheme.primaryBeige,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppNameSection() {
    return AnimatedBuilder(
      animation: _fadeAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // App name with gradient text effect
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: PetCareTheme.primaryGradient,
                  ).createShader(bounds),
                  child: Text(
                    'Pet Care',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: PetCareTheme.primaryBrown,
                      letterSpacing: -1.5,
                      shadows: [
                        Shadow(
                          color: PetCareTheme.primaryBrown.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tagline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: PetCareTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PetCareTheme.primaryBrown.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Your Comprehensive Pet Care Companion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PetCareTheme.lightBrown,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _fadeAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Loading indicator
              if (!_animationCompleted) ...[
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PetCareTheme.primaryBrown,
                    ),
                    backgroundColor: PetCareTheme.primaryBrown.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Progress bar
              if (_showProgressBar) ...[
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PetCareTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimationController,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 200 * _progressAnimation.value,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: PetCareTheme.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: PetCareTheme.primaryBrown.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Loading text
              Text(
                _animationCompleted 
                    ? 'Welcome!' 
                    : _showProgressBar 
                        ? 'Loading your pet care experience...' 
                        : 'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PetCareTheme.lightBrown,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterSection() {
    return AnimatedBuilder(
      animation: _fadeAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.8,
          child: Column(
            children: [
              Text(
                'Made with ❤️ for Pet Lovers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PetCareTheme.lightBrown.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: PetCareTheme.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom painter for decorative circles
class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PetCareTheme.primaryBrown.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw decorative arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
