import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/family.dart';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
enum _MarkerKind { fullFollowUp, partialFollowUp, emergency }

class _MapPin {
  final LatLng point;
  final _MarkerKind kind;
  final Family? family;
  final Alert? alert;
  const _MapPin({required this.point, required this.kind, this.family, this.alert});
}

// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  final TileProvider  _tiles   = NetworkTileProvider();

  static const LatLng _defaultCenter = LatLng(10.5900, 14.3159);
  static const double _defaultZoom   = 11.5;

  LatLng? _myLocation;
  bool    _locating     = false;
  _MapPin? _selectedPin;
  bool    _showLegend   = true;

  // Active filter — null means show all
  _MarkerKind? _activeFilter;

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Pins ──────────────────────────────────────────────────────────────────
  List<_MapPin> _buildPins(AppState state) {
    final pins = <_MapPin>[];
    for (final f in state.families) {
      if (!f.hasLocation) continue;
      final kind = f.vulnerabilityStatus == 'Urgence'
          ? _MarkerKind.emergency
          : f.status == 'Full Follow-up'
              ? _MarkerKind.fullFollowUp
              : _MarkerKind.partialFollowUp;
      pins.add(_MapPin(point: LatLng(f.latitude!, f.longitude!), kind: kind, family: f));
    }
    for (final a in state.alerts) {
      if (!a.hasLocation) continue;
      pins.add(_MapPin(point: LatLng(a.latitude!, a.longitude!), kind: _MarkerKind.emergency, alert: a));
    }
    return pins;
  }

  List<_MapPin> _filteredPins(List<_MapPin> all) =>
      _activeFilter == null ? all : all.where((p) => p.kind == _activeFilter).toList();

  Map<_MarkerKind, int> _counts(List<_MapPin> pins) {
    final m = <_MarkerKind, int>{};
    for (final p in pins) { m[p.kind] = (m[p.kind] ?? 0) + 1; }
    return m;
  }

  // ── Camera ────────────────────────────────────────────────────────────────
  void _animateTo(LatLng target, double zoom) {
    final from  = _mapCtrl.camera.center;
    final fromZ = _mapCtrl.camera.zoom;
    final ctrl  = AnimationController(vsync: this, duration: 700.ms);
    final latTw = Tween<double>(begin: from.latitude,  end: target.latitude);
    final lngTw = Tween<double>(begin: from.longitude, end: target.longitude);
    final zoomTw = Tween<double>(begin: fromZ, end: zoom);
    final curve  = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);

    ctrl.addListener(() => _mapCtrl.move(
        LatLng(latTw.evaluate(curve), lngTw.evaluate(curve)),
        zoomTw.evaluate(curve)));
    ctrl.addStatusListener((s) { if (s == AnimationStatus.completed) ctrl.dispose(); });
    ctrl.forward();
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    final pos = await LocationService.instance.getCurrentPosition();
    setState(() {
      _locating = false;
      if (pos != null) {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _animateTo(_myLocation!, 14.0);
      }
    });
  }

  void _fitAll(List<_MapPin> pins) {
    if (pins.isEmpty) return;
    double minLat = pins.first.point.latitude, maxLat = minLat;
    double minLng = pins.first.point.longitude, maxLng = minLng;
    for (final p in pins) {
      minLat = math.min(minLat, p.point.latitude);
      maxLat = math.max(maxLat, p.point.latitude);
      minLng = math.min(minLng, p.point.longitude);
      maxLng = math.max(maxLng, p.point.longitude);
    }
    _mapCtrl.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
      padding: EdgeInsets.all(48.w),
    ));
  }

  // ── Colors / icons ────────────────────────────────────────────────────────
  Color _pinColor(_MarkerKind k) {
    switch (k) {
      case _MarkerKind.fullFollowUp:    return AppTheme.minproffGreen;
      case _MarkerKind.partialFollowUp: return AppTheme.warningOrange;
      case _MarkerKind.emergency:       return AppTheme.alertRed;
    }
  }

  IconData _pinIcon(_MarkerKind k) {
    switch (k) {
      case _MarkerKind.fullFollowUp:    return Icons.home;
      case _MarkerKind.partialFollowUp: return Icons.home_outlined;
      case _MarkerKind.emergency:       return Icons.warning_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state    = Provider.of<AppState>(context);
    final allPins  = _buildPins(state);
    final shown    = _filteredPins(allPins);
    final counts   = _counts(allPins);

    // families that match current filter for the bottom carousel
    final filterFamilies = shown
        .where((p) => p.family != null)
        .map((p) => p.family!)
        .toList();

    final topOffset = kToolbarHeight + MediaQuery.of(context).padding.top;
    final hasFilter = _activeFilter != null && filterFamilies.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              maxZoom: 18,
              minZoom: 5,
              onTap: (_, __) => setState(() {
                _selectedPin = null;
              }),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.unicef_app',
                tileProvider: _tiles,
                maxZoom: 19,
                errorTileCallback: (_, __, ___) {},
              ),
              if (_myLocation != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _myLocation!,
                    radius: 10,
                    color: AppTheme.unicefBlueSolid.withValues(alpha: 0.35),
                    borderColor: AppTheme.unicefBlueSolid,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: false,
                  ),
                ]),
              MarkerLayer(
                markers: shown.map((pin) {
                  final isSel  = _selectedPin == pin;
                  final color  = _pinColor(pin.kind);
                  return Marker(
                    point: pin.point,
                    width:  isSel ? 52.w : 42.w,
                    height: isSel ? 62.h : 50.h,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPin = pin);
                        _animateTo(pin.point, 14.5);
                      },
                      child: _PinWidget(
                          color: color,
                          icon: _pinIcon(pin.kind),
                          isSelected: isSel),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── TOP APP BAR ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(state, allPins),
          ),

          // ── FILTER CHIPS ─────────────────────────────────────────
          Positioned(
            top: topOffset + 8.h,
            left: 12.w,
            right: 12.w,
            child: _buildFilterChips(counts)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.3),
          ),

          // ── LEGEND ───────────────────────────────────────────────
          if (_showLegend && _selectedPin == null && !hasFilter)
            Positioned(
              bottom: 24.h,
              left: 12.w,
              child: _buildLegend().animate().fadeIn(duration: 300.ms),
            ),

          // ── FAB BUTTONS ──────────────────────────────────────────
          Positioned(
            right: 12.w,
            bottom: (hasFilter || _selectedPin != null) ? 250.h : 24.h,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _MapFab(
                icon: _locating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.my_location, size: 20.sp),
                color: AppTheme.unicefBlueSolid,
                tooltip: 'Ma position',
                onTap: _locateMe,
              ),
              SizedBox(height: 10.h),
              _MapFab(
                icon: Icon(Icons.fit_screen, size: 20.sp),
                color: AppTheme.minproffGreen,
                tooltip: 'Tout afficher',
                onTap: () => shown.isEmpty
                    ? _animateTo(_defaultCenter, _defaultZoom)
                    : _fitAll(shown),
              ),
              SizedBox(height: 10.h),
              _MapFab(
                icon: Icon(_showLegend ? Icons.layers_clear : Icons.layers, size: 20.sp),
                color: Colors.grey[700]!,
                tooltip: 'Légende',
                onTap: () => setState(() => _showLegend = !_showLegend),
              ),
            ]),
          ),

          // ── FILTER FAMILY CAROUSEL ────────────────────────────────
          if (hasFilter && _selectedPin == null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildFilterCarousel(filterFamilies)
                  .animate()
                  .slideY(begin: 1.0, duration: 350.ms, curve: Curves.easeOutCubic),
            ),

          // ── SELECTED PIN DETAIL SHEET ─────────────────────────────
          if (_selectedPin != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _PinDetailSheet(
                pin: _selectedPin!,
                onClose: () => setState(() => _selectedPin = null),
                onAssess: _selectedPin!.family != null
                    ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => FormScreen(family: _selectedPin!.family!)))
                    : null,
              ).animate().slideY(begin: 1.0, duration: 350.ms, curve: Curves.easeOutCubic),
            ),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildTopBar(AppState state, List<_MapPin> pins) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.unicefBlueSolid,
      title: Row(children: [
        Image.asset('assets/images/unicef_logo.png',
            height: 26.h,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.apartment, size: 20.sp, color: Colors.white)),
        SizedBox(width: 8.w),
        Flexible(
          child: Text('Carte des Familles',
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      actions: [
        if (_activeFilter != null)
          IconButton(
            icon: Icon(Icons.filter_alt_off, size: 22.sp, color: Colors.white),
            tooltip: 'Effacer le filtre',
            onPressed: () => setState(() => _activeFilter = null),
          ),
        IconButton(
          icon: Icon(Icons.info_outline, size: 22.sp, color: Colors.white),
          tooltip: '${pins.length} points',
          onPressed: () => _showInfoDialog(pins),
        ),
      ],
    );
  }

  // ── FILTER CHIPS ──────────────────────────────────────────────────────────
  Widget _buildFilterChips(Map<_MarkerKind, int> counts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FilterChip(
          count: counts[_MarkerKind.fullFollowUp] ?? 0,
          label: 'Complet',
          color: AppTheme.minproffGreen,
          icon: Icons.home,
          active: _activeFilter == _MarkerKind.fullFollowUp,
          onTap: () => setState(() {
            _activeFilter = _activeFilter == _MarkerKind.fullFollowUp
                ? null
                : _MarkerKind.fullFollowUp;
            _selectedPin = null;
          }),
        ),
        SizedBox(width: 8.w),
        _FilterChip(
          count: counts[_MarkerKind.partialFollowUp] ?? 0,
          label: 'Partiel',
          color: AppTheme.warningOrange,
          icon: Icons.home_outlined,
          active: _activeFilter == _MarkerKind.partialFollowUp,
          onTap: () => setState(() {
            _activeFilter = _activeFilter == _MarkerKind.partialFollowUp
                ? null
                : _MarkerKind.partialFollowUp;
            _selectedPin = null;
          }),
        ),
        SizedBox(width: 8.w),
        _FilterChip(
          count: counts[_MarkerKind.emergency] ?? 0,
          label: 'Urgence',
          color: AppTheme.alertRed,
          icon: Icons.warning_rounded,
          active: _activeFilter == _MarkerKind.emergency,
          onTap: () => setState(() {
            _activeFilter = _activeFilter == _MarkerKind.emergency
                ? null
                : _MarkerKind.emergency;
            _selectedPin = null;
          }),
        ),
      ],
    );
  }

  // ── FILTER FAMILY CAROUSEL ────────────────────────────────────────────────
  Widget _buildFilterCarousel(List<Family> families) {
    // Sort alphabetically
    final sorted = [...families]
      ..sort((a, b) => a.householdName.toLowerCase().compareTo(b.householdName.toLowerCase()));

    final kindColor = _activeFilter != null ? _pinColor(_activeFilter!) : AppTheme.unicefBlueSolid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r)),
            ),

            // Header row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(children: [
                Icon(Icons.filter_list, size: 16.sp, color: kindColor),
                SizedBox(width: 6.w),
                Text(
                  '${sorted.length} famille(s) · ordre alphabétique',
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: kindColor),
                ),
              ]),
            ),
            SizedBox(height: 10.h),

            // Horizontal scrollable list — each card wraps its own content
            SizedBox(
              height: 118.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                scrollDirection: Axis.horizontal,
                itemCount: sorted.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (_, i) {
                  final f = sorted[i];
                  return GestureDetector(
                    onTap: () {
                      _animateTo(LatLng(f.latitude!, f.longitude!), 16.0);
                      setState(() => _selectedPin = _MapPin(
                            point: LatLng(f.latitude!, f.longitude!),
                            kind: _activeFilter ?? _MarkerKind.partialFollowUp,
                            family: f,
                          ));
                    },
                    child: Container(
                      width: 168.w,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: kindColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: kindColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name row
                          Row(children: [
                            Icon(Icons.family_restroom, size: 14.sp, color: kindColor),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                f.householdName,
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ]),
                          SizedBox(height: 4.h),

                          // Neighborhood
                          Text(
                            f.neighborhood,
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),

                          // Children
                          Text(
                            '${f.childCount} enfant(s)',
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                          ),
                          SizedBox(height: 6.h),

                          // Badges row — Wrap prevents overflow
                          Wrap(
                            spacing: 4.w,
                            runSpacing: 2.h,
                            children: [
                              _miniChip(f.vulnerabilityStatus ?? 'Normal', kindColor),
                              _miniChip('📍 Carte', kindColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.sp, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis),
    );
  }

  // ── LEGEND ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Légende', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(height: 6.h),
        _legendRow(AppTheme.minproffGreen, Icons.home, 'Suivi complet'),
        SizedBox(height: 4.h),
        _legendRow(AppTheme.warningOrange, Icons.home_outlined, 'Suivi partiel'),
        SizedBox(height: 4.h),
        _legendRow(AppTheme.alertRed, Icons.warning_rounded, 'Alerte urgente'),
        SizedBox(height: 4.h),
        _legendRow(AppTheme.unicefBlueSolid, Icons.my_location, 'Ma position'),
      ]),
    );
  }

  Widget _legendRow(Color color, IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14.sp, color: color),
      SizedBox(width: 6.w),
      Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[800])),
    ]);
  }

  void _showInfoDialog(List<_MapPin> pins) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Carte — aide', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        content: Text(
          '${pins.length} point(s) géolocalisé(s).\n\n'
          'Appuyez sur un badge coloré pour filtrer par catégorie.\n'
          'Touchez une carte famille pour centrer la caméra.',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip — tappable, highlights when active
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.count, required this.label, required this.color,
    required this.icon, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? color : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
          border: Border.all(color: color.withValues(alpha: active ? 1 : 0.4), width: active ? 2 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14.sp, color: active ? Colors.white : color),
          SizedBox(width: 4.w),
          Text(
            '$count $label',
            style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : color),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin teardrop widget
// ─────────────────────────────────────────────────────────────────────────────
class _PinWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  const _PinWidget({required this.color, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 44.w : 36.w;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isSelected ? 22.sp : 18.sp),
      ),
      CustomPaint(
          size: Size(10.w, 8.h), painter: _TeardropTail(color: color)),
    ]);
  }
}

class _TeardropTail extends CustomPainter {
  final Color color;
  _TeardropTail({required this.color});
  @override
  void paint(ui.Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path  = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_TeardropTail old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB button
// ─────────────────────────────────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46.w, height: 46.h,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _PinDetailSheet extends StatelessWidget {
  final _MapPin pin;
  final VoidCallback onClose;
  final VoidCallback? onAssess;
  const _PinDetailSheet({required this.pin, required this.onClose, this.onAssess});

  @override
  Widget build(BuildContext context) {
    final isEmergency = pin.kind == _MarkerKind.emergency;
    final color       = isEmergency ? AppTheme.alertRed : AppTheme.unicefBlueSolid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
          width: 40.w, height: 4.h,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 44.w, height: 44.h,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Icon(isEmergency ? Icons.warning_rounded : Icons.family_restroom,
                    color: color, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    pin.family?.householdName ?? pin.alert?.riskCategory ?? '—',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isEmergency
                        ? 'Alerte urgente · ${pin.alert?.incidentDate ?? ''}'
                        : '${pin.family?.neighborhood ?? ''} · ${pin.family?.childCount ?? 0} enfant(s)',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, size: 20.sp, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            SizedBox(height: 14.h),

            if (pin.family != null) ...[
              Wrap(spacing: 8.w, runSpacing: 6.h, children: [
                _chip(Icons.shield_outlined, pin.family!.vulnerabilityStatus ?? 'Normal', _vulnColor(pin.family!.vulnerabilityStatus)),
                _chip(Icons.assignment_turned_in_outlined,
                    pin.family!.status == 'Full Follow-up' ? 'Suivi complet' : 'Suivi partiel',
                    pin.family!.status == 'Full Follow-up' ? AppTheme.minproffGreen : AppTheme.warningOrange),
                if (pin.family!.lastVisitDate.isNotEmpty)
                  _chip(Icons.calendar_today_outlined, pin.family!.lastVisitDate, Colors.grey[600]!),
                _chip(Icons.location_on_outlined,
                    '${pin.point.latitude.toStringAsFixed(4)}, ${pin.point.longitude.toStringAsFixed(4)}',
                    AppTheme.unicefBlueSolid),
              ]),
              SizedBox(height: 12.h),
              if (pin.family!.photoProofPaths != null) ...[
                _photoRow(pin.family!.photoProofPaths!),
                SizedBox(height: 12.h),
              ],
            ],

            if (pin.alert != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.alertRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.3)),
                ),
                child: Text(pin.alert!.anonymizedDescription,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[800], height: 1.5),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(height: 12.h),
              Wrap(spacing: 8.w, children: [
                _chip(Icons.location_on_outlined,
                    '${pin.point.latitude.toStringAsFixed(4)}, ${pin.point.longitude.toStringAsFixed(4)}',
                    AppTheme.alertRed),
              ]),
              SizedBox(height: 12.h),
            ],

            if (onAssess != null)
              SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: onAssess,
                  icon: Icon(Icons.assignment_outlined, size: 18.sp),
                  label: Text(
                    '📋  COMMENCER L\'ÉVALUATION (10 MODULES)',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.unicefBlueSolid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.sp, color: color),
        SizedBox(width: 4.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 160.w),
          child: Text(label,
              style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  Widget _photoRow(String jsonPaths) {
    try {
      final paths = List<String>.from(jsonDecode(jsonPaths));
      if (paths.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 70.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: paths.length,
          separatorBuilder: (_, __) => SizedBox(width: 6.w),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(File(paths[i]),
                width: 70.w, height: 70.h, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 70.w, height: 70.h, color: Colors.grey[200],
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 22.sp))),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Color _vulnColor(String? s) {
    switch (s) {
      case 'Urgence': return AppTheme.alertRed;
      case 'Élevé':   return AppTheme.warningOrange;
      default:        return AppTheme.minproffGreen;
    }
  }
}
