enum FollowUpPhase {
  initial,       // 0–3 months
  consolidation, // 3–6 months
  autonomy,      // 6–12 months
  longTerm,      // > 12 months
}

extension FollowUpPhaseExt on FollowUpPhase {
  String get label {
    switch (this) {
      case FollowUpPhase.initial:       return '0–3 Mois';
      case FollowUpPhase.consolidation: return '3–6 Mois';
      case FollowUpPhase.autonomy:      return '6M–1 An';
      case FollowUpPhase.longTerm:      return '+ 1 An';
    }
  }

  String get description {
    switch (this) {
      case FollowUpPhase.initial:       return 'Phase Initiale — État Civil & WASH';
      case FollowUpPhase.consolidation: return 'Consolidation — Discipline & Budget';
      case FollowUpPhase.autonomy:      return 'Autonomie & Pérennisation';
      case FollowUpPhase.longTerm:      return 'Suivi Long Terme';
    }
  }

  int get colorValue {
    switch (this) {
      case FollowUpPhase.initial:       return 0xFF1565C0; // deep blue
      case FollowUpPhase.consolidation: return 0xFF2E7D32; // green
      case FollowUpPhase.autonomy:      return 0xFF6A1B9A; // purple
      case FollowUpPhase.longTerm:      return 0xFF00838F; // teal
    }
  }
}

class Family {
  final String id;
  final String householdName;
  final int childCount;
  final String status;
  final String neighborhood;
  final String lastVisitDate;
  final int isSynced;
  final String? photoProofPaths;
  final String? phoneNumber;
  final String? vulnerabilityStatus; // 'Normal' | 'Élevé' | 'Urgence'
  final double? latitude;
  final double? longitude;
  // Admin hierarchy
  final String? region;
  final String? department;
  final String? arrondissement;
  // Time-based classification
  final String createdAt; // ISO date yyyy-MM-dd

  Family({
    required this.id,
    required this.householdName,
    required this.childCount,
    required this.status,
    required this.neighborhood,
    required this.lastVisitDate,
    this.isSynced = 0,
    this.photoProofPaths,
    this.phoneNumber,
    this.vulnerabilityStatus = 'Normal',
    this.latitude,
    this.longitude,
    this.region,
    this.department,
    this.arrondissement,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String().substring(0, 10);

  bool get hasLocation => latitude != null && longitude != null;

  /// Compute follow-up phase based on registration date.
  FollowUpPhase get followUpPhase {
    try {
      final registered = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(registered).inDays;
      if (diff < 90)  return FollowUpPhase.initial;
      if (diff < 180) return FollowUpPhase.consolidation;
      if (diff < 365) return FollowUpPhase.autonomy;
      return FollowUpPhase.longTerm;
    } catch (_) {
      return FollowUpPhase.initial;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'householdName': householdName,
        'childCount': childCount,
        'status': status,
        'neighborhood': neighborhood,
        'lastVisitDate': lastVisitDate,
        'isSynced': isSynced,
        'photoProofPaths': photoProofPaths,
        'phoneNumber': phoneNumber,
        'vulnerabilityStatus': vulnerabilityStatus,
        'latitude': latitude,
        'longitude': longitude,
        'region': region,
        'department': department,
        'arrondissement': arrondissement,
        // createdAt intentionally omitted — SQLite DEFAULT fills it on new rows,
        // and older DB schemas without the column won't error on insert.
      };

  factory Family.fromMap(Map<String, dynamic> map) => Family(
        id: map['id'] ?? '',
        householdName: map['householdName'] ?? '',
        childCount: map['childCount'] ?? 0,
        status: map['status'] ?? 'Partial Follow-up',
        neighborhood: map['neighborhood'] ?? '',
        lastVisitDate: map['lastVisitDate'] ?? '',
        isSynced: map['isSynced'] ?? 0,
        photoProofPaths: map['photoProofPaths'],
        phoneNumber: map['phoneNumber'],
        vulnerabilityStatus: map['vulnerabilityStatus'] ?? 'Normal',
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
        region: map['region'],
        department: map['department'],
        arrondissement: map['arrondissement'],
        createdAt: map['createdAt'] ?? DateTime.now().toIso8601String().substring(0, 10),
      );

  Family copyWith({
    String? id,
    String? householdName,
    int? childCount,
    String? status,
    String? neighborhood,
    String? lastVisitDate,
    int? isSynced,
    String? photoProofPaths,
    String? phoneNumber,
    String? vulnerabilityStatus,
    double? latitude,
    double? longitude,
    String? region,
    String? department,
    String? arrondissement,
    String? createdAt,
  }) =>
      Family(
        id: id ?? this.id,
        householdName: householdName ?? this.householdName,
        childCount: childCount ?? this.childCount,
        status: status ?? this.status,
        neighborhood: neighborhood ?? this.neighborhood,
        lastVisitDate: lastVisitDate ?? this.lastVisitDate,
        isSynced: isSynced ?? this.isSynced,
        photoProofPaths: photoProofPaths ?? this.photoProofPaths,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        vulnerabilityStatus: vulnerabilityStatus ?? this.vulnerabilityStatus,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        region: region ?? this.region,
        department: department ?? this.department,
        arrondissement: arrondissement ?? this.arrondissement,
        createdAt: createdAt ?? this.createdAt,
      );
}
