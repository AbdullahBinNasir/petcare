import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import '../pet_owner/pet_owner_dashboard.dart';
import '../veterinarian/vet_dashboard.dart';
import '../shelter/shelter_dashboard.dart';
import '../shelter_owner/shelter_owner_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  AnimationController? _animationController;
  AnimationController? _logoAnimationController;
  AnimationController? _floatingAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _logoRotation;
  Animation<double>? _logoScale;
  Animation<double>? _floatingAnimation;

  // Custom colors
  static const Color primaryBrown = Color(0xFF4D270E);
  static const Color lightBeige = Color(0xFFF5F5DC);
  static const Color darkBrown = Color(0xFF2A1507);
  static const Color mediumBrown = Color(0xFF6B3617);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController!,
      curve: Curves.elasticOut,
    ));
    
    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController!,
      curve: Curves.elasticOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    _animationController!.forward();
    _logoAnimationController!.forward();
    _floatingAnimationController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController?.dispose();
    _logoAnimationController?.dispose();
    _floatingAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: lightBeige,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
                  child: _floatingAnimation != null ? AnimatedBuilder(
                    animation: _floatingAnimation!,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation!.value),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: lightBeige,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: primaryBrown.withOpacity(0.3),
                                blurRadius: 80,
                                offset: const Offset(0, 40),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAnimatedLogo(),
                                const SizedBox(height: 35),
                                _buildWelcomeSection(),
                                const SizedBox(height: 40),
                                _buildEmailField(),
                                const SizedBox(height: 20),
                                _buildPasswordField(),
                                const SizedBox(height: 15),
                                _buildForgotPassword(),
                                const SizedBox(height: 35),
                                _buildSignInButton(),
                                const SizedBox(height: 30),
                                _buildAnimatedDivider(),
                                const SizedBox(height: 30),
                                _buildCreateAccountButton(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ) : Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: lightBeige,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: primaryBrown.withOpacity(0.3),
                          blurRadius: 80,
                          offset: const Offset(0, 40),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnimatedLogo(),
                          const SizedBox(height: 35),
                          _buildWelcomeSection(),
                          const SizedBox(height: 40),
                          _buildEmailField(),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                          const SizedBox(height: 15),
                          _buildForgotPassword(),
                          const SizedBox(height: 35),
                          _buildSignInButton(),
                          const SizedBox(height: 30),
                          _buildAnimatedDivider(),
                          const SizedBox(height: 30),
                          _buildCreateAccountButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return _logoAnimationController != null ? AnimatedBuilder(
      animation: _logoAnimationController!,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale?.value ?? 1.0,
          child: Transform.rotate(
            angle: (_logoRotation?.value ?? 0.0) * 0.1,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBrown,
                    mediumBrown,
                    Color(0xFF8B4513),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBrown.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets,
                color: lightBeige,
                size: 40,
              ),
            ),
          ),
        );
      },
    ) : Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBrown,
            mediumBrown,
            Color(0xFF8B4513),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: const Icon(
        Icons.pets,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryBrown,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to Pet Care',
          style: TextStyle(
            fontSize: 15,
            color: primaryBrown.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value,
            child: _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value,
            child: _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  key: ValueKey(_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: mediumBrown.withOpacity(0.7),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: primaryBrown,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: mediumBrown.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBrown.withOpacity(0.1),
                  mediumBrown.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryBrown,
              size: 22,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.95),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: primaryBrown.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: primaryBrown,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: mediumBrown,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBrown,
                  mediumBrown,
                  Color(0xFF8B4513),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(lightBeige),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Signing in...',
                          style: TextStyle(
                            color: lightBeige,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        color: lightBeige,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDivider() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: (800 * value).round()),
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      mediumBrown.withOpacity(0.4 * value),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: mediumBrown.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: (800 * value).round()),
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      mediumBrown.withOpacity(0.4 * value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreateAccountButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryBrown,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.8),
                  lightBeige.withOpacity(0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBrown,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Create New Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);

        final error = await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          await _waitForUserModelAndNavigate();
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _waitForUserModelAndNavigate() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    int attempts = 0;
    const maxAttempts = 10;
    const delayMs = 500;
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: delayMs));
      
      final user = authService.currentUserModel;
      if (user != null) {
        debugPrint('✅ User model loaded successfully after ${attempts + 1} attempts');
        _navigateToDashboard();
        return;
      }
      
      attempts++;
      debugPrint('⏳ Waiting for user model... attempt ${attempts + 1}/$maxAttempts');
    }
    
    debugPrint('❌ User model not loaded after $maxAttempts attempts');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Login successful but user data is taking too long to load. Please try again.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserModel;

      debugPrint('Navigating to dashboard for user: ${user?.firstName} ${user?.lastName}, role: ${user?.role}');

      if (user != null) {
        Widget dashboard;
        switch (user.role) {
          case UserRole.petOwner:
            dashboard = const PetOwnerDashboard();
            break;
          case UserRole.veterinarian:
            dashboard = const VetDashboard();
            break;
          case UserRole.shelterAdmin:
            dashboard = const ShelterDashboard();
            break;
          case UserRole.shelterOwner:
            dashboard = const ShelterOwnerDashboard();
            break;
          case UserRole.admin:
            dashboard = const AdminDashboard();
            break;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => dashboard),
          (route) => false,
        );
      } else {
        debugPrint('❌ User model is null in _navigateToDashboard - this should not happen');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unexpected error: User data not available. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to dashboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  static const Color primaryBrown = Color(0xFF4D270E);
  static const Color lightBeige = Color(0xFFF5F5DC);
  static const Color darkBrown = Color(0xFF2A1507);
  static const Color mediumBrown = Color(0xFF6B3617);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: lightBeige,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildAnimatedHeader(),
                    const SizedBox(height: 60),
                    _buildRoleSelectionTitle(),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _buildRoleCards(),
                    ),
                    const SizedBox(height: 20),
                    _buildSignInLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [lightBeige, Colors.white],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  color: primaryBrown,
                  size: 45,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [lightBeige, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  'Pet Care',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your comprehensive pet care companion',
                style: TextStyle(
                  fontSize: 16,
                  color: lightBeige.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleSelectionTitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: const Text(
            'Choose Your Role',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: lightBeige,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: [
        _buildAnimatedRoleCard(
          delay: 200,
          icon: Icons.person,
          title: 'Pet Owner',
          description: 'Manage your pets, book appointments, and track health records',
          color: const Color(0xFF2196F3),
          onTap: () => _navigateToAuth(context, UserRole.petOwner),
        ),
        const SizedBox(height: 16),
        _buildAnimatedRoleCard(
          delay: 400,
          icon: Icons.medical_services,
          title: 'Veterinarian',
          description: 'Manage appointments, medical records, and patient care',
          color: const Color(0xFF4CAF50),
          onTap: () => _navigateToAuth(context, UserRole.veterinarian),
        ),
        const SizedBox(height: 16),
        _buildAnimatedRoleCard(
          delay: 600,
          icon: Icons.home,
          title: 'Shelter Admin',
          description: 'Manage pet listings, adoption requests, and shelter operations',
          color: const Color(0xFFFF9800),
          onTap: () => _navigateToAuth(context, UserRole.shelterAdmin),
        ),
      ],
    );
  }

  Widget _buildAnimatedRoleCard({
    required int delay,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 100, 0),
          child: Opacity(
            opacity: value,
            child: _RoleCard(
              icon: icon,
              title: title,
              description: description,
              color: color,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInLink() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: lightBeige,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Already have an account? Sign In',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAuth(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationScreen(selectedRole: role),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 15.0,
      end: 25.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5DC),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value * 0.4),
                ),
                BoxShadow(
                  color: widget.color.withOpacity(0.1),
                  blurRadius: _elevationAnimation.value * 0.8,
                  offset: Offset(0, _elevationAnimation.value * 0.2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _hoverController.forward(),
                onTapUp: (_) => _hoverController.reverse(),
                onTapCancel: () => _hoverController.reverse(),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.color.withOpacity(0.2),
                                    widget.color.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: widget.color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                widget.icon,
                                size: 32,
                                color: widget.color,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4D270E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF6B3617).withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D270E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: const Color(0xFF4D270E).withOpacity(0.7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}