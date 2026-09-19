import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/family.dart';
import '../providers/app_state.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class FormScreen extends StatefulWidget {
  final Family family;
  const FormScreen({super.key, required this.family});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // ── Assessment state ──────────────────────────────────────────────────────
  bool _hasBirthCertificate        = false;
  bool _hasChildrenWithDisabilities = false;
  bool _bestInterestUnderstood     = false;
  bool _vaccinationsUpToDate       = false;
  bool _exclusiveBreastfeeding     = false;
  bool _bedNetsUsed                = false;
  bool _handwashingWithSoap        = false;
  bool _practicesBudgeting         = false;
  bool _corporalPunishmentUsed     = false;
  bool _positiveReinforcementUsed  = true;

  // Photo proofs — one list per module (indexed 0-4)
  final List<List<String>> _modulePhotos = List.generate(5, (_) => []);
  static const int _maxPhotos = 3;

  final TextEditingController _notesController = TextEditingController();
  bool _isListeningMock = false;
  final ImagePicker _picker = ImagePicker();

  String _t(String key) {
    final state = Provider.of<AppState>(context, listen: false);
    return LocalizationService.translate(key, state.currentLocale);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── TTS helper ───────────────────────────────────────────────────────────
  void _speak(String text) {
    final state = Provider.of<AppState>(context, listen: false);
    TtsService.instance.speak(text, state.currentLocale);
  }

  // ── Voice dictation mock ─────────────────────────────────────────────────
  void _toggleVoice(AppState state) {
    setState(() => _isListeningMock = !_isListeningMock);
    if (_isListeningMock) {
      state.speak('Écoute en cours...');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isListeningMock) {
          final samples = {
            'fr': "La famille progresse bien. Les modules sur l'hygiène et la discipline positive ont été abordés.",
            'en': 'Family is making steady progress. Modules on hygiene and positive discipline discussed.',
            'pcm': 'Family dey make progress fine. We talk about hygiene and fine training for pikin.',
          };
          setState(() {
            _notesController.text = samples[state.currentLocale] ?? samples['fr']!;
            _isListeningMock = false;
          });
          state.speak('Saisie vocale terminée.');
        }
      });
    } else {
      state.speak('Saisie vocale arrêtée.');
    }
  }

  // ── Photo picker ─────────────────────────────────────────────────────────
  Future<void> _pickPhoto(int moduleIndex, ImageSource source) async {
    if (_modulePhotos[moduleIndex].length >= _maxPhotos) return;
    try {
      final XFile? img = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (img != null) setState(() => _modulePhotos[moduleIndex].add(img.path));
    } catch (_) {}
  }

  void _showPhotoPicker(int moduleIndex) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: AppTheme.unicefBlueSolid, size: 22.sp),
            title: Text('Prendre une photo', style: TextStyle(fontSize: 14.sp)),
            onTap: () { Navigator.pop(context); _pickPhoto(moduleIndex, ImageSource.camera); },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: AppTheme.minproffGreen, size: 22.sp),
            title: Text('Choisir depuis la galerie', style: TextStyle(fontSize: 14.sp)),
            onTap: () { Navigator.pop(context); _pickPhoto(moduleIndex, ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  void _save(AppState state) {
    final allPhotos = _modulePhotos.expand((l) => l).toList();
    state.addEvaluation(
      familyId:    widget.family.id,
      hasBirthCert: _hasBirthCertificate,
      hasDisability: _hasChildrenWithDisabilities,
      bestInterest: _bestInterestUnderstood,
      vaccination:  _vaccinationsUpToDate,
      breastfeeding: _exclusiveBreastfeeding,
      bednets:      _bedNetsUsed,
      wash:         _handwashingWithSoap,
      budgeting:    _practicesBudgeting,
      abuse:        _corporalPunishmentUsed,
      dialogue:     _positiveReinforcementUsed,
      notes:        _notesController.text,
      photoPaths:   allPhotos.isNotEmpty ? allPhotos : null,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppTheme.minproffGreen,
      content: Text(_t('save_success'), style: TextStyle(fontSize: 13.sp)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('module_title'), style: TextStyle(fontSize: 15.sp), overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildHouseholdHeader(appState),
          SizedBox(height: 14.h),

          // ── MODULE 1 ─────────────────────────────────────────────
          _ModuleCard(
            moduleIndex: 0,
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF1565C0),
            bannerColor: const Color(0xFFE3F2FD),
            title: _t('module_1'),
            definition: 'Tout enfant a un droit inaliénable à l\'identité selon la loi camerounaise. '
                'L\'enregistrement des naissances protège contre la traite et garantit l\'accès à l\'école.',
            talkingPoints: const [
              'Le délai légal est de 90 jours après la naissance au bureau d\'état civil.',
              'Documents requis : acte de mariage ou déclaration de naissance, carte d\'identité des parents.',
              'Un enfant sans acte de naissance ne peut pas s\'inscrire à l\'école ou se faire soigner officiellement.',
              'En cas de délai dépassé, une procédure judiciaire de jugement supplétif est possible.',
            ],
            illustrationIcon: Icons.assignment_ind,
            photoLabel: 'Photo de l\'acte de naissance',
            modulePhotos: _modulePhotos[0],
            onAddPhoto: () => _showPhotoPicker(0),
            onRemovePhoto: (i) => setState(() => _modulePhotos[0].removeAt(i)),
            onTtsPressed: () => _speak(
              'Module 1. Tout enfant a le droit à une identité. Enregistrez les naissances dans 90 jours.'),
            appState: appState,
            assessmentWidgets: [
              _buildCheckbox(appState, _t('birth_cert_q'), _hasBirthCertificate,
                  (v) => setState(() => _hasBirthCertificate = v ?? false)),
              _buildCheckbox(appState, _t('disability_q'), _hasChildrenWithDisabilities,
                  (v) => setState(() => _hasChildrenWithDisabilities = v ?? false)),
            ],
          ),
          SizedBox(height: 10.h),

          // ── MODULE 2 ─────────────────────────────────────────────
          _ModuleCard(
            moduleIndex: 1,
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF2E7D32),
            bannerColor: const Color(0xFFE8F5E9),
            title: _t('module_2'),
            definition: 'La communauté et la famille sont les premiers garants du bien-être de l\'enfant. '
                'L\'intérêt supérieur de l\'enfant doit guider toutes les décisions familiales.',
            talkingPoints: const [
              'L\'intérêt supérieur de l\'enfant signifie : santé, éducation, protection et participation.',
              'Les leaders communautaires (chefs, anciens) ont un rôle clé dans la protection des enfants.',
              'Impliquer les deux parents dans les décisions concernant l\'enfant renforce sa sécurité.',
              'Tout acte violent ou négatif envers un enfant est interdit par la loi camerounaise.',
            ],
            illustrationIcon: Icons.shield_outlined,
            photoLabel: 'Preuve d\'engagement communautaire',
            modulePhotos: _modulePhotos[1],
            onAddPhoto: () => _showPhotoPicker(1),
            onRemovePhoto: (i) => setState(() => _modulePhotos[1].removeAt(i)),
            onTtsPressed: () => _speak(
              'Module 2. L\'intérêt supérieur de l\'enfant guide toutes les décisions familiales et communautaires.'),
            appState: appState,
            assessmentWidgets: [
              _buildCheckbox(appState, _t('best_interest_q'), _bestInterestUnderstood,
                  (v) => setState(() => _bestInterestUnderstood = v ?? false)),
            ],
          ),
          SizedBox(height: 10.h),

          // ── MODULE 3 & 4 ─────────────────────────────────────────
          _ModuleCard(
            moduleIndex: 2,
            icon: Icons.child_friendly_outlined,
            iconColor: const Color(0xFFE65100),
            bannerColor: const Color(0xFFFFF3E0),
            title: _t('module_3_4'),
            definition: 'Les 1 000 premiers jours de vie (de la conception aux 2 ans) sont déterminants '
                'pour le développement cognitif et physique de l\'enfant. L\'eau propre et l\'hygiène sauvent des vies.',
            talkingPoints: const [
              'Allaitement maternel exclusif pendant 6 mois : aucun autre aliment ni eau nécessaire.',
              'Nutrition 5 étoiles après 6 mois : céréales, légumineuses, légumes, fruits, protéines animales.',
              'Calendrier vaccinal complet : BCG, Polio, DTP-HepB-Hib, Rougeole aux âges requis.',
              'Traitement de l\'eau : ébullition 1 minute, chloration, ou filtre céramique.',
              'Lavage des mains aux 5 moments clés : avant de manger, après les toilettes, après avoir changé bébé, avant de cuisiner, après le contact avec des animaux.',
              'Moustiquaires imprégnées : utilisation chaque nuit pour tous les enfants de moins de 5 ans.',
            ],
            illustrationIcon: Icons.water_drop_outlined,
            photoLabel: 'Photo savon / point d\'eau / carnet vaccinal',
            modulePhotos: _modulePhotos[2],
            onAddPhoto: () => _showPhotoPicker(2),
            onRemovePhoto: (i) => setState(() => _modulePhotos[2].removeAt(i)),
            onTtsPressed: () => _speak(
              'Modules 3 et 4. Allaitement exclusif 6 mois, vaccins complets, eau propre, lavage des mains.'),
            appState: appState,
            assessmentWidgets: [
              _buildCheckbox(appState, _t('vaccination_q'), _vaccinationsUpToDate,
                  (v) => setState(() => _vaccinationsUpToDate = v ?? false)),
              _buildCheckbox(appState, _t('breastfeeding_q'), _exclusiveBreastfeeding,
                  (v) => setState(() => _exclusiveBreastfeeding = v ?? false)),
              _buildCheckbox(appState, _t('bednets_q'), _bedNetsUsed,
                  (v) => setState(() => _bedNetsUsed = v ?? false)),
              _buildCheckbox(appState, _t('wash_q'), _handwashingWithSoap,
                  (v) => setState(() => _handwashingWithSoap = v ?? false)),
            ],
          ),
          SizedBox(height: 10.h),

          // ── MODULE 5 ─────────────────────────────────────────────
          _ModuleCard(
            moduleIndex: 3,
            icon: Icons.savings_outlined,
            iconColor: const Color(0xFF6A1B9A),
            bannerColor: const Color(0xFFF3E5F5),
            title: _t('module_5'),
            definition: 'Gérer le budget familial permet d\'assurer les besoins fondamentaux de l\'enfant '
                '(alimentation, soins de santé, frais scolaires) même en période de soudure.',
            talkingPoints: const [
              'Identifier les revenus réguliers et irréguliers du ménage (agriculture, commerce, transferts).',
              'Lister les dépenses prioritaires : nourriture, santé, école — avant les dépenses de loisirs.',
              'Technique "enveloppe" : séparer physiquement l\'argent selon les postes de dépense.',
              'Épargne communautaire (tontine) : cotiser régulièrement pour les urgences médicales.',
              'Éviter les dettes à intérêt élevé ; préférer les groupements d\'épargne locaux.',
            ],
            illustrationIcon: Icons.account_balance_wallet_outlined,
            photoLabel: 'Photo du registre de budget ou de l\'épargne',
            modulePhotos: _modulePhotos[3],
            onAddPhoto: () => _showPhotoPicker(3),
            onRemovePhoto: (i) => setState(() => _modulePhotos[3].removeAt(i)),
            onTtsPressed: () => _speak(
              'Module 5. Planifiez votre budget familial. Priorité à la nourriture, la santé et l\'école.'),
            appState: appState,
            assessmentWidgets: [
              _buildCheckbox(appState, _t('budgeting_q'), _practicesBudgeting,
                  (v) => setState(() => _practicesBudgeting = v ?? false)),
            ],
          ),
          SizedBox(height: 10.h),

          // ── MODULE 6-10 ───────────────────────────────────────────
          _ModuleCard(
            moduleIndex: 4,
            icon: Icons.favorite_outline,
            iconColor: const Color(0xFFC62828),
            bannerColor: const Color(0xFFFFEBEE),
            title: _t('module_6_10'),
            definition: 'La discipline positive remplace la violence physique et verbale par des techniques '
                'd\'éducation bienveillante. Un enfant éduqué sans violence développe mieux sa confiance et ses capacités.',
            talkingPoints: const [
              'Alternatives aux fessées : retrait calme, conséquences logiques, temps de réflexion de 1 min/an d\'âge.',
              'Renforcement positif : féliciter immédiatement les bons comportements ("Tu as bien rangé tes affaires, bravo !").',
              'Communication non-violente : exprimer le besoin, pas la critique ("J\'ai besoin que tu rentrés à l\'heure" vs "Tu es irresponsable").',
              'Résolution de conflits : écouter les deux parties, chercher un accord, éviter les punitions humiliantes.',
              'Garder son calme : si un parent est en colère, s\'éloigner 5 minutes avant de réagir.',
              'L\'éducation des filles : favoriser l\'égalité d\'accès à l\'école, empêcher les mariages précoces.',
            ],
            illustrationIcon: Icons.handshake_outlined,
            photoLabel: 'Preuve d\'activité positive parent-enfant',
            modulePhotos: _modulePhotos[4],
            onAddPhoto: () => _showPhotoPicker(4),
            onRemovePhoto: (i) => setState(() => _modulePhotos[4].removeAt(i)),
            onTtsPressed: () => _speak(
              'Modules 6 à 10. Utilisez la discipline positive. Félicitez les bons comportements. Évitez toute violence.'),
            appState: appState,
            assessmentWidgets: [
              _buildRadioHeading(appState, _t('abuse_q')),
              _buildRadio(appState, 'Oui (Yes)', true, _corporalPunishmentUsed,
                  (v) => setState(() => _corporalPunishmentUsed = v ?? false)),
              _buildRadio(appState, 'Non (No)', false, _corporalPunishmentUsed,
                  (v) => setState(() => _corporalPunishmentUsed = v ?? false)),
              const Divider(),
              _buildRadioHeading(appState, _t('dialogue_q')),
              _buildRadio(appState, 'Oui (Yes)', true, _positiveReinforcementUsed,
                  (v) => setState(() => _positiveReinforcementUsed = v ?? false)),
              _buildRadio(appState, 'Non (No)', false, _positiveReinforcementUsed,
                  (v) => setState(() => _positiveReinforcementUsed = v ?? false)),
            ],
          ),
          SizedBox(height: 16.h),

          // ── VOICE / TEXT NOTES ────────────────────────────────────
          _buildNotesSection(appState),
          SizedBox(height: 24.h),

          // ── SAVE BUTTON ───────────────────────────────────────────
          _buildSaveButton(appState),
          SizedBox(height: 48.h),
        ]),
      ),
    );
  }

  // ── HOUSEHOLD HEADER ────────────────────────────────────────────────────────
  Widget _buildHouseholdHeader(AppState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.unicefBlueSolid, AppTheme.unicefBlueSolid.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22.r,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: Icon(Icons.family_restroom, color: Colors.white, size: 24.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.family.householdName,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            Text(
              '${widget.family.neighborhood}  ·  ${widget.family.childCount} enfant(s)',
              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            widget.family.vulnerabilityStatus ?? 'Normal',
            style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  // ── CHECKBOX / RADIO HELPERS ─────────────────────────────────────────────────
  Widget _buildCheckbox(AppState state, String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(fontSize: 13.sp, color: state.isHighContrast ? Colors.white : Colors.black87)),
      value: value,
      onChanged: (v) { onChanged(v); if (state.ttsEnabled) state.speak('$label : ${v == true ? 'Oui' : 'Non'}'); },
      activeColor: state.isHighContrast ? Colors.yellow : AppTheme.minproffGreen,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildRadioHeading(AppState state, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
      child: Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold,
          color: state.isHighContrast ? Colors.yellow : Colors.black87)),
    );
  }

  Widget _buildRadio(AppState state, String label, bool value, bool groupValue, ValueChanged<bool?> onChanged) {
    return RadioListTile<bool>(
      title: Text(label, style: TextStyle(fontSize: 13.sp, color: state.isHighContrast ? Colors.white : Colors.black87)),
      value: value,
      groupValue: groupValue,
      onChanged: (v) { onChanged(v); if (state.ttsEnabled) state.speak('$label sélectionné'); },
      activeColor: state.isHighContrast ? Colors.yellow : AppTheme.minproffGreen,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ── NOTES SECTION ────────────────────────────────────────────────────────────
  Widget _buildNotesSection(AppState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.notes, size: 18.sp, color: AppTheme.unicefBlueSolid),
        SizedBox(width: 8.w),
        Expanded(child: Text(_t('visit_notes'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        // Mic button
        GestureDetector(
          onTap: () => _toggleVoice(state),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _isListeningMock ? AppTheme.alertRed.withValues(alpha: 0.1) : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: _isListeningMock ? AppTheme.alertRed : Colors.grey[300]!,
                width: _isListeningMock ? 2 : 1,
              ),
            ),
            child: Icon(
              _isListeningMock ? Icons.mic : Icons.mic_none,
              size: 22.sp,
              color: _isListeningMock ? AppTheme.alertRed : (state.isHighContrast ? Colors.yellow : AppTheme.unicefBlueSolid),
            ),
          ),
        ),
      ]),
      SizedBox(height: 8.h),
      if (_isListeningMock)
        Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppTheme.alertRed.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.graphic_eq, size: 16.sp, color: AppTheme.alertRed),
            SizedBox(width: 8.w),
            Text('Écoute en cours... parlez maintenant',
                style: TextStyle(fontSize: 12.sp, color: AppTheme.alertRed, fontStyle: FontStyle.italic)),
          ]),
        ),
      TextField(
        controller: _notesController,
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: 13.sp, color: state.isHighContrast ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: _t('notes_placeholder'),
          hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
          filled: true,
          fillColor: state.isHighContrast ? Colors.grey[950] : Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: state.isHighContrast ? Colors.yellow : Colors.grey[300]!, width: state.isHighContrast ? 2 : 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppTheme.unicefBlueSolid, width: 2),
          ),
          contentPadding: EdgeInsets.all(12.w),
        ),
      ),
    ]);
  }

  // ── SAVE BUTTON ──────────────────────────────────────────────────────────────
  Widget _buildSaveButton(AppState state) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: () => _save(state),
        icon: Icon(Icons.save_outlined, size: 20.sp),
        label: Text(_t('save_offline'), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.minproffGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODULE CARD — Educational + Assessment hub per module
// ══════════════════════════════════════════════════════════════════════════════
class _ModuleCard extends StatefulWidget {
  final int moduleIndex;
  final IconData icon;
  final Color iconColor;
  final Color bannerColor;
  final String title;
  final String definition;
  final List<String> talkingPoints;
  final IconData illustrationIcon;
  final String photoLabel;
  final List<String> modulePhotos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onTtsPressed;
  final AppState appState;
  final List<Widget> assessmentWidgets;

  const _ModuleCard({
    required this.moduleIndex,
    required this.icon,
    required this.iconColor,
    required this.bannerColor,
    required this.title,
    required this.definition,
    required this.talkingPoints,
    required this.illustrationIcon,
    required this.photoLabel,
    required this.modulePhotos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onTtsPressed,
    required this.appState,
    required this.assessmentWidgets,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isHc = widget.appState.isHighContrast;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isHc ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isHc ? Colors.yellow : widget.iconColor.withValues(alpha: 0.3),
          width: isHc ? 2 : 1.5,
        ),
        boxShadow: isHc
            ? null
            : [BoxShadow(color: widget.iconColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── HEADER TAP ROW ─────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14.r), bottom: Radius.circular(_expanded ? 0 : 14.r)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(children: [
              Container(
                width: 40.w, height: 40.h,
                decoration: BoxDecoration(
                  color: widget.bannerColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,
                        color: isHc ? Colors.yellow : widget.iconColor),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              // TTS button
              GestureDetector(
                onTap: widget.onTtsPressed,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: widget.bannerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.volume_up_outlined, size: 18.sp, color: widget.iconColor),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isHc ? Colors.yellow : Colors.grey[500], size: 22.sp,
              ),
            ]),
          ),
        ),

        // ── EXPANDED BODY ─────────────────────────────────────
        if (_expanded) ...[
          Divider(height: 1, color: widget.iconColor.withValues(alpha: 0.15)),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              // A. Visual Banner + Definition
              _buildDefinitionBanner(),
              SizedBox(height: 14.h),

              // B. Key Talking Points
              _buildTalkingPoints(),
              SizedBox(height: 14.h),

              // C. Assessment Checklist
              _buildAssessmentSection(),
              SizedBox(height: 12.h),

              // D. Photo Proof
              _buildPhotoSection(),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── A. DEFINITION BANNER ─────────────────────────────────────────────────
  Widget _buildDefinitionBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: widget.bannerColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52.w, height: 52.h,
          decoration: BoxDecoration(
            color: widget.iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(widget.illustrationIcon, color: widget.iconColor, size: 28.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            widget.definition,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[800], height: 1.5),
          ),
        ),
      ]),
    );
  }

  // ── B. TALKING POINTS ────────────────────────────────────────────────────
  Widget _buildTalkingPoints() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.menu_book_outlined, size: 16.sp, color: widget.iconColor),
        SizedBox(width: 6.w),
        Text('Points clés à expliquer aux parents',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: widget.iconColor)),
      ]),
      SizedBox(height: 8.h),
      ...widget.talkingPoints.map((point) => Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: widget.bannerColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: widget.iconColor.withValues(alpha: 0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.arrow_right, size: 18.sp, color: widget.iconColor),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(point, style: TextStyle(fontSize: 12.sp, color: Colors.grey[800], height: 1.5)),
          ),
        ]),
      )),
    ]);
  }

  // ── C. ASSESSMENT SECTION ────────────────────────────────────────────────
  Widget _buildAssessmentSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.fact_check_outlined, size: 16.sp, color: widget.iconColor),
        SizedBox(width: 6.w),
        Text('Évaluation de la famille',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: widget.iconColor)),
      ]),
      SizedBox(height: 6.h),
      ...widget.assessmentWidgets,
    ]);
  }

  // ── D. PHOTO PROOF ────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    const maxPhotos = 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: Row(children: [
            Icon(Icons.camera_alt_outlined, size: 15.sp, color: widget.iconColor),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                '${widget.photoLabel} (${widget.modulePhotos.length}/$maxPhotos)',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: widget.iconColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
        if (widget.modulePhotos.length < maxPhotos)
          TextButton.icon(
            onPressed: widget.onAddPhoto,
            icon: Icon(Icons.add_a_photo_outlined, size: 15.sp),
            label: Text('Ajouter', style: TextStyle(fontSize: 11.sp)),
            style: TextButton.styleFrom(
              foregroundColor: widget.iconColor,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ]),
      if (widget.modulePhotos.isNotEmpty) ...[
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.modulePhotos.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) => Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(File(widget.modulePhotos[i]),
                    width: 80.w, height: 80.h, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80.w, height: 80.h, color: Colors.grey[200],
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 22.sp),
                    )),
              ),
              Positioned(
                top: 2.h, right: 2.w,
                child: GestureDetector(
                  onTap: () => widget.onRemovePhoto(i),
                  child: Container(
                    width: 20.w, height: 20.h,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Icon(Icons.close, color: Colors.white, size: 12.sp),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ] else ...[
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: widget.onAddPhoto,
          child: Container(
            height: 54.h,
            decoration: BoxDecoration(
              color: widget.bannerColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: widget.iconColor.withValues(alpha: 0.25), style: BorderStyle.solid),
            ),
            child: Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, size: 20.sp, color: widget.iconColor.withValues(alpha: 0.6)),
                SizedBox(width: 6.w),
                Text('Toucher pour ajouter une photo preuve',
                    style: TextStyle(fontSize: 11.sp, color: widget.iconColor.withValues(alpha: 0.7))),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }
}
