import 'package:flutter/material.dart';
import '../models/runner.dart';
import '../services/supabase_service.dart';
import '../widgets/results_table.dart';

class TabbedResultsScreen extends StatefulWidget {
  const TabbedResultsScreen({super.key});

  @override
  State<TabbedResultsScreen> createState() => _TabbedResultsScreenState();
}

class _TabbedResultsScreenState extends State<TabbedResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  List<Runner> overall = [];
  List<Runner> umum10k = [];
  List<Runner> pelajar10k = [];
  List<Runner> master10k = [];
  List<Runner> umum5k = [];
  List<Runner> pelajar5k = [];
  List<Runner> disabilitas5k = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);

    final results = await Future.wait<Iterable<Runner>>([
      SupabaseService.getAllRunners(),
      SupabaseService.getRunnersByCategory('10K UMUM'),
      SupabaseService.getRunnersByCategory('10K PELAJAR'),
      SupabaseService.getRunnersByCategory('10K MASTER'),
      SupabaseService.getRunnersByCategory('5K UMUM'),
      SupabaseService.getRunnersByCategory('5K PELAJAR'),
      SupabaseService.getRunnersByCategory('5K DISABILITAS'),
    ]);

    setState(() {
      overall = List<Runner>.from(results[0]);
      umum10k = List<Runner>.from(results[1]);
      pelajar10k = List<Runner>.from(results[2]);
      master10k = List<Runner>.from(results[3]);
      umum5k = List<Runner>.from(results[4]);
      pelajar5k = List<Runner>.from(results[5]);
      disabilitas5k = List<Runner>.from(results[6]);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RESULTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh, color: Colors.white))
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: '10K UMUM'),
            Tab(text: '10K PELAJAR'),
            Tab(text: '10K MASTER'),
            Tab(text: '5K UMUM'),
            Tab(text: '5K PELAJAR'),
            Tab(text: '5K DISABILITAS'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ResultsTable(title: 'Overall', runners: overall),
                ResultsTable(title: '10K UMUM', runners: umum10k),
                ResultsTable(title: '10K PELAJAR', runners: pelajar10k),
                ResultsTable(title: '10K MASTER', runners: master10k),
                ResultsTable(title: '5K UMUM', runners: umum5k),
                ResultsTable(title: '5K PELAJAR', runners: pelajar5k),
                ResultsTable(title: '5K DISABILITAS', runners: disabilitas5k),
              ],
            ),
    );
  }
}
