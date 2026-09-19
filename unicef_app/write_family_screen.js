const fs = require('fs');

const dart = `import 'package:flutter/material.dart';
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

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  FollowUpPhase? _phaseFilter;
  String? _filterRegion;
  String? _filterDept;

  String _t(String key) {
    final state = Provider.of<AppState>(context, listen: false);
    return LocalizationService.translate(key, state.currentLocale);
  }

  Color _vulnColor(String? s) {
    switch (s) {
      case 'Urgence': return AppTheme.alertRed;
      case '\u00c9lev\u00e9': return AppTheme.warningOrange;
      default: return AppTheme.minproffGreen;
    }
  }

  Color _phaseColor(FollowUpPhase p) => Color(p.colorValue);

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<Family> _applyFilters(List<Family> families) {
    var list = families;
    if (_phaseFilter != null) list = list.where((f) => f.followUpPhase == _phaseFilter).toList();
    if (_filterRegion != null) list = list.where((f) => f.region == _filterRegion).toList();
    if (_filterDept != null) list = list.where((f) => f.department == _filterDept).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState  = Provider.of<AppState>(context);
    final displayed = _applyFilters(appState.families);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_t('my_families'), style: TextStyle(fontSize: 17.sp), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, size: 22.sp,
              color: (_filterRegion != null || _filterDept != null) ? Colors.yellowAccent : Colors.white),
            tooltip: 'Filtrer par zone',
            onPressed: () => _showAdminFilterSheet(appState),
          ),
        ],
      ),
      body: Column(children: [
        _buildSearchBar(appState),
        _buildStatsRow(appState),
        _buildPhaseFilterBar(),
        Expanded(
          child: displayed.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  itemCount: displayed.length,
                  itemBuilder: (ctx, i) => _buildFamilyCard(ctx, displayed[i], appState),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFamilySheet(context, appState),
        icon: const Icon(Icons.add),
        label: Text('Nouvelle Famille', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar(AppState appState) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
      child: TextField(
        controller: _searchController,
        onChanged: appState.updateSearchQuery,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey[600]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18.sp),
                  onPressed: () { _searchController.clear(); appState.updateSearchQuery(''); })
              : null,
          hintText: _t('search_placeholder'),
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppTheme.unicefBlueSolid, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppState state) {
    final total      = state.families.length;
    final fullFollow = state.families.where((f) => f.status == 'Full Follow-up').length;
    final urgent     = state.families.where((f) => f.vulnerabilityStatus == 'Urgence').length;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.unicefBlueSolid.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.unicefBlueSolid.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        _statPill(Icons.people_outline, '\${total}', 'Total', AppTheme.unicefBlueSolid),
        _vDivider(),
        _statPill(Icons.check_circle_outline, '\${fullFollow}', 'Suivi complet', AppTheme.minproffGreen),
        _vDivider(),
        _statPill(Icons.warning_amber_outlined, '\${urgent}', 'Urgence', AppTheme.alertRed),
      ]),
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) {
    return Expanded(child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: color)),
      ]),
      SizedBox(height: 2.h),
      Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
    ]));
  }

  Widget _vDivider() => Container(
    width: 1, height: 30.h, color: Colors.grey[300],
    margin: EdgeInsets.symmetric(horizontal: 4.w));

  Widget _buildPhaseFilterBar() {
    final phases = [null, ...FollowUpPhase.values];
    return SizedBox(
      height: 36.h,
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
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: active ? color : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: color, width: active ? 0 : 1),
                boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)] : null,
              ),
              child: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.family_restroom, size: 56.sp, color: Colors.grey[300]),
      SizedBox(height: 12.h),
      Text('Aucune famille trouv\u00e9e.', style: TextStyle(fontSize: 15.sp, color: Colors.grey[500])),
      SizedBox(height: 6.h),
      Text('Appuyez sur + pour enregistrer une famille.', style: TextStyle(fontSize: 12.sp, color: Colors.grey[400])),
    ]));
  }

  Widget _buildFamilyCard(BuildContext ctx, Family family, AppState appState) {
    final isFull    = family.status == 'Full Follow-up';
    final vulnColor = _vulnColor(family.vulnerabilityStatus);
    final phase     = family.followUpPhase;
    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => FormScreen(family: family))),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(family.householdName,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 8.w),
              _statusBadge(isFull, appState.isHighContrast),
            ]),
            SizedBox(height: 6.h),
            Wrap(spacing: 12.w, runSpacing: 4.h, children: [
              _infoChip(Icons.place_outlined, family.neighborhood),
              _infoChip(Icons.child_care, '\${family.childCount} enfant(s)'),
              if (family.lastVisitDate.isNotEmpty) _infoChip(Icons.calendar_today_outlined, family.lastVisitDate),
            ]),
            SizedBox(height: 6.h),
            Row(children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: vulnColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: vulnColor.withValues(alpha: 0.4)),
                ),
                child: Text(family.vulnerabilityStatus ?? 'Normal',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: vulnColor)),
              ),
              if (family.hasLocation) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppTheme.unicefBlueSolid.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppTheme.unicefBlueSolid.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on, size: 11.sp, color: AppTheme.unicefBlueSolid),
                    SizedBox(width: 3.w),
                    Text('GPS', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppTheme.unicefBlueSolid)),
                  ]),
                ),
              ],
              if (family.region != null) ...[
                SizedBox(width: 6.w),
                Flexible(child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(family.region!, style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                )),
              ],
            ]),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Color(phase.colorValue).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Color(phase.colorValue).withValues(alpha: 0.35)),
              ),
              child: Text('\${phase.label} \u00b7 \${phase.description}',
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Color(phase.colorValue)),
                overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isFull, bool isHighContrast) {
    final label = isFull ? 'Suivi Complet' : 'Suivi Partiel';
    final color = isFull ? AppTheme.minproffGreen : AppTheme.warningOrange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isHighContrast ? Colors.yellow : color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isHighContrast ? Colors.yellow : color)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13.sp, color: Colors.grey[500]),
      SizedBox(width: 3.w),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 130.w),
        child: Text(text, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

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
          final depts   = tempRegion != null ? CameroonAdmin.departmentsFor(tempRegion!) : <String>[];
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)))),
              SizedBox(height: 16.h),
              Text('Filtrer par zone', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              GlassDropdown<String>(
                value: tempRegion,
                hint: 'Toutes les r\u00e9gions',
                icon: Icons.map_outlined,
                items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 13.sp)))).toList(),
                onChanged: (v) => setLocal(() { tempRegion = v; tempDept = null; }),
              ),
              SizedBox(height: 10.h),
              GlassDropdown<String>(
                value: tempDept,
                hint: tempRegion == null ? "Choisir la r\u00e9gion d'abord" : 'Tous les d\u00e9partements',
                icon: Icons.account_balance_outlined,
                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 13.sp)))).toList(),
                onChanged: depts.isEmpty ? null : (v) => setLocal(() => tempDept = v),
              ),
              SizedBox(height: 20.h),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () { setState(() { _filterRegion = null; _filterDept = null; }); Navigator.pop(ctx); },
                  child: Text('R\u00e9initialiser', style: TextStyle(fontSize: 13.sp)),
                )),
                SizedBox(width: 12.w),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () { setState(() { _filterRegion = tempRegion; _filterDept = tempDept; }); Navigator.pop(ctx); },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.unicefBlueSolid, foregroundColor: Colors.white),
                  child: Text('Appliquer', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
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
      case '\u00c9lev\u00e9': return AppTheme.warningOrange;
      default: return AppTheme.minproffGreen;
    }
  }

  Future<void> _captureGps() async {
    setState(() { _gpsLoading = true; _gpsError = null; });
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      setState(() {
        _capturedPosition = pos;
        _gpsLoading = false;
        if (pos == null) _gpsError = 'GPS indisponible. Position non enregistr\u00e9e.';
      });
    } catch (_) {
      setState(() { _gpsLoading = false; _gpsError = 'Erreur GPS. Veuillez r\u00e9essayer.'; });
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
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
              )),
              SizedBox(height: 16.h),
              Row(children: [
                Icon(Icons.family_restroom, color: AppTheme.unicefBlueSolid, size: 22.sp),
                SizedBox(width: 8.w),
                Expanded(child: Text(
                  'Ajouter une Nouvelle Famille',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold,
                    color: state.isHighContrast ? Colors.yellow : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
              SizedBox(height: 20.h),
              GlassField(
                hint: 'Nom du chef de m\u00e9nage',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                onSaved: (v) => _householdName = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassField(
                hint: 'Quartier / Village',
                icon: Icons.place_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Quartier requis' : null,
                onSaved: (v) => _neighborhood = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassField(
                hint: "Nombre d'enfants",
                icon: Icons.child_care,
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
                hint: 'T\u00e9l\u00e9phone du m\u00e9nage',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\\s]'))],
                isRequired: false,
                onSaved: (v) => _phoneNumber = v ?? '',
              ),
              SizedBox(height: 12.h),
              GlassDropdown<String>(
                value: _vulnerabilityStatus,
                hint: 'Statut de vuln\u00e9rabilit\u00e9',
                icon: Icons.shield_outlined,
                items: ['Normal', '\u00c9lev\u00e9', 'Urgence'].map((o) => DropdownMenuItem(
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
                  _region         = r;
                  _department     = d;
                  _arrondissement = a;
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
                  label: Text('ENREGISTRER (HORS LIGNE)',
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
          Expanded(child: Text('\ud83d\udccd Capture de la position GPS en cours...',
            style: TextStyle(fontSize: 13.sp, color: AppTheme.unicefBlueSolid, fontWeight: FontWeight.w500))),
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
            Text('\ud83d\udfe2 GPS Captur\u00e9',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppTheme.minproffGreen)),
            SizedBox(height: 2.h),
            Text('Lat \${_capturedPosition!.latitude.toStringAsFixed(5)}  \u00b7  Lng \${_capturedPosition!.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
          ])),
          IconButton(
            onPressed: _captureGps,
            icon: Icon(Icons.refresh, size: 18.sp, color: AppTheme.minproffGreen),
            tooltip: 'Actualiser la position',
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
            color: _gpsError != null ? AppTheme.warningOrange.withValues(alpha: 0.5) : Colors.grey[300]!),
        ),
        child: Row(children: [
          Icon(Icons.location_searching, size: 20.sp,
            color: _gpsError != null ? AppTheme.warningOrange : Colors.grey[500]),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_gpsError != null ? '\u26a0\ufe0f GPS non disponible'
                : '\ud83d\udccd Position GPS : Obtenir la localisation actuelle',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500,
                color: _gpsError != null ? AppTheme.warningOrange : AppTheme.unicefBlueSolid)),
            if (_gpsError != null) ...[
              SizedBox(height: 2.h),
              Text('Appuyez pour r\u00e9essayer \u00b7 Famille enregistr\u00e9e sans coordonn\u00e9es',
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
      _householdName,
      _neighborhood,
      _childrenCount,
      phoneNumber: _phoneNumber.isEmpty ? null : _phoneNumber,
      vulnerabilityStatus: _vulnerabilityStatus,
      latitude: _capturedPosition?.latitude,
      longitude: _capturedPosition?.longitude,
      region: _region,
      department: _department,
      arrondissement: _arrondissement,
    );
    Navigator.pop(context);
  }
}
`;

fs.writeFileSync('lib/screens/family_list_screen.dart', dart, 'utf8');
console.log('SUCCESS: wrote', dart.length, 'chars,', dart.split('\n').length, 'lines');
