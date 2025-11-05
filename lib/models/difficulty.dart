enum Difficulty {
  easy,
  medium,
  hard,
  expert,
}

extension DifficultyExtension on Difficulty {
  String get name {
    switch (this) {
      case Difficulty.easy:
        return 'OSON';
      case Difficulty.medium:
        return 'O\'RTA';
      case Difficulty.hard:
        return 'QIYIN';
      case Difficulty.expert:
        return 'EKSPERT';
    }
  }

  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Yangi boshlovchilar uchun';
      case Difficulty.medium:
        return 'O\'rta daraja o\'yinchilar uchun';
      case Difficulty.hard:
        return 'Tajribali o\'yinchilar uchun';
      case Difficulty.expert:
        return 'Professional o\'yinchilar uchun';
    }
  }

  // Target timeout in seconds
  int get targetTimeout {
    switch (this) {
      case Difficulty.easy:
        return 3;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 1;
      case Difficulty.expert:
        return 1;
    }
  }

  // Spawn delay in milliseconds
  int get spawnDelay {
    switch (this) {
      case Difficulty.easy:
        return 1500;
      case Difficulty.medium:
        return 1000;
      case Difficulty.hard:
        return 700;
      case Difficulty.expert:
        return 500;
    }
  }

  // Target size
  double get targetSize {
    switch (this) {
      case Difficulty.easy:
        return 80.0;
      case Difficulty.medium:
        return 65.0;
      case Difficulty.hard:
        return 50.0;
      case Difficulty.expert:
        return 40.0;
    }
  }

  // Moving targets
  bool get hasMovingTargets {
    switch (this) {
      case Difficulty.easy:
        return false;
      case Difficulty.medium:
        return false;
      case Difficulty.hard:
        return true;
      case Difficulty.expert:
        return true;
    }
  }

  // Multiple targets
  bool get hasMultipleTargets {
    switch (this) {
      case Difficulty.easy:
        return false;
      case Difficulty.medium:
        return false;
      case Difficulty.hard:
        return false;
      case Difficulty.expert:
        return true;
    }
  }

  // Score multiplier
  double get scoreMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
      case Difficulty.expert:
        return 3.0;
    }
  }
}
