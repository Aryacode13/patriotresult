import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/runner.dart';

class ResultsTable extends StatefulWidget {
  final String title;
  final List<Runner> runners;
  final bool showCertificate;

  const ResultsTable({
    super.key,
    required this.title,
    required this.runners,
    this.showCertificate = false,
  });

  @override
  State<ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> {
  late List<Runner> allRunners;
  late List<Runner> filteredRunners;
  String searchQuery = '';
  String? sortColumn;
  bool sortAscending = true;
  
  // Pagination
  int currentPage = 0;
  final int itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    allRunners = List<Runner>.from(widget.runners);
    _calculateGenderRanks(allRunners);
    filteredRunners = List<Runner>.from(allRunners);
  }

  int _categoryMaxCpForRunner(Runner runner) {
    // Prefer runner.category if available; fallback to table title
    final category = (runner.category).toUpperCase();
    if (category.contains('5K')) return 4;
    if (category.contains('10K')) return 8;
    // Fallback to table title if runner category is empty
    final title = widget.title.toUpperCase();
    if (title.contains('5K')) return 4;
    if (title.contains('10K')) return 8;
    // Overall/mixed default to 8
    return 8;
  }

  String _cpValueByIndex(Runner r, int index) {
    switch (index) {
      case 1:
        return r.cp1;
      case 2:
        return r.cp2;
      case 3:
        return r.cp3;
      case 4:
        return r.cp4;
      case 5:
        return r.cp5;
      case 6:
        return r.cp6;
      case 7:
        return r.cp7;
      case 8:
        return r.cp8;
      default:
        return '';
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

  @override
  void didUpdateWidget(covariant ResultsTable oldWidget) {
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
    currentPage = 0; // Reset to first page when searching
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
      currentPage = 0; // Reset to first page when sorting

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
          content: Column(
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
              ...List.generate(maxCp + 1, (index) {
                final cpLabel = index == 0 ? 'CP0 (Start)' : 'CP$index';
                final cpTime = index == 0 ? runner.cp0 : _cpValueByIndex(runner, index);
                final isReached = cpTime.isNotEmpty;
                
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
                        cpLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isReached ? Colors.green.shade800 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        isReached ? cpTime : 'Not reached',
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
              // Always show CP9 (Finish) for all categories
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
                      'CP9 (Finish)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: runner.cp9.isNotEmpty ? Colors.blue.shade800 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      runner.cp9.isNotEmpty ? runner.cp9 : 'Not reached',
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
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    searchQuery = v;
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
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DataTable2(
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
                if (widget.showCertificate)
                  const DataColumn2(
                    label: Text('Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
              rows: _paginatedRunners.asMap().entries.map((entry) {
                final index = entry.key;
                final runner = entry.value;

                // overall rank inside this filtered list
                int overallRank = 0;
                final copy = filteredRunners.where((r) => r.isFinished).toList();
                copy.sort((a, b) => a.totalTime!.compareTo(b.totalTime!));
                if (runner.isFinished) {
                  overallRank = copy.indexOf(runner) + 1;
                }
                
                // Adjust rank for pagination
                final actualIndex = currentPage * itemsPerPage + index;

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
                      final label = lastCp > 0 ? 'CP$lastCp' : 'CP0';
                      
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
                    if (widget.showCertificate)
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        // Pagination Controls
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: currentPage > 0 ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
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
                    ElevatedButton.icon(
                      onPressed: currentPage < _totalPages - 1 ? _nextPage : null,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
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
      ],
    );
  }
}
