import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';

/// Маршруттарды қорғау: авторизацияланбаған пайдаланушыларды
/// автоматты түрде AuthScreen экранына бағыттайды (Task 16).
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? protectedScreenName;

  const AuthGuard({
    super.key,
    required this.child,
    this.protectedScreenName,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Егер пайдаланушы авторизациядан өтпеген болса — AuthScreen көрсетіледі
    if (!auth.isAuthenticated) {
      return const AuthScreen(initialIsLogin: true);
    }

    return child;
  }
}

