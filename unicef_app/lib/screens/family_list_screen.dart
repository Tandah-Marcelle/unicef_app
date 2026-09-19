import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/family.dart';
import '../providers/app_state.dart';
import '../services/cameroon_admin.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cameroon_location_picker.dart';
import '../widgets/glass_field.dart';
import 'form_screen.dart';

// ── Palette for avatar circles (cycles by index) ────────────────────────────
const _avatarColors = [
  Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00838F),
  Color(0xFF2E7D32), Color(0xFFAD1457), Color(0xFFE65100),
  Color(0xFF4527A0), Color(0xFF00695C),
];

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});
  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool   _searchOpen   = false;
  String? _expandedId;          // id of currently expanded card
  FollowUpPhase? _phaseFilter;
  String? _filterRegion;
  String? _filterDept;

  String _t(String key) =>
      LocalizationService.translate(key, Provider.of<AppState>(context, listen: false).currentLocale);

  Color _vulnColor(String? s) {
    switch (s) {
      case 'Urgence': return AppTheme.alertRed;
      case 'Élevé':   return AppTheme.warningOrange;
      default:        return AppTheme.minproffGreen;
    }
  }

  Color _phaseColor(FollowUpPhase p) => Color(p.colorValue);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Family> _applyFilters(List<Family> all) {
    var list = all;
    if (_phaseFilter   != null) list = list.where((f) => f.followUpPhase == _phaseFilter).toList();
    if (_filterRegion  != null) list = list.where((f) => f.region     == _filterRegion).toList();
    if (_filterDept    != null) list = list.where((f) => f.department == _filterDept).toList();
    return list;
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState  = Provider.of<AppState>(context);
    final displayed = _applyFilters(appState.families);
    final hasFilter = _filterRegion != null || _filterDept != null || _phaseFilter != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: appState.updateSearchQuery,
                style: TextStyle(fontSize: 15.sp, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: _t('search_placeholder'),
                  hintStyle: TextStyle(fontSize: 14.sp, color: Colors.white60),
                  border: InputBorder.none,
                ),
              )
            : Text(_t('my_families'),
                style: TextStyle(fontSize: 17.sp), overflow: TextOverflow.ellipsis),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search, size: 22.sp),
            tooltip: 'Rechercher',
            onPressed: () {
              setState(() { _searchOpen = !_searchOpen; });
              if (!_searchOpen) {
                _searchController.clear();
                appState.updateSearchQuery('');
              }
            },
          ),
          // Add family
          IconButton(
            icon: Icon(Icons.add, size: 24.sp),
            tooltip: 'Nouvelle famille',
            onPressed: () => _showAddFamilySheet(context, appState),
          ),
          // Three-dot menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 22.sp),
            onSelected: (v) => _onMenuSelected(v, appState),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list,
                      color: hasFilter ? AppTheme.unicefBlueSolid : null),
                  title: Text('Filtrer par zone',
                      style: TextStyle(fontSize: 13.sp,
                          color: hasFilter ? AppTheme.unicefBlueSolid : null)),
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
              PopupMenuItem(value: 'select',
                child: ListTile(
                  leading: const Icon(Icons.check_box_outlined),
                  title: Text('Sélectionner', style: TextStyle(fontSize: 13.sp)),
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: Text('Importer', style: TextStyle(fontSize: 13.sp)),
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
              PopupMenuItem(value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text('Exporter', style: TextStyle(fontSize: 13.sp)),
                  dense: true, contentPadding: EdgeInsets.zero,
                )),
            ],
          ),
        ],
      ),
      body: Column(children: [
        _buildStatsRow(appState),
        _buildPhaseFilterBar(),
        Expanded(
          child: displayed.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(top: 6.h, bottom: 20.h),
                  itemCount: displayed.length,
                  itemBuilder: (ctx, i) =>
                      _buildFamilyRow(ctx, displayed[i], i, appState),
                ),
        ),
      ]),
    );
  }

  void _onMenuSelected(String value, AppState appState) {
    switch (value) {
      case 'filter': _showAdminFilterSheet(appState); break;
      case 'select':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mode sélection — bientôt disponible')));
        break;
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importation — bientôt disponible')));
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportation — bientôt disponible')));
        break;
    }
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(AppState state) {
    final total  = state.families.length;
    final full   = state.families.where((f) => f.status == 'Full Follow-up').length;
    final urgent = state.families.where((f) => f.vulnerabilityStatus == 'Urgence').length;
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(children: [
        _statPill(Icons.people_outline, '$total', 'Total', AppTheme.unicefBlueSolid),
        _vDivider(),
        _statPill(Icons.check_circle_outline, '$full', 'Suivi complet', AppTheme.minproffGreen),
        _vDivider(),
        _statPill(Icons.warning_amber_outlined, '$urgent', 'Urgence', AppTheme.alertRed),
      ]),
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13.sp, color: color), SizedBox(width: 3.w),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ]),
        SizedBox(height: 1.h),
        Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
      ]));

  Widget _vDivider() => Container(
      width: 1, height: 28.h, color: Colors.grey[200],
      margin: EdgeInsets.symmetric(horizontal: 4.w));

  // ── Phase filter chips ─────────────────────────────────────────────────────
  Widget _buildPhaseFilterBar() {
    final phases = [null, ...FollowUpPhase.values];
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        scrollDirection: Axis.horizontal,
        itemCount: phases.length,
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (_, i) {
          final phase  = phases[i];
          final active = _phaseFilter == phase;
          final label  = phase == null ? 'Toutes' : phase.label;
          final color  = phase == null ? AppTheme.unicefBlueSolid : _phaseColor(phase);
          return GestureDetector(
            onTap: () => setState(() => _phaseFilter = phase),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: active ? color : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: active ? color : Colors.grey[300]!),
              ),
              child: Text(label,
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : Colors.grey[700])),
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.family_restroom, size: 56.sp, color: Colors.grey[300]),
      SizedBox(height: 12.h),
      Text('Aucune famille trouvée.',
          style: TextStyle(fontSize: 15.sp, color: Colors.grey[500])),
      SizedBox(height: 6.h),
      Text('Appuyez sur + pour enregistrer une famille.',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[400])),
    ]),
  );

  // ── Contact-style row with accordion expand ────────────────────────────────
  Widget _buildFamilyRow(BuildContext ctx, Family family, int index, AppState appState) {
    final isExpanded = _expandedId == family.id;
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final initial = family.householdName.isNotEmpty
        ? family.householdName[0].toUpperCase()
        : '?';
    final vulnColor = _vulnColor(family.vulnerabilityStatus);
    final phase = family.followUpPhase;
    final isFull = family.status == 'Full Follow-up';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Row ──────────────────────────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expandedId = isExpanded ? null : family.id),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(children: [
              // Avatar circle
              CircleAvatar(
                radius: 22.r,
                backgroundColor: avatarColor,
                child: Text(initial,
                    style: TextStyle(color: Colors.white, fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 14.w),
              // Name + subtitle
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.householdName,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      family.neighborhood,
                      '${family.childCount} enfant(s)',
                      if (family.region != null) family.region!,
                    ].join(' · '),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )),
              SizedBox(width: 8.w),
              // Vuln dot
              Container(
                width: 10.w, height: 10.w,
                decoration: BoxDecoration(color: vulnColor, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20.sp, color: Colors.grey[400]),
            ]),
          ),
        ),

        // ── Expanded details panel ────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: const Color(0xFFF9F9FB),
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status + phase badges
              Wrap(spacing: 6.w, runSpacing: 6.h, children: [
                _badge(isFull ? 'Suivi Complet' : 'Suivi Partiel',
                    isFull ? AppTheme.minproffGreen : AppTheme.warningOrange),
                _badge(family.vulnerabilityStatus ?? 'Normal', vulnColor),
                _badge('${phase.label}', Color(phase.colorValue)),
                if (family.hasLocation) _badge('GPS', AppTheme.unicefBlueSolid),
              ]),
              SizedBox(height: 10.h),

              // Detail rows
              if (family.phoneNumber != null && family.phoneNumber!.isNotEmpty)
                _detailRow(Icons.phone_outlined, family.phoneNumber!),
              if (family.lastVisitDate.isNotEmpty)
                _detailRow(Icons.calendar_today_outlined, 'Dernière visite : ${family.lastVisitDate}'),
              _detailRow(Icons.info_outline, phase.description),
              if (family.arrondissement != null)
                _detailRow(Icons.location_city_outlined,
                    [family.arrondissement, family.department, family.region]
                        .whereType<String>().join(', ')),
              if (family.hasLocation)
                _detailRow(Icons.location_on_outlined,
                    'Lat ${family.latitude!.toStringAsFixed(5)}  ·  Lng ${family.longitude!.toStringAsFixed(5)}'),

              SizedBox(height: 12.h),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => FormScreen(family: family))),
                  icon: Icon(Icons.edit_outlined, size: 16.sp),
                  label: Text('Ouvrir le dossier',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.unicefBlueSolid,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Divider between rows
        Divider(height: 1, thickness: 0.6, indent: 54.w, color: Colors.grey[200]),
      ],
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6.r),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: EdgeInsets.only(bottom: 5.h),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14.sp, color: Colors.grey[500]),
      SizedBox(width: 6.w),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]))),
    ]),
  );

  // ── Admin filter sheet ─────────────────────────────────────────────────────
  void _showAdminFilterSheet(AppState state) {
    String? tempRegion = _filterRegion;
    String? tempDept   = _filterDept;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final regions = CameroonAdmin.regions;
          final depts = tempRegion != null
              ? CameroonAdmin.departmentsFor(tempRegion!)
              : <String>[];
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40.w, height: 4.h,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r)))),
              SizedBox(height: 16.h),
              Text('Filtrer par zone',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              GlassDropdown<String>(
                value: tempRegion,
                hint: 'Toutes les régions',
                icon: Icons.map_outlined,
                items: regions.map((r) => DropdownMenuItem(
                    value: r, child: Text(r, style: TextStyle(fontSize: 13.sp)))).toList(),
                onChanged: (v) => setLocal(() { tempRegion = v; tempDept = null; }),
              ),
              SizedBox(height: 10.h),
              GlassDropdown<String>(
                value: tempDept,
                hint: tempRegion == null ? "Choisir la région d'abord" : 'Tous les départements',
                icon: Icons.account_balance_outlined,
                items: depts.map((d) => DropdownMenuItem(
                    value: d, child: Text(d, style: TextStyle(fontSize: 13.sp)))).toList(),
                onChanged: depts.isEmpty ? null : (v) => setLocal(() => tempDept = v),
              ),
              SizedBox(height: 20.h),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    setState(() { _filterRegion = null; _filterDept = null; });
                    Navigator.pop(ctx);
                  },
                  child: Text('Réinitialiser', style: TextStyle(fontSize: 13.sp)),
                )),
                SizedBox(width: 12.w),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () {
                    setState(() { _filterRegion = tempRegion; _filterDept = tempDept; });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.unicefBlueSolid, foregroundColor: Colors.white),
                  child: Text('Appliquer',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                )),
              ]),
            ]),
          );
        },
      ),
    );
  }

  void _showAddFamilySheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFamilySheet(appState: state),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add Family bottom sheet
// ══════════════════════════════════════════════════════════════════════════════
class _AddFamilySheet extends StatefulWidget {
  final AppState appState;
  const _AddFamilySheet({required this.appState});
  @override
  State<_AddFamilySheet> createState() => _AddFamilySheetState();
}

class _AddFamilySheetState extends State<_AddFamilySheet> {
  final _formKey = GlobalKey<FormState>();

  String _householdName       = '';
  String _neighborhood        = '';
  int    _childrenCount       = 0;
  String _phoneNumber         = '';
  String _vulnerabilityStatus = 'Normal';

  Position? _capturedPosition;
  bool      _gpsLoading = false;
  String?   _gpsError;

  String? _region;
  String? _department;
  String? _arrondissement;

  Color _vulnColor(String? s) {
    switch (s) {
      case 'Urgence': return AppTheme.alertRed;
      case 'Élevé':   return AppTheme.warningOrange;
      default:        return AppTheme.minproffGreen;
    }
  }

  Future<void> _captureGps() async {
    setState(() { _gpsLoading = true; _gpsError = null; });
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      setState(() {
        _capturedPosition = pos;
        _gpsLoading = false;
        if (pos == null) _gpsError = 'GPS indisponible. Position non enregistrée.';
      });
    } catch (_) {
      setState(() { _gpsLoading = false; _gpsError = 'Erreur GPS. Veuillez réessayer.'; });
    }
  }

  @override
  void initState() {
    super.initState();
    _captureGps();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      decoration: BoxDecoration(
        color: state.isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: state.isHighContrast ? Border.all(color: Colors.yellow, width: 2) : null,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r)),
              )),
              SizedBox(height: 16.h),
              Row(children: [
                Icon(Icons.family_restroom, color: AppTheme.unicefBlueSolid, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(child: Text('Ajouter une Nouvelle Famille',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold,
                      color: state.isHighContrast ? Colors.yellow : Colors.black87),
                  overflow: TextOverflow.ellipsis)),
              ]),
              SizedBox(height: 20.h),
              GlassField(
                hint: 'Nom du chef de ménage', icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                onSaved: (v) => _householdName = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassField(
                hint: 'Quartier / Village', icon: Icons.place_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Quartier requis' : null,
                onSaved: (v) => _neighborhood = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassField(
                hint: "Nombre d'enfants", icon: Icons.child_care,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nombre requis';
                  if ((int.tryParse(v) ?? -1) < 0) return 'Nombre invalide';
                  return null;
                },
                onSaved: (v) => _childrenCount = int.tryParse(v ?? '0') ?? 0,
              ),
              SizedBox(height: 12.h),
              GlassField(
                hint: 'Téléphone du ménage', icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]'))],
                isRequired: false,
                onSaved: (v) => _phoneNumber = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassDropdown<String>(
                value: _vulnerabilityStatus,
                hint: 'Statut de vulnérabilité',
                icon: Icons.shield_outlined,
                items: ['Normal', 'Élevé', 'Urgence'].map((o) => DropdownMenuItem(
                  value: o,
                  child: Row(children: [
                    Icon(Icons.circle, size: 10.sp, color: _vulnColor(o)),
                    SizedBox(width: 8.w),
                    Text(o, style: TextStyle(fontSize: 13.sp)),
                  ]),
                )).toList(),
                onChanged: (v) => setState(() => _vulnerabilityStatus = v ?? 'Normal'),
              ),
              SizedBox(height: 12.h),
              _buildGpsWidget(),
              SizedBox(height: 12.h),
              CameroonLocationPicker(
                onChanged: (r, d, a) {
                  _region = r; _department = d; _arrondissement = a;
                },
              ),
              SizedBox(height: 24.h),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text('Annuler', style: TextStyle(fontSize: 14.sp)),
                )),
                SizedBox(width: 12.w),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  onPressed: _saveFamily,
                  icon: Icon(Icons.save_outlined, size: 18.sp),
                  label: Text('ENREGISTRER',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.minproffGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsWidget() {
    if (_gpsLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppTheme.unicefBlueSolid.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppTheme.unicefBlueSolid.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          SizedBox(width: 18.w, height: 18.h,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.unicefBlueSolid)),
          SizedBox(width: 12.w),
          Expanded(child: Text('📍 Capture GPS en cours...',
              style: TextStyle(fontSize: 13.sp, color: AppTheme.unicefBlueSolid,
                  fontWeight: FontWeight.w500))),
        ]),
      );
    }
    if (_capturedPosition != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppTheme.minproffGreen.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppTheme.minproffGreen.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.location_on, color: AppTheme.minproffGreen, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🟢 GPS Capturé',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold,
                    color: AppTheme.minproffGreen)),
            SizedBox(height: 2.h),
            Text(
                'Lat ${_capturedPosition!.latitude.toStringAsFixed(5)}  ·  Lng ${_capturedPosition!.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis),
          ])),
          IconButton(
            onPressed: _captureGps,
            icon: Icon(Icons.refresh, size: 18.sp, color: AppTheme.minproffGreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      );
    }
    return GestureDetector(
      onTap: _captureGps,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color: _gpsError != null
                  ? AppTheme.warningOrange.withValues(alpha: 0.5)
                  : Colors.grey[300]!),
        ),
        child: Row(children: [
          Icon(Icons.location_searching, size: 20.sp,
              color: _gpsError != null ? AppTheme.warningOrange : Colors.grey[500]),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_gpsError != null
                ? '⚠️ GPS non disponible'
                : '📍 Obtenir la localisation actuelle',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500,
                    color: _gpsError != null
                        ? AppTheme.warningOrange
                        : AppTheme.unicefBlueSolid)),
            if (_gpsError != null) ...[
              SizedBox(height: 2.h),
              Text('Appuyez pour réessayer',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
            ],
          ])),
          Icon(Icons.chevron_right, size: 18.sp, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  void _saveFamily() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.appState.addFamilyWithCoords(
      _householdName, _neighborhood, _childrenCount,
      phoneNumber: _phoneNumber.isEmpty ? null : _phoneNumber,
      vulnerabilityStatus: _vulnerabilityStatus,
      latitude: _capturedPosition?.latitude,
      longitude: _capturedPosition?.longitude,
      region: _region, department: _department, arrondissement: _arrondissement,
    );
    Navigator.pop(context);
  }
}
