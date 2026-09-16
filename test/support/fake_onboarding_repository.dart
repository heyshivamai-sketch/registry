import 'package:the_registry/features/onboarding/data/onboarding_repository.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.completed = false});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> complete() async {
    completed = true;
  }

  @override
  Future<void> reset() async {
    completed = false;
  }
}
