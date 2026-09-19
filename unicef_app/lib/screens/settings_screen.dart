import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHc = appState.isHighContrast;

    return Scaffold(
      backgroundColor: isHc ? Colors.black : null,
      appBar: AppBar(
        title: Text('Paramètres', style: TextStyle(fontSize: 17.sp)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          // ── PROFILE HEADER ───────────────────────────────────────
          _ProfileHeader(appState: appState)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1),

          SizedBox(height: 24.h),

          // ── ACCESSIBILITY ────────────────────────────────────────
          _sectionHeader('🎨  Accessibilité', isHc)
              .animate().fadeIn(delay: 100.ms),
          SizedBox(height: 8.h),
          _buildCard(isHc: isHc, children: [
            _switchTile(
              icon: Icons.contrast,
              title: 'Mode Contraste Élevé',
              subtitle: 'Fond noir avec contours jaunes',
              value: appState.isHighContrast,
              onChanged: (_) => appState.toggleHighContrast(),
              isHc: isHc,
            ),
            _divider(isHc),
            _switchTile(
              icon: Icons.record_voice_over,
              title: 'Synthèse Vocale (TTS)',
              subtitle: 'Lire les étiquettes à voix haute',
              value: appState.isTtsEnabled,
              onChanged: (_) => appState.toggleTts(),
              isHc: isHc,
            ),
            _divider(isHc),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.format_size, size: 20.sp,
                        color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
                    SizedBox(width: 12.w),
                    Text('Taille de Police',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: isHc ? Colors.white : null)),
                    SizedBox(width: 8.w),
                    Text('${(appState.fontScale * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: isHc ? Colors.yellow : Colors.grey[600])),
                  ]),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isHc ? Colors.yellow : AppTheme.unicefBlueSolid,
                      thumbColor: isHc ? Colors.yellow : AppTheme.unicefBlueSolid,
                      inactiveTrackColor: isHc ? Colors.grey[800] : Colors.grey[300],
                      overlayColor: isHc
                          ? Colors.yellow.withValues(alpha: 0.15)
                          : AppTheme.unicefBlueSolid.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: appState.fontScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      label: '${(appState.fontScale * 100).round()}%',
                      onChanged: appState.setFontScale,
                    ),
                  ),
                ],
              ),
            ),
          ]).animate().fadeIn(delay: 150.ms),

          SizedBox(height: 20.h),

          // ── LANGUAGE ─────────────────────────────────────────────
          _sectionHeader('🌐  Langue', isHc)
              .animate().fadeIn(delay: 250.ms),
          SizedBox(height: 8.h),
          _buildCard(isHc: isHc, children: [
            for (final locale in [
              ('en', '🇬🇧', 'English'),
              ('fr', '🇫🇷', 'Français'),
              ('pcm', '🇨🇲', 'Cameroon Pidgin'),
            ])
              RadioListTile<String>(
                value: locale.$1,
                groupValue: appState.currentLocale,
                onChanged: (v) => appState.changeLocale(v ?? 'fr'),
                activeColor: isHc ? Colors.yellow : AppTheme.unicefBlueSolid,
                title: Text(
                  '${locale.$2}  ${locale.$3}',
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: isHc ? Colors.white : null),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
          ]).animate().fadeIn(delay: 300.ms),

          SizedBox(height: 20.h),

          // ── APP INFO ──────────────────────────────────────────────
          _sectionHeader('ℹ️  À Propos', isHc)
              .animate().fadeIn(delay: 400.ms),
          SizedBox(height: 8.h),
          _buildCard(isHc: isHc, children: [
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid,
                  size: 22.sp),
              title: Text('ComMobi-Tracker v1.0.0',
                  style: TextStyle(
                      fontSize: 14.sp, color: isHc ? Colors.white : null)),
              subtitle: Text('MINPROFF / UNICEF Cameroun',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: isHc ? Colors.grey[400] : null)),
            ),
            _divider(isHc),
            ListTile(
              leading: Icon(Icons.lock_outline,
                  color: isHc ? Colors.yellow : AppTheme.minproffGreen,
                  size: 22.sp),
              title: Text('Chiffrement Local Actif',
                  style: TextStyle(
                      fontSize: 14.sp, color: isHc ? Colors.white : null)),
              subtitle: Text('Données hors ligne sécurisées',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: isHc ? Colors.grey[400] : null)),
              trailing: Icon(Icons.check_circle,
                  color: isHc ? Colors.yellow : AppTheme.minproffGreen,
                  size: 18.sp),
            ),
          ]).animate().fadeIn(delay: 450.ms),

          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isHc) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
    );
  }

  static Widget _divider(bool isHc) => Divider(
      height: 1, color: isHc ? Colors.yellow.withValues(alpha: 0.3) : null);

  static Widget _buildCard({required bool isHc, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isHc ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHc ? Border.all(color: Colors.yellow, width: 1.5) : null,
        boxShadow: isHc
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(children: children),
    );
  }

  static Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isHc,
  }) {
    return SwitchListTile(
      secondary: Icon(icon,
          size: 22.sp, color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
      title: Text(title,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isHc ? Colors.white : null)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 11.sp,
              color: isHc ? Colors.grey[400] : null),
          overflow: TextOverflow.ellipsis),
      value: value,
      onChanged: onChanged,
      activeColor: isHc ? Colors.yellow : AppTheme.unicefBlueSolid,
      inactiveThumbColor: isHc ? Colors.grey[600] : null,
      inactiveTrackColor: isHc ? Colors.grey[800] : null,
    );
  }
}

// ── PROFILE HEADER WIDGET ────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final AppState appState;
  const _ProfileHeader({required this.appState});

  @override
  Widget build(BuildContext context) {
    final profile = appState.userProfile;
    final String fullName = profile?['fullName'] ?? 'Field Facilitator';
    final String role = profile?['role'] ?? 'Facilitator';
    final String facilitatorId = profile?['facilitatorId'] ?? '—';
    final String region = profile?['region'] ?? '—';
    final String district = profile?['district'] ?? '—';
    final String? imagePath = profile?['profileImagePath'];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.unicefBlueSolid, AppTheme.unicefBlueSolid.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          // Avatar + camera overlay
          _AvatarUpload(imagePath: imagePath, appState: appState),
          SizedBox(height: 12.h),

          // Name
          Text(
            fullName,
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Role badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              role,
              style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),

          SizedBox(height: 14.h),

          // Profile details grid — Flexible on each cell prevents overflow
          Row(
            children: [
              _profileField('ID', facilitatorId),
              _vDivider(),
              _profileField('Region', region),
              _vDivider(),
              _profileField('District', district),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.white60),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    height: 32.h,
    width: 1,
    color: Colors.white.withValues(alpha: 0.25),
    margin: EdgeInsets.symmetric(horizontal: 4.w),
  );
}

// ── AVATAR UPLOAD ────────────────────────────────────────────────────────────
class _AvatarUpload extends StatefulWidget {
  final String? imagePath;
  final AppState appState;
  const _AvatarUpload({required this.imagePath, required this.appState});

  @override
  State<_AvatarUpload> createState() => _AvatarUploadState();
}

class _AvatarUploadState extends State<_AvatarUpload> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await widget.appState.updateProfileImage(image.path);
      }
    } catch (_) {}
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('Update Profile Photo', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.unicefBlueSolid, size: 22.sp),
              title: Text('📸  Take a Photo', style: TextStyle(fontSize: 14.sp)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.minproffGreen, size: 22.sp),
              title: Text('🖼️  Choose from Gallery', style: TextStyle(fontSize: 14.sp)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.appState.userProfile?['profileImagePath'];

    return GestureDetector(
      onTap: _showSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 42.r,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: path != null && File(path).existsSync()
                ? FileImage(File(path))
                : null,
            child: path == null || !File(path).existsSync()
                ? Icon(Icons.person, size: 44.sp, color: Colors.white)
                : null,
          ),
          // Camera overlay badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28.w,
              height: 28.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.unicefBlueSolid, width: 1.5),
              ),
              child: Icon(Icons.camera_alt, size: 15.sp, color: AppTheme.unicefBlueSolid),
            ),
          ),
        ],
      ),
    );
  }
}
