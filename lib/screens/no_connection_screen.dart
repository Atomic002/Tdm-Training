// lib/screens/no_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/app_colors.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Internetga ulanmagansiz!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Iltimos, internetga ulanib qayta urinib ko‘ring.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
