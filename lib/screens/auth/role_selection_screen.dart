import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // App Logo and Title
                Icon(
                  Icons.pets,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pet Care',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your comprehensive pet care companion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Role Selection Title
                Text(
                  'Choose Your Role',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Role Cards
                Column(
                  children: [
                    _RoleCard(
                      icon: Icons.person,
                      title: 'Pet Owner',
                      description: 'Manage your pets, book appointments, and track health records',
                      color: Colors.blue,
                      onTap: () => _navigateToAuth(context, UserRole.petOwner),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.medical_services,
                      title: 'Veterinarian',
                      description: 'Manage appointments, medical records, and patient care',
                      color: Colors.green,
                      onTap: () => _navigateToAuth(context, UserRole.veterinarian),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.home,
                      title: 'Shelter Admin',
                      description: 'Manage pet listings, adoption requests, and shelter operations',
                      color: Colors.orange,
                      onTap: () => _navigateToAuth(context, UserRole.shelterAdmin),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.pets,
                      title: 'Shelter Owner',
                      description: 'Manage pet listings, adoption requests, success stories, and volunteer forms',
                      color: Colors.teal,
                      onTap: () => _navigateToAuth(context, UserRole.shelterOwner),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin',
                      description: 'Manage contacts, feedback, and system administration',
                      color: Colors.purple,
                      onTap: () => _navigateToAuth(context, UserRole.admin),
                    ),
                  ],
                ),
                
                // Already have account
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
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
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}