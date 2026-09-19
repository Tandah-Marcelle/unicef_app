import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/family.dart';
import '../models/evaluation.dart';
import '../models/group_session.dart';
import '../models/alert.dart';

/// REST client for the ComMobi-Tracker backend (unicef_server).
///
/// [baseUrl] must point at the PC running `npm start`.
/// - Physical phone over Wi-Fi/hotspot : http://192.168.43.69:4000
/// - Android emulator                  : http://10.0.2.2:4000
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'http://192.168.43.69:4000';

  String? _token;

  bool get hasToken => _token != null;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String identifier, String pin) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'identifier': identifier, 'pin': pin}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      setToken(body['token'] as String?);
    }
    return body;
  }

  // ── Sync ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> push({
    required List<Family> families,
    required List<Evaluation> evaluations,
    required List<GroupSession> groupSessions,
    required List<Alert> alerts,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/sync/push'),
      headers: _headers,
      body: jsonEncode({
        'families': families.map((f) => f.toMap()).toList(),
        'evaluations': evaluations.map((e) => e.toMap()).toList(),
        'groupSessions': groupSessions.map((s) => s.toMap()).toList(),
        'alerts': alerts.map((a) => a.toMap()).toList(),
      }),
    );
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Downloads every record from the server as local-model maps.
  Future<SyncPullResult> pull() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/sync/pull'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Pull failed (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final fams = ((body['families'] ?? []) as List)
        .map((r) => familyFromServer(r as Map<String, dynamic>))
        .toList();
    final evals = ((body['evaluations'] ?? []) as List)
        .map((r) => evaluationFromServer(r as Map<String, dynamic>))
        .toList();
    final sess = ((body['groupSessions'] ?? []) as List)
        .map((r) => sessionFromServer(r as Map<String, dynamic>))
        .toList();
    final alts = ((body['alerts'] ?? []) as List)
        .map((r) => alertFromServer(r as Map<String, dynamic>))
        .toList();
    return SyncPullResult(families: fams, evaluations: evals, sessions: sess, alerts: alts);
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Server row (snake_case) → local model map (camelCase) ────────────────

  static int _b(dynamic v) =>
      v == null ? 0 : (v is bool ? (v ? 1 : 0) : (v == 1 || v == '1' ? 1 : 0));

  static double? _d(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  static Family familyFromServer(Map<String, dynamic> r) => Family(
        id: r['id'] ?? '',
        householdName: r['household_name'] ?? '',
        childCount: (r['child_count'] as num?)?.toInt() ?? 0,
        status: r['status'] ?? 'Partial Follow-up',
        neighborhood: r['neighborhood'] ?? '',
        lastVisitDate: r['last_visit_date'] ?? '',
        isSynced: 1,
        photoProofPaths: r['photo_proof_paths'],
        phoneNumber: r['phone_number'],
        vulnerabilityStatus: r['vulnerability_status'] ?? 'Normal',
        latitude: _d(r['latitude']),
        longitude: _d(r['longitude']),
        region: r['region'],
        department: r['department'],
        arrondissement: r['arrondissement'],
        createdAt: r['created_at'] != null
            ? (r['created_at'] as String).substring(0, 10)
            : null,
      );

  static Evaluation evaluationFromServer(Map<String, dynamic> r) => Evaluation(
        id: r['id'] ?? '',
        familyId: r['family_id'] ?? '',
        hasBirthCertificate: _b(r['has_birth_certificate']) == 1,
        hasChildrenWithDisabilities: _b(r['has_children_with_disabilities']) == 1,
        bestInterestUnderstood: _b(r['best_interest_understood']) == 1,
        vaccinationsUpToDate: _b(r['vaccinations_up_to_date']) == 1,
        exclusiveBreastfeeding: _b(r['exclusive_breastfeeding']) == 1,
        bedNetsUsed: _b(r['bed_nets_used']) == 1,
        handwashingWithSoap: _b(r['handwashing_with_soap']) == 1,
        practicesBudgeting: _b(r['practices_budgeting']) == 1,
        corporalPunishmentUsed: _b(r['corporal_punishment_used']) == 1,
        positiveReinforcementUsed: _b(r['positive_reinforcement_used']) == 1,
        visitNotes: r['visit_notes'] ?? '',
        visitDate: r['visit_date'] ?? '',
        isSynced: 1,
        photoProofPaths: r['photo_proof_paths'],
      );

  static GroupSession sessionFromServer(Map<String, dynamic> r) => GroupSession(
        id: r['id'] ?? '',
        sessionDate: r['session_date'] ?? '',
        location: r['location'] ?? '',
        menAttendance: (r['men_attendance'] as num?)?.toInt() ?? 0,
        womenAttendance: (r['women_attendance'] as num?)?.toInt() ?? 0,
        topicCovered: r['topic_covered'] ?? '',
        isSynced: 1,
        photoProofPaths: r['photo_proof_paths'],
        latitude: _d(r['latitude']),
        longitude: _d(r['longitude']),
      );

  static Alert alertFromServer(Map<String, dynamic> r) => Alert(
        id: r['id'] ?? '',
        riskCategory: r['risk_category'] ?? '',
        anonymizedDescription: r['anonymized_description'] ?? '',
        isRedPriority: _b(r['is_red_priority']),
        incidentDate: r['incident_date'] ?? '',
        isSynced: 1,
        latitude: _d(r['latitude']),
        longitude: _d(r['longitude']),
      );
}

class SyncPullResult {
  final List<Family> families;
  final List<Evaluation> evaluations;
  final List<GroupSession> sessions;
  final List<Alert> alerts;

  SyncPullResult({
    required this.families,
    required this.evaluations,
    required this.sessions,
    required this.alerts,
  });

  int get totalCount =>
      families.length + evaluations.length + sessions.length + alerts.length;
}