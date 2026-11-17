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

  /// Профиль → JSON (shared_preferences-ке жазу үшін). Рөл атауымен сақталады.
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'role': role.name,
        'subscribed': subscribed,
      };

  /// JSON → Профиль. Белгісіз рөл келсе — Студент.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.student,
        ),
        subscribed: json['subscribed'] as bool? ?? false,
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  String toString() =>
      'UserProfile(fullName: $fullName, email: $email, role: ${role.label}, subscribed: $subscribed)';
}
