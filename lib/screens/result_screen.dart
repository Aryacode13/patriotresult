import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/runner.dart';
import '../models/race_category.dart';
import '../services/supabase_service.dart';

class ResultScreen extends StatefulWidget {
  final RaceCategory category;

  const ResultScreen({super.key, required this.category});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Runner> runners = [];
  bool isLoading = true;
  String? sortColumn;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadRunners();
  }

  Future<void> _loadRunners() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Runner> fetchedRunners;
      
      switch (widget.category) {
        case RaceCategory.male:
          fetchedRunners = await SupabaseService.getRunnersByGender('male');
          break;
        case RaceCategory.female:
          fetchedRunners = await SupabaseService.getRunnersByGender('female');
          break;
        case RaceCategory.umum:
          fetchedRunners = await SupabaseService.getRunnersByCategory('umum');
          break;
        case RaceCategory.veteran:
          fetchedRunners = await SupabaseService.getRunnersByCategory('veteran');
          break;
        case RaceCategory.master:
          fetchedRunners = await SupabaseService.getRunnersByCategory('master');
          break;
        default:
          fetchedRunners = await SupabaseService.getAllRunners();
      }

      setState(() {
        runners = fetchedRunners;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading results: $e')),
        );
      }
    }
  }

  void _sort(String columnName) {
    setState(() {
      if (sortColumn == columnName) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = columnName;
        sortAscending = true;
      }

      switch (columnName) {
        case 'rank':
          runners.sort((a, b) {
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
        case 'bib':
          runners.sort((a, b) => sortAscending 
              ? a.bib.compareTo(b.bib)
              : b.bib.compareTo(a.bib));
          break;
        case 'name':
          runners.sort((a, b) => sortAscending 
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'time':
          runners.sort((a, b) {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.displayName} Results'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRunners,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 800,
                            columns: [
                              DataColumn2(
                                label: Text(
                                  'Rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                onSort: (columnIndex, ascending) => _sort('rank'),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Bib',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                onSort: (columnIndex, ascending) => _sort('bib'),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                onSort: (columnIndex, ascending) => _sort('name'),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              DataColumn2(
                                label: Text(
                                  'Time Result',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                onSort: (columnIndex, ascending) => _sort('time'),
                              ),
                            ],
                            rows: runners.asMap().entries.map((entry) {
                              final index = entry.key;
                              final runner = entry.value;
                              final rank = runner.isFinished ? index + 1 : '-';
                              
                              return DataRow2(
                                cells: [
                                  DataCell(
                                    Text(
                                      rank.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rank == 1 ? Colors.amber.shade700 : null,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        runner.bib,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(runner.name)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          runner.gender == 'male' 
                                              ? Icons.male 
                                              : Icons.female,
                                          color: runner.gender == 'male' 
                                              ? Colors.blue 
                                              : Colors.pink,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(runner.gender.toUpperCase()),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      runner.formattedTime,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: runner.isFinished 
                                            ? Colors.green.shade700 
                                            : (runner.isDns ? Colors.orange.shade700 : Colors.red.shade700),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final finishedCount = runners.where((r) => r.isFinished).length;
    final totalCount = runners.length;
    final dnfCount = runners.where((r) => r.isDnf).length;
    final dnsCount = runners.where((r) => r.isDns).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total', totalCount.toString(), Colors.blue),
            _buildSummaryItem('Finished', finishedCount.toString(), Colors.green),
            _buildSummaryItem('DNF', dnfCount.toString(), Colors.red),
            _buildSummaryItem('DNS', dnsCount.toString(), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
