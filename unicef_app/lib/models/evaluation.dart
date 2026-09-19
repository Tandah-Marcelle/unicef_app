class Evaluation {
  final String id;
  final String familyId;
  final bool hasBirthCertificate;
  final bool hasChildrenWithDisabilities;
  final bool bestInterestUnderstood;
  final bool vaccinationsUpToDate;
  final bool exclusiveBreastfeeding;
  final bool bedNetsUsed;
  final bool handwashingWithSoap;
  final bool practicesBudgeting;
  final bool corporalPunishmentUsed;
  final bool positiveReinforcementUsed;
  final String visitNotes;
  final String visitDate;
  final int isSynced;
  final String? photoProofPaths; // JSON-encoded list of paths

  Evaluation({
    required this.id,
    required this.familyId,
    required this.hasBirthCertificate,
    required this.hasChildrenWithDisabilities,
    required this.bestInterestUnderstood,
    required this.vaccinationsUpToDate,
    required this.exclusiveBreastfeeding,
    required this.bedNetsUsed,
    required this.handwashingWithSoap,
    required this.practicesBudgeting,
    required this.corporalPunishmentUsed,
    required this.positiveReinforcementUsed,
    required this.visitNotes,
    required this.visitDate,
    this.isSynced = 0,
    this.photoProofPaths,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'hasBirthCertificate': hasBirthCertificate ? 1 : 0,
      'hasChildrenWithDisabilities': hasChildrenWithDisabilities ? 1 : 0,
      'bestInterestUnderstood': bestInterestUnderstood ? 1 : 0,
      'vaccinationsUpToDate': vaccinationsUpToDate ? 1 : 0,
      'exclusiveBreastfeeding': exclusiveBreastfeeding ? 1 : 0,
      'bedNetsUsed': bedNetsUsed ? 1 : 0,
      'handwashingWithSoap': handwashingWithSoap ? 1 : 0,
      'practicesBudgeting': practicesBudgeting ? 1 : 0,
      'corporalPunishmentUsed': corporalPunishmentUsed ? 1 : 0,
      'positiveReinforcementUsed': positiveReinforcementUsed ? 1 : 0,
      'visitNotes': visitNotes,
      'visitDate': visitDate,
      'isSynced': isSynced,
      'photoProofPaths': photoProofPaths,
    };
  }

  factory Evaluation.fromMap(Map<String, dynamic> map) {
    return Evaluation(
      id: map['id'] ?? '',
      familyId: map['familyId'] ?? '',
      hasBirthCertificate: (map['hasBirthCertificate'] ?? 0) == 1,
      hasChildrenWithDisabilities: (map['hasChildrenWithDisabilities'] ?? 0) == 1,
      bestInterestUnderstood: (map['bestInterestUnderstood'] ?? 0) == 1,
      vaccinationsUpToDate: (map['vaccinationsUpToDate'] ?? 0) == 1,
      exclusiveBreastfeeding: (map['exclusiveBreastfeeding'] ?? 0) == 1,
      bedNetsUsed: (map['bedNetsUsed'] ?? 0) == 1,
      handwashingWithSoap: (map['handwashingWithSoap'] ?? 0) == 1,
      practicesBudgeting: (map['practicesBudgeting'] ?? 0) == 1,
      corporalPunishmentUsed: (map['corporalPunishmentUsed'] ?? 0) == 1,
      positiveReinforcementUsed: (map['positiveReinforcementUsed'] ?? 0) == 1,
      visitNotes: map['visitNotes'] ?? '',
      visitDate: map['visitDate'] ?? '',
      isSynced: map['isSynced'] ?? 0,
      photoProofPaths: map['photoProofPaths'],
    );
  }

  Evaluation copyWith({
    String? id,
    String? familyId,
    bool? hasBirthCertificate,
    bool? hasChildrenWithDisabilities,
    bool? bestInterestUnderstood,
    bool? vaccinationsUpToDate,
    bool? exclusiveBreastfeeding,
    bool? bedNetsUsed,
    bool? handwashingWithSoap,
    bool? practicesBudgeting,
    bool? corporalPunishmentUsed,
    bool? positiveReinforcementUsed,
    String? visitNotes,
    String? visitDate,
    int? isSynced,
    String? photoProofPaths,
  }) {
    return Evaluation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      hasBirthCertificate: hasBirthCertificate ?? this.hasBirthCertificate,
      hasChildrenWithDisabilities: hasChildrenWithDisabilities ?? this.hasChildrenWithDisabilities,
      bestInterestUnderstood: bestInterestUnderstood ?? this.bestInterestUnderstood,
      vaccinationsUpToDate: vaccinationsUpToDate ?? this.vaccinationsUpToDate,
      exclusiveBreastfeeding: exclusiveBreastfeeding ?? this.exclusiveBreastfeeding,
      bedNetsUsed: bedNetsUsed ?? this.bedNetsUsed,
      handwashingWithSoap: handwashingWithSoap ?? this.handwashingWithSoap,
      practicesBudgeting: practicesBudgeting ?? this.practicesBudgeting,
      corporalPunishmentUsed: corporalPunishmentUsed ?? this.corporalPunishmentUsed,
      positiveReinforcementUsed: positiveReinforcementUsed ?? this.positiveReinforcementUsed,
      visitNotes: visitNotes ?? this.visitNotes,
      visitDate: visitDate ?? this.visitDate,
      isSynced: isSynced ?? this.isSynced,
      photoProofPaths: photoProofPaths ?? this.photoProofPaths,
    );
  }
}
