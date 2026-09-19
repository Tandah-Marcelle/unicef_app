import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../providers/app_state.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = '';

  String _t(String key) {
    final state = Provider.of<AppState>(context, listen: false);
    return LocalizationService.translate(key, state.currentLocale);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  List<String> _categories() => [
        _t('risk_physical_abuse'),
        _t('risk_marriage'),
        _t('risk_neglect'),
        _t('risk_sexual'),
      ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final categories = _categories();
    if (_selectedCategory.isEmpty || !categories.contains(_selectedCategory)) {
      _selectedCategory = categories[0];
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appState.isHighContrast ? Colors.black : AppTheme.alertRed,
        title: Text(
          _t('emergency_alerts'),
          style: TextStyle(fontSize: 16.sp),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWarningHeader(appState),
            SizedBox(height: 12.h),
            _buildFormCard(appState, categories),
            SizedBox(height: 16.h),
            _buildSubmittedHeader(appState),
            SizedBox(height: 8.h),
            ...appState.alerts.map((a) => _buildAlertCard(appState, a)),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  // ── Warning header ────────────────────────────────────────────────────────
  Widget _buildWarningHeader(AppState state) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: state.isHighContrast
            ? Colors.black
            : AppTheme.alertRed.withValues(alpha: 0.07),
        border: Border.all(
          color: state.isHighContrast ? Colors.yellow : AppTheme.alertRed,
          width: state.isHighContrast ? 3.0 : 2.0,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              color: state.isHighContrast ? Colors.yellow : AppTheme.alertRed,
              size: 32.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'SIGNALEMENT CONFIDENTIEL : Ce système génère des alertes de télémétrie de priorité directe '
              'destinées à alerter instantanément les agents de protection sociale lors de la détection réseau.',
              style: TextStyle(
                color: state.isHighContrast ? Colors.yellow : AppTheme.alertRed,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ─────────────────────────────────────────────────────────────
  Widget _buildFormCard(AppState state, List<String> categories) {
    return Card(
      elevation: state.isHighContrast ? 0 : 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Catégorie de risque
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _t('risk_category'),
                  labelStyle: TextStyle(fontSize: 13.sp),
                  prefixIcon: Icon(Icons.category_outlined, size: 20.sp),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                ),
                style: TextStyle(
                    fontSize: 13.sp,
                    color: state.isHighContrast ? Colors.white : Colors.black),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.sp)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v ?? categories[0]),
              ),
              SizedBox(height: 14.h),

              // Description anonymisée
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: state.isHighContrast ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: _t('description_label'),
                  labelStyle: TextStyle(fontSize: 13.sp),
                  hintText: 'Décrivez la situation sans mentionner de noms...',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  enabledBorder: state.isHighContrast
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              const BorderSide(color: Colors.yellow, width: 2.5))
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Description requise' : null,
              ),

              SizedBox(height: 20.h),

              // Submit button
              SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Provider.of<AppState>(context, listen: false).addAlert(
                        riskCategory: _selectedCategory,
                        description: _descController.text.trim(),
                      );
                      _descController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: AppTheme.alertRed,
                        content: Text(
                          'Alerte enregistrée et chiffrée localement.',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ));
                    }
                  },
                  icon: Icon(Icons.warning_amber_rounded, size: 20.sp),
                  label: Text(
                    _t('report_urgent'),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.alertRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submitted header ──────────────────────────────────────────────────────
  Widget _buildSubmittedHeader(AppState state) {
    return Row(children: [
      Icon(Icons.history, size: 18.sp, color: AppTheme.alertRed),
      SizedBox(width: 8.w),
      Expanded(
        child: Text(
          'Signalements soumis (${state.alerts.length})',
          style:
              TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  // ── Alert card ────────────────────────────────────────────────────────────
  Widget _buildAlertCard(AppState state, Alert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: state.isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: state.isHighContrast
              ? Colors.yellow
              : AppTheme.alertRed.withValues(alpha: 0.25),
          width: state.isHighContrast ? 2 : 1,
        ),
        boxShadow: state.isHighContrast
            ? null
            : [
                BoxShadow(
                    color: AppTheme.alertRed.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk category + sync icon
            Row(children: [
              Expanded(
                child: Text(
                  alert.riskCategory,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: state.isHighContrast ? Colors.yellow : AppTheme.alertRed,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                alert.isSynced == 1 ? Icons.cloud_done : Icons.sync_problem,
                size: 18.sp,
                color: alert.isSynced == 1
                    ? Colors.green
                    : (state.isHighContrast ? Colors.yellow : AppTheme.warningOrange),
              ),
            ]),
            SizedBox(height: 6.h),

            // Date + GPS badges
            Wrap(spacing: 8.w, runSpacing: 4.h, children: [
              _infoBadge(
                Icons.calendar_today_outlined,
                alert.incidentDate,
                Colors.grey[600]!,
              ),
              // GPS badge — green if coordinates stored, grey if not
              _infoBadge(
                alert.hasLocation ? Icons.location_on : Icons.location_off,
                alert.hasLocation
                    ? '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}'
                    : 'Non géolocalisé',
                alert.hasLocation ? AppTheme.minproffGreen : Colors.grey[400]!,
              ),
              // Priority badge
              _infoBadge(
                Icons.priority_high,
                'Priorité Rouge',
                AppTheme.alertRed,
              ),
            ]),

            SizedBox(height: 8.h),
            Divider(height: 1, color: AppTheme.alertRed.withValues(alpha: 0.15)),
            SizedBox(height: 8.h),

            // Description
            Text(
              alert.anonymizedDescription,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: state.isHighContrast ? Colors.white70 : Colors.grey[700],
                  height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 4.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 160.w),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10.sp, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
