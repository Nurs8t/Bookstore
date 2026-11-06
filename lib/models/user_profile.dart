import 'package:flutter/material.dart';

enum UserRole {
  student('Студент', Icons.school),
  teacher('Оқытушы', Icons.cast_for_education),
  developer('Әзірлеуші', Icons.code);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;
}

class UserProfile {
  final String fullName;
  final String email;
  final UserRole role;
  final bool subscribed;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.role,
    required this.subscribed,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  String toString() =>
      'UserProfile(fullName: $fullName, email: $email, role: ${role.label}, subscribed: $subscribed)';
}
