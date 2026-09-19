class Alert {
  final String id;
  final String riskCategory;
  final String anonymizedDescription;
  final int isRedPriority;
  final String incidentDate;
  final int isSynced;
  final double? latitude;
  final double? longitude;

  Alert({
    required this.id,
    required this.riskCategory,
    required this.anonymizedDescription,
    this.isRedPriority = 1,
    required this.incidentDate,
    this.isSynced = 0,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'riskCategory': riskCategory,
        'anonymizedDescription': anonymizedDescription,
        'isRedPriority': isRedPriority,
        'incidentDate': incidentDate,
        'isSynced': isSynced,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Alert.fromMap(Map<String, dynamic> map) => Alert(
        id: map['id'] ?? '',
        riskCategory: map['riskCategory'] ?? '',
        anonymizedDescription: map['anonymizedDescription'] ?? '',
        isRedPriority: map['isRedPriority'] ?? 1,
        incidentDate: map['incidentDate'] ?? '',
        isSynced: map['isSynced'] ?? 0,
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      );

  Alert copyWith({
    String? id,
    String? riskCategory,
    String? anonymizedDescription,
    int? isRedPriority,
    String? incidentDate,
    int? isSynced,
    double? latitude,
    double? longitude,
  }) =>
      Alert(
        id: id ?? this.id,
        riskCategory: riskCategory ?? this.riskCategory,
        anonymizedDescription: anonymizedDescription ?? this.anonymizedDescription,
        isRedPriority: isRedPriority ?? this.isRedPriority,
        incidentDate: incidentDate ?? this.incidentDate,
        isSynced: isSynced ?? this.isSynced,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
