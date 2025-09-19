class Runner {
  final int id;
  final DateTime createdAt;
  final String bib;
  final String name;
  final String gender;
  final String category;
  final String bloodType;
  final String cp0; // Start time
  final String cp1;
  final String cp2;
  final String cp3;
  final String cp4;
  final String cp5;
  final String cp6;
  final String cp7;
  final String cp8;
  final String cp9; // Finish time
  final bool isActive;
  final bool isDnf;
  final bool isDns;
  final String tag;

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'bib': bib,
      'name': name,
      'gender': gender,
      'category': category,
      'blood_type': bloodType,
      'cp0': cp0,
      'cp1': cp1,
      'cp2': cp2,
      'cp3': cp3,
      'cp4': cp4,
      'cp5': cp5,
      'cp6': cp6,
      'cp7': cp7,
      'cp8': cp8,
      'cp9': cp9,
      'is_active': isActive,
      'is_dnf': isDnf,
      'is_dns': isDns,
      'tag': tag,
    };
  }

  String get formattedTime {
    if (isDnf || isDns) {
      return isDns ? 'DNS' : 'DNF';
    }
    
    if (cp9.isEmpty) return 'DNF';
    
    // Parse time from cp9 (finish time) and cp0 (start time)
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

  DateTime? _parseTime(String timeString) {
    if (timeString.isEmpty) return null;
    
    try {
      // Try parsing as DateTime first
      if (timeString.contains('T') || timeString.contains(' ')) {
        return DateTime.parse(timeString);
      }
      
      // Try parsing as time format (HH:MM:SS)
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length > 2 ? int.parse(parts[2]) : 0;
        
        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  bool get isFinished => !isDnf && !isDns && cp9.isNotEmpty;

  // Gender rank will be calculated in the service
  int genderRank = 0;
}
