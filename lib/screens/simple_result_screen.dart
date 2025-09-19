import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/runner.dart';
import '../services/supabase_service.dart';

class SimpleResultScreen extends StatefulWidget {
  const SimpleResultScreen({super.key});

  @override
  State<SimpleResultScreen> createState() => _SimpleResultScreenState();
}

class _SimpleResultScreenState extends State<SimpleResultScreen> {
  List<Runner> allRunners = [];
  List<Runner> filteredRunners = [];
  bool isLoading = true;
  String searchQuery = '';
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
      final fetchedRunners = await SupabaseService.getAllRunners();
      
      // Calculate gender ranks
      _calculateGenderRanks(fetchedRunners);
      
      setState(() {
        allRunners = fetchedRunners;
        filteredRunners = fetchedRunners;
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

  void _calculateGenderRanks(List<Runner> runners) {
    // Separate by gender and sort by finish time
    final maleRunners = runners.where((r) => r.gender == 'male' && r.isFinished).toList();
    final femaleRunners = runners.where((r) => r.gender == 'female' && r.isFinished).toList();
    
    // Sort by total time
    maleRunners.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
    femaleRunners.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
    
    // Assign gender ranks
    for (int i = 0; i < maleRunners.length; i++) {
      maleRunners[i].genderRank = i + 1;
    }
    for (int i = 0; i < femaleRunners.length; i++) {
      femaleRunners[i].genderRank = i + 1;
    }
  }

  void _filterRunners(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRunners = allRunners;
      } else {
        filteredRunners = allRunners.where((runner) {
          return runner.name.toLowerCase().contains(query.toLowerCase()) ||
                 runner.bib.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'RESULTS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRunners,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    onChanged: _filterRunners,
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
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 16,
                      minWidth: 800,
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: [
                        DataColumn2(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (sortColumn == 'rank')
                                Icon(
                                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.blue.shade800,
                                ),
                            ],
                          ),
                          onSort: (columnIndex, ascending) => _sort('rank'),
                        ),
                        DataColumn2(
                          label: Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _sort('name'),
                        ),
                        DataColumn2(
                          label: Text(
                            'Bib',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _sort('bib'),
                        ),
                        DataColumn2(
                          label: Text(
                            'Gender',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          onSort: (columnIndex, ascending) => _sort('gender'),
                        ),
                        DataColumn2(
                          label: Text(
                            'Check Point',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        DataColumn2(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (sortColumn == 'time')
                                Icon(
                                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.blue.shade800,
                                ),
                            ],
                          ),
                          onSort: (columnIndex, ascending) => _sort('time'),
                        ),
                        DataColumn2(
                          label: Text(
                            'Gender Rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        DataColumn2(
                          label: Text(
                            'Certificate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                      rows: filteredRunners.asMap().entries.map((entry) {
                        final index = entry.key;
                        final runner = entry.value;
                        
                        // Calculate overall rank
                        int overallRank = 0;
                        if (runner.isFinished) {
                          final finishedRunners = filteredRunners.where((r) => r.isFinished).toList();
                          finishedRunners.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
                          overallRank = finishedRunners.indexOf(runner) + 1;
                        }
                        
                        return DataRow2(
                          color: MaterialStateProperty.all(
                            index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                          ),
                          cells: [
                            DataCell(
                              Text(
                                overallRank > 0 ? overallRank.toString() : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: overallRank == 1 ? Colors.amber.shade700 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                runner.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  runner.bib,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    runner.gender == 'male' ? Icons.male : Icons.female,
                                    color: runner.gender == 'male' ? Colors.blue : Colors.pink,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(runner.gender.toUpperCase()),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                runner.cp1.isNotEmpty ? runner.cp1 : '-',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Text(
                                runner.formattedTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: runner.isFinished 
                                      ? Colors.green.shade700 
                                      : (runner.isDns ? Colors.orange.shade700 : Colors.red.shade700),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                runner.genderRank > 0 ? runner.genderRank.toString() : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: runner.genderRank == 1 ? Colors.amber.shade700 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            DataCell(
                              runner.isFinished
                                  ? InkWell(
                                      onTap: () {
                                        // TODO: Implement certificate download
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Certificate download coming soon!')),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.download,
                                            size: 16,
                                            color: Colors.blue.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Download',
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const Text(
                                      '-',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
