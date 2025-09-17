import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/pet_care_theme.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final UserRole selectedRole;

  const RegistrationScreen({super.key, required this.selectedRole});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _shelterNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _clinicNameController.dispose();
    _licenseNumberController.dispose();
    _shelterNameController.dispose();
    _addressController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 480),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: PetCareTheme.cardWhite,
                              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusXXLarge),
                              boxShadow: [
                                PetCareTheme.elevatedShadow,
                                BoxShadow(
                                  color: roleColor.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildRoleIndicator(),
                                  const SizedBox(height: 32),
                                  _buildFormFields(),
                                  const SizedBox(height: 32),
                                  _buildRegisterButton(),
                                  const SizedBox(height: 20),
                                  _buildLoginLink(),
                                ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor().withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
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
            'Register as ${_getRoleTitle()}',
            style: PetCareTheme.headingMedium.copyWith(
              color: PetCareTheme.primaryBrown,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleIndicator() {
    final roleColor = _getRoleColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withOpacity(0.1),
            roleColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        border: Border.all(
          color: roleColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withOpacity(0.2),
                  roleColor.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusMedium),
            ),
            child: Icon(
              _getRoleIcon(),
              color: PetCareTheme.primaryBeige,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creating Account',
                  style: PetCareTheme.bodySmall.copyWith(
                    color: PetCareTheme.lightBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getRoleTitle()} Registration',
                  style: PetCareTheme.bodyLarge.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleTitle() {
    switch (widget.selectedRole) {
      case UserRole.petOwner:
        return 'Pet Owner';
      case UserRole.veterinarian:
        return 'Veterinarian';
      case UserRole.shelterAdmin:
        return 'Shelter Admin';
      case UserRole.shelterOwner:
        return 'Shelter Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  IconData _getRoleIcon() {
    switch (widget.selectedRole) {
      case UserRole.petOwner:
        return Icons.person;
      case UserRole.veterinarian:
        return Icons.medical_services;
      case UserRole.shelterAdmin:
        return Icons.home;
      case UserRole.shelterOwner:
        return Icons.pets;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _getRoleColor() {
    switch (widget.selectedRole) {
      case UserRole.petOwner:
        return PetCareTheme.softGreen;
      case UserRole.veterinarian:
        return PetCareTheme.accentGold;
      case UserRole.shelterAdmin:
        return PetCareTheme.warmRed;
      case UserRole.shelterOwner:
        return PetCareTheme.warmPurple;
      case UserRole.admin:
        return PetCareTheme.primaryBrown;
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name fields
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Email field
        _buildInputField(
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
        const SizedBox(height: 20),
        
        // Phone field
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number (Optional)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        
        // Password field
        _buildInputField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: PetCareTheme.lightBrown,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Confirm password field
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: PetCareTheme.lightBrown,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        
        // Role-specific fields
        if (widget.selectedRole == UserRole.veterinarian) ..._buildVeterinarianFields(),
        if (widget.selectedRole == UserRole.shelterAdmin) ..._buildShelterAdminFields(),
      ],
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
    int maxLines = 1,
  }) {
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        style: PetCareTheme.bodyLarge.copyWith(
          color: PetCareTheme.primaryBrown,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: PetCareTheme.bodyMedium.copyWith(
            color: PetCareTheme.lightBrown,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRoleColor().withOpacity(0.15),
                  _getRoleColor().withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusMedium),
            ),
            child: Icon(
              icon,
              color: _getRoleColor(),
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
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
            borderSide: BorderSide(
              color: _getRoleColor(),
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
        validator: validator,
      ),
    );
  }

  List<Widget> _buildVeterinarianFields() {
    return [
      const SizedBox(height: 20),
      _buildInputField(
        controller: _clinicNameController,
        label: 'Clinic Name',
        icon: Icons.local_hospital_outlined,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your clinic name';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      _buildInputField(
        controller: _licenseNumberController,
        label: 'License Number',
        icon: Icons.badge_outlined,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your license number';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      _buildInputField(
        controller: _addressController,
        label: 'Clinic Address',
        icon: Icons.location_on_outlined,
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildShelterAdminFields() {
    return [
      const SizedBox(height: 20),
      _buildInputField(
        controller: _shelterNameController,
        label: 'Shelter Name',
        icon: Icons.home_outlined,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your shelter name';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      _buildInputField(
        controller: _addressController,
        label: 'Shelter Address',
        icon: Icons.location_on_outlined,
        maxLines: 2,
      ),
    ];
  }

  Widget _buildRegisterButton() {
    final roleColor = _getRoleColor();
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor,
            roleColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: PetCareTheme.primaryBeige.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return ElevatedButton(
            onPressed: authService.isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
              ),
              splashFactory: InkRipple.splashFactory,
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
                        'Creating Account...',
                        style: PetCareTheme.bodyLarge.copyWith(
                          color: PetCareTheme.primaryBeige,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Create Account',
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: PetCareTheme.bodyMedium.copyWith(
            color: PetCareTheme.lightBrown,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: _getRoleColor(),
            overlayColor: _getRoleColor().withOpacity(0.1),
          ),
          child: Text(
            'Sign In',
            style: PetCareTheme.bodyMedium.copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      final error = await authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: widget.selectedRole,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        clinicName: _clinicNameController.text.trim().isEmpty ? null : _clinicNameController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim().isEmpty ? null : _licenseNumberController.text.trim(),
        shelterName: _shelterNameController.text.trim().isEmpty ? null : _shelterNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Registration successful, navigate to appropriate dashboard
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
