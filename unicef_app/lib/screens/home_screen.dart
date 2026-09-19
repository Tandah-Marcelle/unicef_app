import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselCtrl = PageController();
  int _carouselPage = 0;
  Timer? _carouselTimer;

  // Field photo carousel images — place pp1.jpg and pp2.JPG in assets/images/
  // to enable real field photos. Falls back to placeholder if files are missing.
  static const List<String> _carouselAssets = [
    'assets/images/pp1.jpeg',
    'assets/images/pp2.JPG',
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_carouselPage + 1) % _carouselAssets.length;
      _carouselCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  String _t(String key) {
    final state = Provider.of<AppState>(context, listen: false);
    return LocalizationService.translate(key, state.currentLocale);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: _buildAppBar(appState),
      body: RefreshIndicator(
        onRefresh: () => appState.synchronizeData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Facilitator profile card
              _buildProfileCard(appState)
                  .animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),
              SizedBox(height: 14.h),

              // Emergency safeguarding card
              _buildEmergencyCard(appState)
                  .animate().fadeIn(delay: 100.ms, duration: 500.ms),
              SizedBox(height: 16.h),

              // Section title
              Text(_t('statistics'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold))
                  .animate().fadeIn(delay: 200.ms),
              SizedBox(height: 10.h),

              // 2×2 compact stats grid
              _buildStatsGrid(appState),
              SizedBox(height: 16.h),

              // Photo carousel
              _buildPhotoCarousel()
                  .animate().fadeIn(delay: 500.ms),
              SizedBox(height: 16.h),

              // Sync card
              _buildSyncCard(appState)
                  .animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
              SizedBox(height: 14.h),

              // Map shortcut
              _buildMapShortcutCard(appState)
                  .animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
              SizedBox(height: 16.h),

              // Sync button
              SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: appState.isSyncing
                      ? null
                      : () => appState.synchronizeData(),
                  icon: appState.isSyncing
                      ? SizedBox(
                          width: 18.w, height: 18.h,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(Icons.cloud_upload_outlined, size: 20.sp),
                  label: Text('SYNCHRONISER VERS POWER BI',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.unicefBlueSolid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppState state) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(children: [
        Image.asset('assets/images/unicef_logo.png',
            height: 26.h,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.apartment, size: 20.sp, color: Colors.white)),
        SizedBox(width: 8.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ComMobi-Tracker',
                  style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text('Pour chaque enfant',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.85)),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
      actions: [
        IconButton(
          icon: Icon(Icons.record_voice_over, size: 22.sp),
          tooltip: 'Toggle TTS',
          onPressed: () => state.toggleTts(),
        ),
      ],
    );
  }

  // ── PROFILE CARD ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard(AppState state) {
    final profile   = state.userProfile;
    final name      = profile?['fullName']         ?? 'Field Facilitator';
    final role      = profile?['role']             ?? 'Facilitator';
    final region    = profile?['region']           ?? '';
    final district  = profile?['district']         ?? '';
    final imagePath = profile?['profileImagePath'] as String?;
    final hasPhoto  = imagePath != null && File(imagePath).existsSync();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.unicefBlueSolid,
            AppTheme.unicefBlueSolid.withValues(alpha: 0.75)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26.r,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          backgroundImage: hasPhoto ? FileImage(File(imagePath)) : null,
          child: hasPhoto
              ? null
              : Icon(Icons.person, color: Colors.white, size: 28.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            Text(role,
                style:
                    TextStyle(color: Colors.white70, fontSize: 11.sp),
                overflow: TextOverflow.ellipsis),
            if (region.isNotEmpty || district.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                [
                  if (region.isNotEmpty) region,
                  if (district.isNotEmpty) district
                ].join(' · '),
                style: TextStyle(color: Colors.white60, fontSize: 10.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ]),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: state.isLastSyncSuccessful ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                state.isLastSyncSuccessful
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: Colors.white,
                size: 12.sp),
            SizedBox(width: 4.w),
            Text(
              state.isLastSyncSuccessful ? 'En ligne' : 'Hors ligne',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── EMERGENCY CARD ───────────────────────────────────────────────────────────
  Widget _buildEmergencyCard(AppState state) {
    return GestureDetector(
      onTap: () => _showEmergencyModal(state),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.alertRed, const Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.alertRed.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(children: [
          Icon(Icons.shield, color: Colors.white, size: 32.sp)
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                  begin: 1.0,
                  end: 1.15,
                  duration: 900.ms,
                  curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.15, end: 1.0, duration: 900.ms),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SIGNALEMENT URGENT DE SAUVEGARDE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
              SizedBox(height: 3.h),
              Text('Appuyez pour signaler abus, mariage précoce ou exploitation',
                  style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ]),
          ),
          Icon(Icons.chevron_right, color: Colors.white70, size: 22.sp),
        ]),
      ),
    );
  }

  void _showEmergencyModal(AppState state) {
    final descCtrl = TextEditingController();
    String selected = 'Risque d\'abus physique';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          final cats = [
            'Risque d\'abus physique',
            'Risque de mariage d\'enfants',
            'Négligence grave',
            'Exploitation sexuelle'
          ];
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w,
                MediaQuery.of(ctx2).viewInsets.bottom + 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(
                child: Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Row(children: [
                Icon(Icons.shield, color: AppTheme.alertRed, size: 24.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text('Signalement d\'urgence',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.alertRed),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Catégorie de risque',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setS(() => selected = v ?? cats[0]),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description anonymisée',
                  hintText: 'Décrivez sans mentionner de noms...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 50.h,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (descCtrl.text.trim().isNotEmpty) {
                      state.addAlert(riskCategory: selected, description: descCtrl.text);
                      Navigator.pop(ctx2);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: AppTheme.alertRed,
                        content: Text('Alerte enregistrée localement.',
                            style: TextStyle(fontSize: 13.sp)),
                      ));
                    }
                  },
                  icon: Icon(Icons.warning_amber_rounded, size: 20.sp),
                  label: Text('SOUMETTRE LE SIGNALEMENT',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.alertRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── 2×2 STATS GRID ───────────────────────────────────────────────────────────
  Widget _buildStatsGrid(AppState state) {
    final families  = state.families.length;
    final assessed  = state.families.where((f) => f.lastVisitDate.isNotEmpty).length;
    final pending   = families - assessed;
    final mapped    = state.families.where((f) => f.hasLocation).length;
    final sessions  = state.sessions;
    final totalAtt  = sessions.fold<int>(0, (s, e) => s + e.menAttendance + e.womenAttendance);
    final menAtt    = sessions.fold<int>(0, (s, e) => s + e.menAttendance);
    final pmi       = totalAtt == 0 ? 0.0 : (menAtt / totalAtt) * 100;

    final cards = [
      _StatCard(
        icon: Icons.family_restroom,
        color: AppTheme.unicefBlueSolid,
        label: 'Familles enregistrées',
        value: '$families',
        sub: 'Total ménages',
        delay: 300,
      ),
      _StatCard(
        icon: Icons.assignment_turned_in,
        color: AppTheme.minproffGreen,
        label: 'Évaluations',
        value: '$assessed / $families',
        sub: '$pending en attente',
        delay: 380,
      ),
      _StatCard(
        icon: Icons.location_on,
        color: const Color(0xFF7B1FA2),
        label: 'Familles géolocalisées',
        value: '$mapped / $families',
        sub: 'Visibles sur la carte',
        delay: 460,
      ),
      _StatCard(
        icon: Icons.people,
        color: AppTheme.warningOrange,
        label: 'Masculinité positive',
        value: '${pmi.toStringAsFixed(0)}%',
        sub: 'Indice PMI (GSP)',
        delay: 540,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.h,
      childAspectRatio: 1.55,
      children: cards.map(_buildStatTile).toList(),
    );
  }

  Widget _buildStatTile(_StatCard d) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: d.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: d.color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 30.w, height: 30.h,
              decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r)),
              child: Icon(d.icon, color: d.color, size: 16.sp),
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(d.label,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
          ]),
          Text(d.value,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: d.color)),
          Text(d.sub,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: d.delay), duration: 450.ms).slideY(begin: 0.1);
  }

  // ── PHOTO CAROUSEL ───────────────────────────────────────────────────────────
  Widget _buildPhotoCarousel() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: 160.h,
            child: PageView.builder(
              controller: _carouselCtrl,
              itemCount: _carouselAssets.length,
              onPageChanged: (i) => setState(() => _carouselPage = i),
              itemBuilder: (_, i) => Image.asset(
                _carouselAssets[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.unicefBlueSolid.withValues(alpha: 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          size: 32.sp,
                          color: AppTheme.unicefBlueSolid.withValues(alpha: 0.4)),
                      SizedBox(height: 6.h),
                      Text('Photos de terrain',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.unicefBlueSolid.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselAssets.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: _carouselPage == i ? 18.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: _carouselPage == i
                    ? AppTheme.unicefBlueSolid
                    : AppTheme.unicefBlueSolid.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SYNC CARD ────────────────────────────────────────────────────────────────
  Widget _buildSyncCard(AppState state) {
    final pending = state.families.where((f) => f.isSynced == 0).length;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text(
              '$pending formulaire(s) en attente de synchronisation',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Icon(Icons.cloud_sync, size: 20.sp, color: AppTheme.unicefBlueSolid),
        ]),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: state.syncProgress,
            color: AppTheme.unicefBlueSolid,
            backgroundColor: Colors.grey[300],
            minHeight: 6.h,
          ),
        ),
      ]),
    );
  }

  // ── MAP SHORTCUT ─────────────────────────────────────────────────────────────
  Widget _buildMapShortcutCard(AppState state) {
    final mapped = state.families.where((f) => f.hasLocation).length;
    final alerts = state.alerts.where((a) => a.hasLocation).length;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MapScreen())),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 46.w, height: 46.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.map_outlined, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Carte Interactive des Familles',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: 3.h),
              Text(
                mapped == 0
                    ? 'Aucun point géolocalisé'
                    : '$mapped famille(s) · $alerts alerte(s) sur la carte',
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          Icon(Icons.chevron_right, color: Colors.white70, size: 22.sp),
        ]),
      ),
    );
  }
}

class _StatCard {
  final IconData icon;
  final Color color;
  final String label, value, sub;
  final int delay;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
    required this.delay,
  });
}
