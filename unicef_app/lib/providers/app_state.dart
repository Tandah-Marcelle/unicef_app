import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family.dart';
import '../models/evaluation.dart';
import '../models/group_session.dart';
import '../models/alert.dart';
import '../services/database_helper.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';
import '../services/localization_service.dart';

class AppState with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // UI state
  bool _isHighContrast = false;
  String _currentLocale = 'fr'; // DEFAULT: French (Cameroon Institutional Language)
  bool _ttsEnabled = false;
  double _fontScale = 1.0;
  bool _lastSyncSuccessful = false;

  // Database lists
  List<Family> _families = [];
  List<GroupSession> _sessions = [];
  List<Alert> _alerts = [];
  String _searchQuery = '';

  // User profile
  Map<String, dynamic>? _userProfile;

  // Synchronisation status
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  int _pendingSyncCount = 0;

  AppState() {
    _loadInitialData();
  }

  // Getters
  bool get isHighContrast => _isHighContrast;
  String get currentLocale => _currentLocale;
  bool get ttsEnabled => _ttsEnabled;
  bool get isTtsEnabled => _ttsEnabled; // alias
  double get fontScale => _fontScale;
  bool get isLastSyncSuccessful => _lastSyncSuccessful;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  int get pendingSyncCount => _pendingSyncCount;

  List<Family> get families {
    if (_searchQuery.isEmpty) {
      return _families;
    }
    final lowercaseQuery = _searchQuery.toLowerCase();
    return _families.where((f) {
      return f.householdName.toLowerCase().contains(lowercaseQuery) ||
          f.neighborhood.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<GroupSession> get sessions => _sessions;
  List<Alert> get alerts => _alerts;

  Map<String, dynamic>? get userProfile => _userProfile;

  // ── Prefs keys ────────────────────────────────────────────────────────────
  static const _kHighContrast = 'high_contrast';
  static const _kLocale       = 'locale';
  static const _kTts          = 'tts_enabled';
  static const _kFontScale    = 'font_scale';

  // Initialize
  Future<void> _loadInitialData() async {
    await _loadPrefs();
    await refreshAll();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isHighContrast = prefs.getBool(_kHighContrast) ?? false;
    _currentLocale  = prefs.getString(_kLocale)      ?? 'fr';
    _ttsEnabled     = prefs.getBool(_kTts)            ?? false;
    _fontScale      = prefs.getDouble(_kFontScale)    ?? 1.0;
    TtsService.instance.setEnabled(_ttsEnabled);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, _isHighContrast);
    await prefs.setString(_kLocale,     _currentLocale);
    await prefs.setBool(_kTts,          _ttsEnabled);
    await prefs.setDouble(_kFontScale,  _fontScale);
  }

  Future<void> refreshAll() async {
    _families = await _dbHelper.getAllFamilies();
    _sessions = await _dbHelper.getAllGroupSessions();
    _alerts   = await _dbHelper.getAllAlerts();
    _pendingSyncCount = await _dbHelper.getUnsyncedCount();
    _userProfile = await _dbHelper.getUserProfile();
    notifyListeners();
  }

  // ── Accessibility actions ─────────────────────────────────────────────────
  void toggleHighContrast() {
    _isHighContrast = !_isHighContrast;
    notifyListeners();
    _savePrefs();
    speakLocal('toggle_contrast');
  }

  void toggleTTS() {
    _ttsEnabled = !_ttsEnabled;
    TtsService.instance.setEnabled(_ttsEnabled);
    notifyListeners();
    _savePrefs();
    final phrase = _ttsEnabled
        ? LocalizationService.translate('tts_activated', _currentLocale)
        : LocalizationService.translate('tts_deactivated', _currentLocale);
    TtsService.instance.speak(phrase, _currentLocale);
  }

  void toggleTts() => toggleTTS();

  void setLocale(String locale) {
    if (locale == 'en' || locale == 'fr' || locale == 'pcm') {
      _currentLocale = locale;
      notifyListeners();
      _savePrefs();
      speak(LocalizationService.translate('app_name', _currentLocale));
    }
  }

  void changeLocale(String locale) => setLocale(locale);

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
    _savePrefs();
  }

  void speak(String text) {
    if (_ttsEnabled) {
      TtsService.instance.speak(text, _currentLocale);
    }
  }

  void speakLocal(String translationKey, {List<String>? args}) {
    if (_ttsEnabled) {
      final phrase = LocalizationService.translate(translationKey, _currentLocale, args: args);
      TtsService.instance.speak(phrase, _currentLocale);
    }
  }

  // Operations - Family

  Future<void> addFamily(
    String name,
    String neighborhood,
    int childrenCount, {
    List<String>? photoPaths,
    String? phoneNumber,
    String? vulnerabilityStatus,
  }) async {
    final pos = await LocationService.instance.getCurrentPosition();
    final newFamily = Family(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      householdName: name,
      childCount: childrenCount,
      status: 'Partial Follow-up',
      neighborhood: neighborhood,
      lastVisitDate: '',
      isSynced: 0,
      photoProofPaths: photoPaths != null ? jsonEncode(photoPaths) : null,
      phoneNumber: phoneNumber,
      vulnerabilityStatus: vulnerabilityStatus ?? 'Normal',
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
    await _dbHelper.insertFamily(newFamily);
    await refreshAll();
    speakLocal('save_success');
  }

  // Operations - Evaluation (10-Module Form)

  // Variant used by the Add Family sheet — accepts pre-captured GPS coords
  // instead of calling LocationService again (avoids double permission prompts).
  Future<void> addFamilyWithCoords(
    String name,
    String neighborhood,
    int childrenCount, {
    List<String>? photoPaths,
    String? phoneNumber,
    String? vulnerabilityStatus,
    double? latitude,
    double? longitude,
    String? region,
    String? department,
    String? arrondissement,
  }) async {
    final newFamily = Family(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      householdName: name,
      childCount: childrenCount,
      status: 'Partial Follow-up',
      neighborhood: neighborhood,
      lastVisitDate: '',
      isSynced: 0,
      photoProofPaths: photoPaths != null ? jsonEncode(photoPaths) : null,
      phoneNumber: phoneNumber,
      vulnerabilityStatus: vulnerabilityStatus ?? 'Normal',
      latitude: latitude,
      longitude: longitude,
      region: region,
      department: department,
      arrondissement: arrondissement,
      createdAt: DateTime.now().toIso8601String().substring(0, 10),
    );
    await _dbHelper.insertFamily(newFamily);
    await refreshAll();
    speakLocal('save_success');
  }

  Future<void> addEvaluation({
    required String familyId,
    required bool hasBirthCert,
    required bool hasDisability,
    required bool bestInterest,
    required bool vaccination,
    required bool breastfeeding,
    required bool bednets,
    required bool wash,
    required bool budgeting,
    required bool abuse,
    required bool dialogue,
    required String notes,
    List<String>? photoPaths,
  }) async {
    // Determine status: If positive habits are mostly checked and no corporal abuse, set status to Full Follow-up
    // Or set status based on specific parenting modules logic
    String followUpStatus = 'Full Follow-up';
    if (abuse || !hasBirthCert || !vaccination || !wash) {
      followUpStatus = 'Partial Follow-up';
    }

    final newEval = Evaluation(
      id: 'eval_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      familyId: familyId,
      hasBirthCertificate: hasBirthCert,
      hasChildrenWithDisabilities: hasDisability,
      bestInterestUnderstood: bestInterest,
      vaccinationsUpToDate: vaccination,
      exclusiveBreastfeeding: breastfeeding,
      bedNetsUsed: bednets,
      handwashingWithSoap: wash,
      practicesBudgeting: budgeting,
      corporalPunishmentUsed: abuse,
      positiveReinforcementUsed: dialogue,
      visitNotes: notes,
      visitDate: DateTime.now().toIso8601String().substring(0, 10),
      isSynced: 0,
      photoProofPaths: photoPaths != null ? jsonEncode(photoPaths) : null,
    );

    // Get family detail and update status
    final currentFamilies = await _dbHelper.getAllFamilies();
    final famIndex = currentFamilies.indexWhere((element) => element.id == familyId);
    if (famIndex != -1) {
      final updatedFamily = currentFamilies[famIndex].copyWith(
        status: followUpStatus,
        lastVisitDate: newEval.visitDate,
        isSynced: 0,
      );
      await _dbHelper.insertFamily(updatedFamily);
    }

    await _dbHelper.insertEvaluation(newEval);
    await refreshAll();
    speakLocal('save_success');
  }

  // Operations - Group Session Report

  Future<void> addGroupSession({
    required String location,
    required int men,
    required int women,
    required String topic,
    required String date,
    List<String>? photoPaths,
  }) async {
    final pos = await LocationService.instance.getCurrentPosition();
    final newSession = GroupSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      sessionDate: date,
      location: location,
      menAttendance: men,
      womenAttendance: women,
      topicCovered: topic,
      isSynced: 0,
      photoProofPaths: photoPaths != null ? jsonEncode(photoPaths) : null,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );

    await _dbHelper.insertGroupSession(newSession);
    await refreshAll();
    speakLocal('save_success');
  }

  // Operations - Emergency Alert

  Future<void> addAlert({
    required String riskCategory,
    required String description,
  }) async {
    final pos = await LocationService.instance.getCurrentPosition();
    final newAlert = Alert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      riskCategory: riskCategory,
      anonymizedDescription: description,
      isRedPriority: 1,
      incidentDate: DateTime.now().toIso8601String().substring(0, 10),
      isSynced: 0,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
    await _dbHelper.insertAlert(newAlert);
    await refreshAll();
    speakLocal('save_success');
  }

  // Search logic
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // User profile
  Future<void> updateProfileImage(String? imagePath) async {
    await _dbHelper.updateUserProfileImage(imagePath);
    _userProfile = await _dbHelper.getUserProfile();
    notifyListeners();
  }

  // Real sync: push offline records to the REST API, then pull server data.
  Future<bool> synchronizeData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _syncProgress = 0.1;
    _lastSyncSuccessful = false;
    notifyListeners();
    speakLocal('sync_in_progress');

    try {
      // 1) Push unsynced local records
      final unsyncedFams = await _dbHelper.getUnsyncedFamilies();
      final unsyncedEvals = await _dbHelper.getUnsyncedEvaluations();
      final unsyncedSessions = await _dbHelper.getUnsyncedGroupSessions();
      final unsyncedAlerts = await _dbHelper.getUnsyncedAlerts();

      final pushRes = await ApiClient.instance.push(
        families: unsyncedFams,
        evaluations: unsyncedEvals,
        groupSessions: unsyncedSessions,
        alerts: unsyncedAlerts,
      );
      if (pushRes['ok'] != true) {
        throw Exception(pushRes['error'] ?? 'Push rejected by server');
      }

      _syncProgress = 0.5;
      notifyListeners();

      // Mark pushed records as synced locally
      if (unsyncedFams.isNotEmpty) {
        await _dbHelper.markFamiliesAsSynced(unsyncedFams.map((f) => f.id).toList());
      }
      if (unsyncedEvals.isNotEmpty) {
        await _dbHelper.markEvaluationsAsSynced(unsyncedEvals.map((e) => e.id).toList());
      }
      if (unsyncedSessions.isNotEmpty) {
        await _dbHelper.markGroupSessionsAsSynced(unsyncedSessions.map((s) => s.id).toList());
      }
      if (unsyncedAlerts.isNotEmpty) {
        await _dbHelper.markAlertsAsSynced(unsyncedAlerts.map((a) => a.id).toList());
      }

      // 2) Pull server records and merge into local SQLite
      final pullRes = await ApiClient.instance.pull();
      await _dbHelper.upsertFamilies(pullRes.families);
      await _dbHelper.upsertEvaluations(pullRes.evaluations);
      await _dbHelper.upsertGroupSessions(pullRes.sessions);
      await _dbHelper.upsertAlerts(pullRes.alerts);

      _syncProgress = 1.0;
      _isSyncing = false;
      _lastSyncSuccessful = true;
      await refreshAll();
      speakLocal('sync_success');
      return true;
    } catch (e) {
      _isSyncing = false;
      _syncProgress = 0.0;
      _lastSyncSuccessful = false;
      notifyListeners();
      speakLocal('sync_failed');
      return false;
    }
  }
}
