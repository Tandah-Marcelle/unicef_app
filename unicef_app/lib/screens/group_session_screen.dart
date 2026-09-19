import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/group_session.dart';
import '../providers/app_state.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_field.dart';

class GroupSessionScreen extends StatefulWidget {
  const GroupSessionScreen({super.key});

  @override
  State<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends State<GroupSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  int _menCount = 0;
  int _womenCount = 0;
  String _selectedTopic = 'Module 1: Rights & Birth Registration';
  final List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();

  static const int _maxPhotos = 3;

  final List<String> _topicsList = const [
    'Module 1: Rights & Birth Registration',
    'Module 2: Community Role & Best Interests',
    'Module 3: First 1,000 Days (Maternal Health)',
    'Module 4: WASH (Water, Sanitation, Hygiene)',
    'Module 5: Family Financial Budgeting',
    'Module 6: Positive Discipline (Alternative to Violence)',
    'Module 7: Child Growth Development & Care',
    'Module 8: Conflict Management in the Household',
    'Module 9: Girls Education & Prevention of Early Marriage',
    'Module 10: Parent-Child Dialogue and Feedback',
  ];

  String _t(String key) {
    final state = Provider.of<AppState>(context, listen: false);
    return LocalizationService.translate(key, state.currentLocale);
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double get _masculinityIndex {
    final total = _menCount + _womenCount;
    if (total == 0) return 0.0;
    return (_menCount / total) * 100;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photoPaths.length >= _maxPhotos) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _photoPaths.add(image.path));
      }
    } catch (_) {}
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.unicefBlueSolid, size: 22.sp),
              title: Text('Take a Photo', style: TextStyle(fontSize: 14.sp)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.minproffGreen, size: 22.sp),
              title: Text('Choose from Gallery', style: TextStyle(fontSize: 14.sp)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSession(AppState state) {
    if (!_formKey.currentState!.validate()) return;
    state.addGroupSession(
      location: _locationController.text.trim(),
      men: _menCount,
      women: _womenCount,
      topic: _selectedTopic,
      date: _dateController.text,
      photoPaths: _photoPaths.isNotEmpty ? List.from(_photoPaths) : null,
    );
    _locationController.clear();
    setState(() {
      _menCount = 0;
      _womenCount = 0;
      _photoPaths.clear();
      _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.minproffGreen,
        content: Text(_t('save_success'), style: TextStyle(fontSize: 13.sp)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('group_sessions'), style: TextStyle(fontSize: 16.sp), overflow: TextOverflow.ellipsis),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoBanner(appState),
            SizedBox(height: 16.h),
            _buildFormCard(appState),
            SizedBox(height: 20.h),
            _buildSessionsHeader(appState),
            SizedBox(height: 8.h),
            ...appState.sessions.map((s) => _buildSessionCard(appState, s)),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  // ── INFO BANNER ─────────────────────────────────────────────────────────────
  Widget _buildInfoBanner(AppState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.unicefBlueSolid.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.unicefBlueSolid.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.unicefBlueSolid, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Log community workshops held with local parents to track participation and positive masculinity engagement.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM CARD ────────────────────────────────────────────────────────────────
  Widget _buildFormCard(AppState state) {
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
              Text(
                _t('report_title'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: state.isHighContrast ? Colors.yellow : AppTheme.minproffGreen,
                ),
              ),

              SizedBox(height: 16.h),

              // Date Picker
              _buildDateCard(state),
              SizedBox(height: 12.h),

              // Location — glass style
              GlassField(
                controller: _locationController,
                hint: _t('location'),
                icon: Icons.place_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Lieu requis' : null,
              ),
              SizedBox(height: 12.h),

              // Topic Dropdown — glass style
              GlassDropdown<String>(
                value: _selectedTopic,
                hint: _t('topic_covered'),
                icon: Icons.menu_book_outlined,
                items: _topicsList
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontSize: 13.sp)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTopic = v ?? _topicsList[0]),
              ),
              SizedBox(height: 16.h),

              // Attendance Counters
              Row(
                children: [
                  Expanded(child: _buildAttendanceCounter(
                    state,
                    label: _t('men_count'),
                    icon: Icons.male,
                    iconColor: const Color(0xFF1976D2),
                    value: _menCount,
                    onUpdate: (v) => setState(() => _menCount = v),
                  )),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildAttendanceCounter(
                    state,
                    label: _t('women_count'),
                    icon: Icons.female,
                    iconColor: const Color(0xFFE91E8C),
                    value: _womenCount,
                    onUpdate: (v) => setState(() => _womenCount = v),
                  )),
                ],
              ),
              SizedBox(height: 16.h),

              // Masculinity Index Gauge
              _buildMasculinityGauge(state),
              SizedBox(height: 16.h),

              // Photo Proof Section
              _buildPhotoSection(state),
              SizedBox(height: 20.h),

              // Save Button
              SizedBox(
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () => _saveSession(state),
                  icon: Icon(Icons.save_outlined, size: 20.sp),
                  label: Text(
                    _t('save_offline'),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.minproffGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(AppState state) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => _dateController.text = picked.toIso8601String().substring(0, 10));
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 20.sp, color: AppTheme.unicefBlueSolid),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('date'),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
              SizedBox(height: 2.h),
              Text(_dateController.text,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
            ]),
          ),
          Icon(Icons.edit_calendar_outlined, size: 18.sp, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _buildAttendanceCounter(
    AppState state, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required int value,
    required ValueChanged<int> onUpdate,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: state.isHighContrast ? Colors.black : Colors.grey[50],
        border: Border.all(
          color: state.isHighContrast ? Colors.yellow : Colors.grey[300]!,
          width: state.isHighContrast ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: iconColor),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: state.isHighContrast ? Colors.yellow : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: value > 0 ? () => onUpdate(value - 1) : null,
                icon: Icon(Icons.remove_circle_outline, size: 28.sp),
                color: state.isHighContrast ? Colors.yellow : AppTheme.alertRed,
                constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
                padding: EdgeInsets.zero,
              ),
              Text(
                '$value',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => onUpdate(value + 1),
                icon: Icon(Icons.add_circle_outline, size: 28.sp),
                color: state.isHighContrast ? Colors.yellow : AppTheme.minproffGreen,
                constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasculinityGauge(AppState state) {
    final index = _masculinityIndex;
    final total = _menCount + _womenCount;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: state.isHighContrast
            ? Colors.black
            : AppTheme.unicefBlueSolid.withValues(alpha: 0.05),
        border: Border.all(
          color: state.isHighContrast ? Colors.yellow : AppTheme.unicefBlueSolid.withValues(alpha: 0.4),
          width: state.isHighContrast ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _t('masculinity_index'),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: state.isHighContrast ? Colors.yellow : AppTheme.unicefBlueSolid,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: state.isHighContrast
                      ? Colors.yellow.withValues(alpha: 0.15)
                      : AppTheme.unicefBlueSolid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${index.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: state.isHighContrast ? Colors.yellow : AppTheme.unicefBlueSolid,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _t('masculinity_desc'),
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.0 : _menCount / total,
              minHeight: 12.h,
              color: state.isHighContrast ? Colors.yellow : AppTheme.minproffGreen,
              backgroundColor: state.isHighContrast ? Colors.grey[900] : Colors.grey[200],
            ),
          ),
          SizedBox(height: 6.h),
          // Male / Female legend — use Row with Flexible to prevent overflow
          Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10.w, height: 10.h, decoration: BoxDecoration(color: AppTheme.minproffGreen, borderRadius: BorderRadius.circular(2.r))),
                    SizedBox(width: 4.w),
                    Flexible(child: Text('Men ($_menCount)', style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10.w, height: 10.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r))),
                    SizedBox(width: 4.w),
                    Flexible(child: Text('Women ($_womenCount)', style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Photo Proof (${_photoPaths.length}/$_maxPhotos)',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_photoPaths.length < _maxPhotos)
              TextButton.icon(
                onPressed: _showPhotoPickerSheet,
                icon: Icon(Icons.add_a_photo_outlined, size: 18.sp),
                label: Text('Add', style: TextStyle(fontSize: 12.sp)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.unicefBlueSolid),
              ),
          ],
        ),
        if (_photoPaths.isNotEmpty) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 90.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (_, i) => _buildPhotoThumb(_photoPaths[i], i),
            ),
          ),
        ] else ...[
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _showPhotoPickerSheet,
            child: Container(
              height: 70.h,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.grey[50],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 24.sp, color: Colors.grey[400]),
                    SizedBox(height: 4.h),
                    Text('Tap to add proof photos', style: TextStyle(fontSize: 11.sp, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoThumb(String path, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            File(path),
            width: 80.w,
            height: 90.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80.w, height: 90.h,
              color: Colors.grey[200],
              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24.sp),
            ),
          ),
        ),
        Positioned(
          top: 2.h,
          right: 2.w,
          child: GestureDetector(
            onTap: () => setState(() => _photoPaths.removeAt(index)),
            child: Container(
              width: 22.w, height: 22.h,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Icon(Icons.close, color: Colors.white, size: 14.sp),
            ),
          ),
        ),
      ],
    );
  }

  // ── SUBMITTED SESSIONS ───────────────────────────────────────────────────────
  Widget _buildSessionsHeader(AppState state) {
    return Row(
      children: [
        Icon(Icons.history, size: 18.sp, color: AppTheme.unicefBlueSolid),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Submitted Reports (${state.sessions.length})',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(AppState state, GroupSession session) {
    final List<String> photos = session.photoProofPaths != null
        ? List<String>.from(jsonDecode(session.photoProofPaths!))
        : [];

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: state.isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: state.isHighContrast ? Colors.yellow : Colors.grey[200]!,
          width: state.isHighContrast ? 2 : 1,
        ),
        boxShadow: state.isHighContrast
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic + sync icon — Expanded prevents overflow
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.topicCovered,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  session.isSynced == 1 ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  size: 18.sp,
                  color: session.isSynced == 1 ? Colors.green : Colors.grey[400],
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Date & Location — wrapped safely
            Wrap(
              spacing: 12.w,
              runSpacing: 4.h,
              children: [
                _infoChip(Icons.calendar_today_outlined, session.sessionDate, Colors.grey[600]!),
                _infoChip(Icons.place_outlined, session.location, Colors.grey[600]!),
              ],
            ),
            SizedBox(height: 8.h),

            // Attendance badges — Wrap prevents row overflow
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _attendanceBadge(Icons.male, '${session.menAttendance}', const Color(0xFF1976D2)),
                _attendanceBadge(Icons.female, '${session.womenAttendance}', const Color(0xFFE91E8C)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppTheme.unicefBlueSolid.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.unicefBlueSolid.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'PMI: ${session.positiveMasculinityIndex.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppTheme.unicefBlueSolid),
                  ),
                ),
                // GPS badge
                if (session.hasLocation)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppTheme.minproffGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.minproffGreen.withValues(alpha: 0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on, size: 11.sp, color: AppTheme.minproffGreen),
                      SizedBox(width: 3.w),
                      Text('GPS',
                          style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.minproffGreen)),
                    ]),
                  ),
              ],
            ),

            // Photo thumbnails if any
            if (photos.isNotEmpty) ...[
              SizedBox(height: 10.h),
              SizedBox(
                height: 60.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6.w),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.file(
                      File(photos[i]),
                      width: 60.w,
                      height: 60.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60.w, height: 60.h, color: Colors.grey[200],
                        child: Icon(Icons.broken_image_outlined, size: 20.sp, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 4.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 140.w),
          child: Text(label, style: TextStyle(fontSize: 12.sp, color: color), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _attendanceBadge(IconData icon, String count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(count, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
