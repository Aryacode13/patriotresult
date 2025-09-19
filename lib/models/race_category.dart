import 'runner.dart';

enum RaceCategory {
  overall('Overall'),
  male('Male'),
  female('Female'),
  umum10k('10K UMUM'),
  pelajar10k('10K PELAJAR'),
  master10k('10K MASTER'),
  umum5k('5K UMUM'),
  pelajar5k('5K PELAJAR'),
  disabilitas5k('5K DISABILITAS');

  const RaceCategory(this.displayName);
  final String displayName;
}

class CategoryResult {
  final RaceCategory category;
  final List<Runner> runners;
  final int totalRunners;
  final int finishedRunners;

  CategoryResult({
    required this.category,
    required this.runners,
    required this.totalRunners,
    required this.finishedRunners,
  });

  List<Runner> get sortedRunners {
    final finished = runners.where((r) => r.isFinished).toList();
    final dnf = runners.where((r) => !r.isFinished).toList();
    
    finished.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
    
    return [...finished, ...dnf];
  }
}
