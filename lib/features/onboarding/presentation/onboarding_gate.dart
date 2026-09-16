import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';
import 'package:the_registry/features/onboarding/presentation/onboarding_screen.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.repository});

  final OnboardingRepository repository;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final Future<bool> _completed = widget.repository.isCompleted();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _completed,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return const AppShell();
        }

        return OnboardingScreen(repository: widget.repository);
      },
    );
  }
}
