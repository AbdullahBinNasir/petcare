import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/pet_care_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;
  
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.sendPasswordResetEmail(_emailController.text.trim());

    if (result == null) {
      setState(() {
        _isEmailSent = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildModernAppBar(),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: PetCareTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusXXLarge),
                                  boxShadow: [
                                    PetCareTheme.elevatedShadow,
                                    BoxShadow(
                                      color: PetCareTheme.primaryBrown.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: 32),
                                    _buildDescription(),
                                    const SizedBox(height: 40),
                                    _isEmailSent ? _buildSuccessState() : _buildEmailForm(),
                                    const SizedBox(height: 32),
                                    _buildBackToLoginButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: PetCareTheme.primaryBeige.withOpacity(0.9),
              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusMedium),
              boxShadow: [PetCareTheme.cardShadow],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: PetCareTheme.primaryBrown,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Reset Password',
            style: PetCareTheme.headingMedium.copyWith(
              color: PetCareTheme.primaryBrown,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PetCareTheme.accentGold.withOpacity(0.8),
                PetCareTheme.warmRed.withOpacity(0.6),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PetCareTheme.accentGold.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            _isEmailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
            size: 48,
            color: PetCareTheme.primaryBeige,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isEmailSent ? 'Check Your Email' : 'Forgot Password?',
          style: PetCareTheme.headingLarge.copyWith(
            color: PetCareTheme.primaryBrown,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      _isEmailSent
          ? 'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.'
          : 'Enter your email address and we\'ll send you a link to reset your password.',
      style: PetCareTheme.bodyLarge.copyWith(
        color: PetCareTheme.lightBrown,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.primaryBrown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: PetCareTheme.bodyLarge.copyWith(
          color: PetCareTheme.primaryBrown,
        ),
        decoration: InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your email address',
          labelStyle: PetCareTheme.bodyMedium.copyWith(
            color: PetCareTheme.lightBrown,
          ),
          hintStyle: PetCareTheme.bodyMedium.copyWith(
            color: PetCareTheme.lightBrown.withOpacity(0.6),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PetCareTheme.accentGold.withOpacity(0.15),
                  PetCareTheme.accentGold.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusMedium),
            ),
            child: Icon(
              Icons.email_outlined,
              color: PetCareTheme.accentGold,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: PetCareTheme.primaryBeige.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            borderSide: BorderSide(
              color: PetCareTheme.primaryBrown.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            borderSide: const BorderSide(
              color: PetCareTheme.accentGold,
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            borderSide: const BorderSide(
              color: PetCareTheme.warmRed,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            borderSide: const BorderSide(
              color: PetCareTheme.warmRed,
              width: 2.0,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email address';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PetCareTheme.accentGold,
            PetCareTheme.accentGold.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.accentGold.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return ElevatedButton(
            onPressed: authService.isLoading ? null : _sendPasswordResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
              ),
            ),
            child: authService.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(PetCareTheme.primaryBeige),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Sending...',
                        style: PetCareTheme.bodyLarge.copyWith(
                          color: PetCareTheme.primaryBeige,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Send Reset Link',
                    style: PetCareTheme.bodyLarge.copyWith(
                      color: PetCareTheme.primaryBeige,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PetCareTheme.softGreen.withOpacity(0.1),
                PetCareTheme.softGreen.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
            border: Border.all(
              color: PetCareTheme.softGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PetCareTheme.softGreen.withOpacity(0.8),
                      PetCareTheme.softGreen,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: PetCareTheme.softGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: PetCareTheme.primaryBeige,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Email Sent Successfully!',
                style: PetCareTheme.headingSmall.copyWith(
                  color: PetCareTheme.softGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your email and follow the instructions to reset your password.',
                style: PetCareTheme.bodyMedium.copyWith(
                  color: PetCareTheme.lightBrown,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() {
              _isEmailSent = false;
              _emailController.clear();
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: PetCareTheme.accentGold,
            overlayColor: PetCareTheme.accentGold.withOpacity(0.1),
          ),
          child: Text(
            'Send to a different email address',
            style: PetCareTheme.bodyMedium.copyWith(
              color: PetCareTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity(0.7),
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: PetCareTheme.primaryBrown,
          overlayColor: PetCareTheme.primaryBrown.withOpacity(0.1),
        ),
        child: Text(
          'Back to Login',
          style: PetCareTheme.bodyLarge.copyWith(
            color: PetCareTheme.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
