import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/pet_care_theme.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
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
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildRoleSelectionTitle(),
                        const SizedBox(height: 32),
                        _buildRoleCards(),
                        const SizedBox(height: 32),
                        _buildSignInLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: PetCareTheme.primaryGradient,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              PetCareTheme.elevatedShadow,
              BoxShadow(
                color: PetCareTheme.primaryBeige.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(-10, -10),
              ),
            ],
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: PetCareTheme.primaryBeige,
            size: 56,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Pet Care',
          style: PetCareTheme.headingLarge.copyWith(
            fontSize: 36,
            color: PetCareTheme.primaryBrown,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your comprehensive pet care companion',
          style: PetCareTheme.bodyLarge.copyWith(
            color: PetCareTheme.lightBrown,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleSelectionTitle() {
    return Text(
      'Choose Your Role',
      style: PetCareTheme.headingMedium.copyWith(
        color: PetCareTheme.primaryBrown,
      ),
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: [
        _RoleCard(
          icon: Icons.person_rounded,
          title: 'Pet Owner',
          description: 'Manage your pets, book appointments, and track health records',
          color: PetCareTheme.softGreen,
          onTap: () => _navigateToAuth(context, UserRole.petOwner),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.medical_services_rounded,
          title: 'Veterinarian',
          description: 'Manage appointments, medical records, and patient care',
          color: PetCareTheme.accentGold,
          onTap: () => _navigateToAuth(context, UserRole.veterinarian),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.home_rounded,
          title: 'Shelter Admin',
          description: 'Manage pet listings, adoption requests, and shelter operations',
          color: PetCareTheme.warmRed,
          onTap: () => _navigateToAuth(context, UserRole.shelterAdmin),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.pets_rounded,
          title: 'Shelter Owner',
          description: 'Manage listings, adoptions, success stories, and volunteer forms',
          color: PetCareTheme.warmPurple,
          onTap: () => _navigateToAuth(context, UserRole.shelterOwner),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Admin',
          description: 'Manage contacts, feedback, and system administration',
          color: PetCareTheme.primaryBrown,
          onTap: () => _navigateToAuth(context, UserRole.admin),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity(0.7),
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
        border: Border.all(
          color: PetCareTheme.primaryBrown.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.primaryBrown.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: PetCareTheme.primaryBrown,
          overlayColor: PetCareTheme.primaryBrown.withOpacity(0.1),
        ),
        child: Text(
          'Already have an account? Sign In',
          style: PetCareTheme.bodyLarge.copyWith(
            color: PetCareTheme.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

class _RoleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusXLarge),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          PetCareTheme.cardShadow,
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusXLarge),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusXLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.02),
                  Colors.transparent,
                  color.withOpacity(0.01),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: PetCareTheme.primaryBeige,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PetCareTheme.headingSmall.copyWith(
                          color: PetCareTheme.primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: PetCareTheme.bodyMedium.copyWith(
                          color: PetCareTheme.lightBrown,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PetCareTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PetCareTheme.borderRadiusMedium),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: PetCareTheme.primaryBrown,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
