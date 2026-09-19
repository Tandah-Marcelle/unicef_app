class GroupSession {
  final String id;
  final String sessionDate;
  final String location;
  final int menAttendance;
  final int womenAttendance;
  final String topicCovered;
  final int isSynced;
  final String? photoProofPaths;
  final double? latitude;
  final double? longitude;

  GroupSession({
    required this.id,
    required this.sessionDate,
    required this.location,
    required this.menAttendance,
    required this.womenAttendance,
    required this.topicCovered,
    this.isSynced = 0,
    this.photoProofPaths,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  double get positiveMasculinityIndex {
    final total = menAttendance + womenAttendance;
    if (total == 0) return 0.0;
    return (menAttendance / total) * 100;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionDate': sessionDate,
        'location': location,
        'menAttendance': menAttendance,
        'womenAttendance': womenAttendance,
        'topicCovered': topicCovered,
        'isSynced': isSynced,
        'photoProofPaths': photoProofPaths,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory GroupSession.fromMap(Map<String, dynamic> map) => GroupSession(
        id: map['id'] ?? '',
        sessionDate: map['sessionDate'] ?? '',
        location: map['location'] ?? '',
        menAttendance: map['menAttendance'] ?? 0,
        womenAttendance: map['womenAttendance'] ?? 0,
        topicCovered: map['topicCovered'] ?? '',
        isSynced: map['isSynced'] ?? 0,
        photoProofPaths: map['photoProofPaths'],
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      );

  GroupSession copyWith({
    String? id,
    String? sessionDate,
    String? location,
    int? menAttendance,
    int? womenAttendance,
    String? topicCovered,
    int? isSynced,
    String? photoProofPaths,
    double? latitude,
    double? longitude,
  }) =>
      GroupSession(
        id: id ?? this.id,
        sessionDate: sessionDate ?? this.sessionDate,
        location: location ?? this.location,
        menAttendance: menAttendance ?? this.menAttendance,
        womenAttendance: womenAttendance ?? this.womenAttendance,
        topicCovered: topicCovered ?? this.topicCovered,
        isSynced: isSynced ?? this.isSynced,
        photoProofPaths: photoProofPaths ?? this.photoProofPaths,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
