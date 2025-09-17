import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthDebugHelper {
  static void printAuthState(AuthService authService) {
    print('🔐 AUTH DEBUG INFO:');
    print('  - Current User: ${authService.currentUser?.uid ?? "null"}');
    print('  - User Model: ${authService.currentUserModel?.firstName ?? "null"} ${authService.currentUserModel?.lastName ?? ""}');
    print('  - Is Loading: ${authService.isLoading}');
    print('  - Is Fully Authenticated: ${authService.isFullyAuthenticated}');
    print('  - Is Partially Authenticated: ${authService.isPartiallyAuthenticated}');
    print('  - User Role: ${authService.currentUserModel?.role ?? "null"}');
  }

  static void showAuthDebugDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Debug Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current User: ${authService.currentUser?.uid ?? "null"}'),
            Text('User Model: ${authService.currentUserModel?.firstName ?? "null"} ${authService.currentUserModel?.lastName ?? ""}'),
            Text('Is Loading: ${authService.isLoading}'),
            Text('Is Fully Authenticated: ${authService.isFullyAuthenticated}'),
            Text('Is Partially Authenticated: ${authService.isPartiallyAuthenticated}'),
            Text('User Role: ${authService.currentUserModel?.role ?? "null"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              authService.refreshAuthState();
              Navigator.pop(context);
            },
            child: const Text('Refresh Auth State'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
