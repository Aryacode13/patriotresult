import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:intl/intl.dart';


class Runner {
  final int id;
  final DateTime createdAt;
  final String bib;
  final String name;
  final String gender;
  final String category;
  final String bloodType;
  final String cp0;
  final String cp1;
  final String cp2;
  final String cp3;
  final String cp4;
  final String cp5;
  final String cp6;
  final String cp7;
  final String cp8;
  final String cp9;
  final bool isActive;
  final bool isDnf;
  final bool isDns;
  final String tag;
  int genderRank = 0;

  Runner({
    required this.id,
    required this.createdAt,
    required this.bib,
    required this.name,
    required this.gender,
    required this.category,
    required this.bloodType,
    required this.cp0,
    required this.cp1,
    required this.cp2,
    required this.cp3,
    required this.cp4,
    required this.cp5,
    required this.cp6,
    required this.cp7,
    required this.cp8,
    required this.cp9,
    required this.isActive,
    required this.isDnf,
    required this.isDns,
    required this.tag,
  });

  factory Runner.fromJson(Map<String, dynamic> json) {
    return Runner(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      bib: json['bib'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'male',
      category: json['category'] ?? 'umum',
      bloodType: json['blood_type'] ?? '',
      cp0: json['cp0'] ?? '',
      cp1: json['cp1'] ?? '',
      cp2: json['cp2'] ?? '',
      cp3: json['cp3'] ?? '',
      cp4: json['cp4'] ?? '',
      cp5: json['cp5'] ?? '',
      cp6: json['cp6'] ?? '',
      cp7: json['cp7'] ?? '',
      cp8: json['cp8'] ?? '',
      cp9: json['cp9'] ?? '',
      isActive: json['is_active'] ?? true,
      isDnf: json['is_dnf'] ?? false,
      isDns: json['is_dns'] ?? false,
      tag: json['tag'] ?? '',
    );
  }

  String get formattedTime {
    if (isDnf || isDns) {
      return isDns ? 'DNS' : 'DNF';
    }
    
    if (cp9.isEmpty) return 'DNF';
    
    try {
      final startTime = _parseTime(cp0);
      final finishTime = _parseTime(cp9);
      
      if (startTime == null || finishTime == null) return 'DNF';
      
      final duration = finishTime.difference(startTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'DNF';
    }
  }

  Duration? get totalTime {
    if (isDnf || isDns || cp9.isEmpty) return null;
    
    try {
      final startTime = _parseTime(cp0);
      final finishTime = _parseTime(cp9);
      
      if (startTime == null || finishTime == null) return null;
      
      return finishTime.difference(startTime);
    } catch (e) {
      return null;
    }
  }

  bool get hasValidTime => totalTime != null;

  static final DateFormat _cpFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  DateTime? _parseTime(String timeString) {
    if (timeString.isEmpty) return null;

    try {
      // Primary: strict parse for "yyyy-MM-dd HH:mm:ss"
      // (local time by default)
      return _cpFormat.parseStrict(timeString);
    } catch (_) {
      // Fallback 1: ISO or other DateTime.parse-compatible strings
      try {
        if (timeString.contains('T') || timeString.contains(' ')) {
          return DateTime.parse(timeString);
        }
      } catch (_) {}

      // Fallback 2: "HH:mm[:ss]" same-day times
      try {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final second = parts.length > 2 ? int.parse(parts[2]) : 0;
          return DateTime(now.year, now.month, now.day, hour, minute, second);
        }
      } catch (_) {}

      return null;
    }
  }


  bool get isFinished => !isDnf && !isDns && cp9.isNotEmpty && totalTime != null;

}

class ConsolidatedResultsScreen extends StatefulWidget {
  const ConsolidatedResultsScreen({super.key});

  @override
  State<ConsolidatedResultsScreen> createState() => _ConsolidatedResultsScreenState();
}

class _ConsolidatedResultsScreenState extends State<ConsolidatedResultsScreen> with SingleTickerProviderStateMixin {
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

    try {
      final client = Supabase.instance.client;
      
      final results = await Future.wait<Iterable<Runner>>([
        _getAllRunners(client),
        _getRunnersByCategory(client, '10K UMUM'),
        _getRunnersByCategory(client, '10K PELAJAR'),
        _getRunnersByCategory(client, '10K MASTER'),
        _getRunnersByCategory(client, '5K UMUM'),
        _getRunnersByCategory(client, '5K PELAJAR'),
        _getRunnersByCategory(client, '5K DISABILITAS'),
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
      
      print('=== DATA LOADED ===');
      print('Overall: ${overall.length}');
      print('10K UMUM: ${umum10k.length}');
      print('10K PELAJAR: ${pelajar10k.length}');
      print('10K MASTER: ${master10k.length}');
      print('5K UMUM: ${umum5k.length}');
      print('5K PELAJAR: ${pelajar5k.length}');
      print('5K DISABILITAS: ${disabilitas5k.length}');
      print('==================');
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading results: $e')),
        );
      }
    }
  }

  Future<List<Runner>> _getAllRunners(SupabaseClient client) async {
    try {
      List<Runner> allRunners = [];
      int offset = 0;
      const int limit = 1000;
      
      while (true) {
        final response = await client
            .from(SupabaseConfig.runnersTable)
            .select()
            .order('id', ascending: true)
            .range(offset, offset + limit - 1);
        
        if (response.isEmpty) break;
        
        final batch = response.map((json) => Runner.fromJson(json)).toList();
        allRunners.addAll(batch);
        
        print('Loaded batch: ${batch.length} records (offset: $offset)');
        
        if (batch.length < limit) break;
        offset += limit;
      }
      
      print('Total runners loaded: ${allRunners.length}');
      return allRunners;
    } catch (e) {
      print('Error fetching all runners: $e');
      return [];
    }
  }

  Future<List<Runner>> _getRunnersByCategory(SupabaseClient client, String category) async {
    try {
      final response = await client
          .from(SupabaseConfig.runnersTable)
          .select()
          .eq('category', category)
          .order('cp9', ascending: true);
      
      final runners = response.map((json) => Runner.fromJson(json)).toList();
      print('$category runners loaded: ${runners.length}');
      return runners;
    } catch (e) {
      print('Error fetching runners by category: $e');
      return [];
    }
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
                _buildResultsTable('Overall', overall),
                _buildResultsTable('10K UMUM', umum10k),
                _buildResultsTable('10K PELAJAR', pelajar10k),
                _buildResultsTable('10K MASTER', master10k),
                _buildResultsTable('5K UMUM', umum5k),
                _buildResultsTable('5K PELAJAR', pelajar5k),
                _buildResultsTable('5K DISABILITAS', disabilitas5k),
              ],
            ),
    );
  }

  Widget _buildResultsTable(String title, List<Runner> runners) {
    return _ResultsTableWidget(title: title, runners: runners);
  }
}

class _ResultsTableWidget extends StatefulWidget {
  final String title;
  final List<Runner> runners;

  const _ResultsTableWidget({required this.title, required this.runners});

  @override
  State<_ResultsTableWidget> createState() => _ResultsTableWidgetState();
}

class _ResultsTableWidgetState extends State<_ResultsTableWidget> {
  late List<Runner> allRunners;
  late List<Runner> filteredRunners;
  String searchQuery = '';
  String? sortColumn;
  bool sortAscending = true;
  
  // Pagination - 100 rows per page
  int currentPage = 0;
  final int itemsPerPage = 100;

  @override
  void initState() {
    super.initState();
    allRunners = List<Runner>.from(widget.runners);
    _calculateGenderRanks(allRunners);
    filteredRunners = List<Runner>.from(allRunners);
  }

  // Strict parser for "yyyy-MM-dd HH:mm:ss"
  static final DateFormat _cpFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  DateTime? _parseCpTime(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      return _cpFormat.parseStrict(timeString); // local time
    } catch (_) {
      try {
        if (timeString.contains('T') || timeString.contains(' ')) {
          return DateTime.parse(timeString);
        }
      } catch (_) {}
      try {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final s = parts.length > 2 ? int.parse(parts[2]) : 0;
          return DateTime(now.year, now.month, now.day, h, m, s);
        }
      } catch (_) {}
      return null;
    }
  }

  String _formatSplit(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }


  @override
  void didUpdateWidget(covariant _ResultsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runners != widget.runners) {
      allRunners = List<Runner>.from(widget.runners);
      _calculateGenderRanks(allRunners);
      _applySearch();
    }
  }

  void _calculateGenderRanks(List<Runner> runners) {
    final male = runners.where((r) => r.gender == 'male' && r.isFinished).toList();
    final female = runners.where((r) => r.gender == 'female' && r.isFinished).toList();

    male.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
    female.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));

    for (int i = 0; i < male.length; i++) {
      male[i].genderRank = i + 1;
    }
    for (int i = 0; i < female.length; i++) {
      female[i].genderRank = i + 1;
    }
  }

  void _applySearch() {
    if (searchQuery.isEmpty) {
      filteredRunners = List<Runner>.from(allRunners);
    } else {
      filteredRunners = allRunners.where((runner) {
        return runner.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            runner.bib.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    currentPage = 0;
    setState(() {});
  }

  void _sort(String columnName) {
    setState(() {
      if (sortColumn == columnName) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = columnName;
        sortAscending = true;
      }
      currentPage = 0;

      switch (columnName) {
        case 'rank':
        case 'time':
          filteredRunners.sort((a, b) {
            if (a.isFinished && b.isFinished) {
              return sortAscending
                  ? a.totalTime!.compareTo(b.totalTime!)
                  : b.totalTime!.compareTo(a.totalTime!);
            } else if (a.isFinished && !b.isFinished) {
              return sortAscending ? -1 : 1;
            } else if (!a.isFinished && b.isFinished) {
              return sortAscending ? 1 : -1;
            }
            return 0;
          });
          break;
        case 'name':
          filteredRunners.sort((a, b) => sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'bib':
          filteredRunners.sort((a, b) => sortAscending
              ? a.bib.compareTo(b.bib)
              : b.bib.compareTo(a.bib));
          break;
        case 'gender':
          filteredRunners.sort((a, b) => sortAscending
              ? a.gender.compareTo(b.gender)
              : b.gender.compareTo(a.gender));
          break;
        case 'genderrank':
          filteredRunners.sort((a, b) => sortAscending
              ? a.genderRank.compareTo(b.genderRank)
              : b.genderRank.compareTo(a.genderRank));
          break;
      }
    });
  }

  List<Runner> get _paginatedRunners {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredRunners.length);
    return filteredRunners.sublist(startIndex, endIndex);
  }

  int get _totalPages => (filteredRunners.length / itemsPerPage).ceil();

  void _nextPage() {
    if (currentPage < _totalPages - 1) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  Widget _buildSortIcon(String columnName) {
    if (sortColumn != columnName) {
      return Icon(Icons.unfold_more, size: 16, color: Colors.grey.shade400);
    }
    return Icon(
      sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      size: 16,
      color: Colors.blue.shade800,
    );
  }

  int _categoryMaxCpForRunner(Runner runner) {
    final category = (runner.category).toUpperCase();
    if (category.contains('5K')) return 4;
    if (category.contains('10K')) return 8;
    final title = widget.title.toUpperCase();
    if (title.contains('5K')) return 4;
    if (title.contains('10K')) return 8;
    return 8;
  }

  String _cpValueByIndex(Runner r, int index) {
    switch (index) {
      case 1: return r.cp1;
      case 2: return r.cp2;
      case 3: return r.cp3;
      case 4: return r.cp4;
      case 5: return r.cp5;
      case 6: return r.cp6;
      case 7: return r.cp7;
      case 8: return r.cp8;
      default: return '';
    }
  }

  int _lastReachedCp(Runner r, int maxCp) {
    for (int i = maxCp; i >= 1; i--) {
      if (_cpValueByIndex(r, i).isNotEmpty) {
        return i;
      }
    }
    return 0;
  }

  void _showCheckpointPopup(BuildContext context, Runner runner, int maxCp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Checkpoint Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          content: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${runner.name} (Bib: ${runner.bib})',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 16),
      // CP splits (skip CP0)
      ...List.generate(maxCp, (index) {
        final cpIndex = index + 1; // CP1 … CPmax
        final cpTime = _cpValueByIndex(runner, cpIndex);
        final baseTime = runner.cp0;
        Duration? split;
        if (cpTime.isNotEmpty && baseTime.isNotEmpty) {
          final start = _parseCpTime(baseTime);
          final now = _parseCpTime(cpTime);
          if (start != null && now != null) {
            split = now.difference(start);
          }
        }

        final isReached = split != null;
        final label = 'CP$cpIndex';

        String formatSplit(Duration d) {
          final h = d.inHours;
          final m = d.inMinutes.remainder(60);
          final s = d.inSeconds.remainder(60);
          return h > 0
              ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
              : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isReached ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isReached ? Colors.green.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isReached ? Colors.green.shade800 : Colors.grey.shade600,
                ),
              ),
              Text(
                isReached ? formatSplit(split!) : 'Not reached',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: isReached ? Colors.green.shade700 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
      // Finish split (cp9)
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: runner.cp9.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: runner.cp9.isNotEmpty ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Finish',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: runner.cp9.isNotEmpty ? Colors.blue.shade800 : Colors.grey.shade600,
              ),
            ),
            Text(
              () {
                if (runner.cp9.isEmpty || runner.cp0.isEmpty) return 'Not reached';
                final start = _parseCpTime(runner.cp0);
                final end = _parseCpTime(runner.cp9);
                if (start == null || end == null) return 'Not reached';
                final split = end.difference(start);
                return _formatSplit(split);
              }(),
              style: TextStyle(
                fontFamily: 'monospace',
                color: runner.cp9.isNotEmpty ? Colors.blue.shade700 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            onChanged: (value) {
              searchQuery = value;
              _applySearch();
            },
            decoration: InputDecoration(
              hintText: 'Search by Bib or Name',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade800),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),
        
        // Results Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Mobile responsive: use different column configurations
                final isMobile = constraints.maxWidth < 768;
                
                if (isMobile) {
                  return _buildMobileTable();
                } else {
                  return _buildDesktopTable();
                }
              },
            ),
          ),
        ),
        
        // Pagination Controls
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(currentPage * itemsPerPage) + 1}-${((currentPage + 1) * itemsPerPage).clamp(0, filteredRunners.length)} of ${filteredRunners.length} results',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentPage > 0 ? _previousPage : null,
                        icon: const Icon(Icons.chevron_left),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${currentPage + 1} / $_totalPages',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: currentPage < _totalPages - 1 ? _nextPage : null,
                        icon: const Icon(Icons.chevron_right),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 900,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
      columns: [
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('rank'),
            ],
          ),
          onSort: (i, a) => _sort('rank'),
        ),
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('name'),
            ],
          ),
          onSort: (i, a) => _sort('name'),
        ),
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bib', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('bib'),
            ],
          ),
          onSort: (i, a) => _sort('bib'),
        ),
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('gender'),
            ],
          ),
          onSort: (i, a) => _sort('gender'),
        ),
        const DataColumn2(
          label: Text('Check Point', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('time'),
            ],
          ),
          onSort: (i, a) => _sort('time'),
        ),
        DataColumn2(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gender Rank', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildSortIcon('genderrank'),
            ],
          ),
          onSort: (i, a) => _sort('genderrank'),
        ),
      ],
      rows: _paginatedRunners.asMap().entries.map((entry) {
        final index = entry.key;
        final runner = entry.value;

        int overallRank = 0;
        final copy = filteredRunners.where((r) => r.isFinished).toList();
        copy.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
        if (runner.isFinished) {
          overallRank = copy.indexOf(runner) + 1;
        }

        return DataRow2(
          color: MaterialStateProperty.all(index % 2 == 0 ? Colors.white : Colors.grey.shade50),
          cells: [
            DataCell(Text(overallRank > 0 ? overallRank.toString() : '-', style: TextStyle(fontWeight: FontWeight.bold, color: overallRank == 1 ? Colors.amber.shade700 : Colors.black87))),
            DataCell(Text(runner.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)), child: Text(runner.bib, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [Icon(runner.gender == 'male' ? Icons.male : Icons.female, size: 16, color: runner.gender == 'male' ? Colors.blue : Colors.pink), const SizedBox(width: 4), Text(runner.gender.toUpperCase())])),
            DataCell(() {
              final maxCp = _categoryMaxCpForRunner(runner);
              final lastCp = _lastReachedCp(runner, maxCp);
              final lastCpTime = lastCp > 0 ? _cpValueByIndex(runner, lastCp) : '';
              final label = lastCp > 0 ? 'CP$lastCp' : 'START';
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showCheckpointPopup(context, runner, maxCp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: Colors.blue.shade800,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lastCpTime.isNotEmpty ? lastCpTime : '-',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (runner.cp9.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(width: 1, height: 16, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'FINISH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      runner.cp9,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            }()),
            DataCell(Text(runner.formattedTime, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: runner.isFinished ? Colors.green.shade700 : (runner.isDns ? Colors.orange.shade700 : Colors.red.shade700)))) ,
            DataCell(Text(runner.genderRank > 0 ? runner.genderRank.toString() : '-', style: TextStyle(fontWeight: FontWeight.bold, color: runner.genderRank == 1 ? Colors.amber.shade700 : Colors.black87))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileTable() {
    return ListView.builder(
      itemCount: _paginatedRunners.length,
      itemBuilder: (context, index) {
        final runner = _paginatedRunners[index];
        
        int overallRank = 0;
        final copy = filteredRunners.where((r) => r.isFinished).toList();
        copy.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
        if (runner.isFinished) {
          overallRank = copy.indexOf(runner) + 1;
        }

        final maxCp = _categoryMaxCpForRunner(runner);
        final lastCp = _lastReachedCp(runner, maxCp);
        final lastCpTime = lastCp > 0 ? _cpValueByIndex(runner, lastCp) : '';
        final label = lastCp > 0 ? 'CP$lastCp' : 'START';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name and Bib Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        runner.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        runner.bib,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Gender and Rank Row
                Row(
                  children: [
                    Icon(
                      runner.gender == 'male' ? Icons.male : Icons.female,
                      size: 16,
                      color: runner.gender == 'male' ? Colors.blue : Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    Text(runner.gender.toUpperCase()),
                    const Spacer(),
                    Text(
                      'Rank: ${overallRank > 0 ? overallRank.toString() : '-'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: overallRank == 1 ? Colors.amber.shade700 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Checkpoint Row
                Wrap(
                  children: [
                    GestureDetector(
                      onTap: () => _showCheckpointPopup(context, runner, maxCp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 12,
                              color: Colors.blue.shade800,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastCpTime.isNotEmpty ? lastCpTime : '-',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    if (runner.cp9.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'FINISH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        runner.cp9,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Time and Gender Rank Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Time: ${runner.formattedTime}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: runner.isFinished ? Colors.green.shade700 : (runner.isDns ? Colors.orange.shade700 : Colors.red.shade700),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'G.Rank: ${runner.genderRank > 0 ? runner.genderRank.toString() : '-'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: runner.genderRank == 1 ? Colors.amber.shade700 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
