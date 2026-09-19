import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/cameroon_admin.dart';
import '../theme/app_theme.dart';
import 'glass_field.dart';

/// Cascading dropdown: Région → Département → Arrondissement.
/// Calls [onChanged] whenever any level changes.
class CameroonLocationPicker extends StatefulWidget {
  final String? initialRegion;
  final String? initialDepartment;
  final String? initialArrondissement;
  final void Function(String? region, String? department, String? arrondissement) onChanged;

  const CameroonLocationPicker({
    super.key,
    this.initialRegion,
    this.initialDepartment,
    this.initialArrondissement,
    required this.onChanged,
  });

  @override
  State<CameroonLocationPicker> createState() => _CameroonLocationPickerState();
}

class _CameroonLocationPickerState extends State<CameroonLocationPicker> {
  String? _region;
  String? _department;
  String? _arrondissement;

  @override
  void initState() {
    super.initState();
    _region        = widget.initialRegion;
    _department    = widget.initialDepartment;
    _arrondissement = widget.initialArrondissement;
  }

  void _notify() => widget.onChanged(_region, _department, _arrondissement);

  @override
  Widget build(BuildContext context) {
    final regions      = CameroonAdmin.regions;
    final departments  = _region != null ? CameroonAdmin.departmentsFor(_region!) : <String>[];
    final arronds      = (_region != null && _department != null)
        ? CameroonAdmin.arrondissementsFor(_region!, _department!)
        : <String>[];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Section label
      Row(children: [
        Icon(Icons.location_city, size: 16.sp, color: AppTheme.unicefBlueSolid),
        SizedBox(width: 6.w),
        Text('Localisation Administrative',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold,
                color: AppTheme.unicefBlueSolid)),
      ]),
      SizedBox(height: 8.h),

      // Région
      GlassDropdown<String>(
        value: _region,
        hint: 'Sélectionner la Région',
        icon: Icons.map_outlined,
        items: regions.map((r) => DropdownMenuItem(
          value: r,
          child: Text(r, style: TextStyle(fontSize: 13.sp)),
        )).toList(),
        onChanged: (v) {
          setState(() {
            _region         = v;
            _department     = null;
            _arrondissement = null;
          });
          _notify();
        },
      ),
      SizedBox(height: 10.h),

      // Département
      GlassDropdown<String>(
        value: _department,
        hint: _region == null ? 'Choisir la Région d\'abord' : 'Sélectionner le Département',
        icon: Icons.account_balance_outlined,
        items: departments.map((d) => DropdownMenuItem(
          value: d,
          child: Text(d, style: TextStyle(fontSize: 13.sp)),
        )).toList(),
        onChanged: departments.isEmpty ? null : (v) {
          setState(() {
            _department     = v;
            _arrondissement = null;
          });
          _notify();
        },
      ),
      SizedBox(height: 10.h),

      // Arrondissement
      GlassDropdown<String>(
        value: _arrondissement,
        hint: _department == null ? 'Choisir le Département d\'abord' : 'Sélectionner l\'Arrondissement',
        icon: Icons.location_on_outlined,
        items: arronds.map((a) => DropdownMenuItem(
          value: a,
          child: Text(a, style: TextStyle(fontSize: 13.sp), overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: arronds.isEmpty ? null : (v) {
          setState(() => _arrondissement = v);
          _notify();
        },
      ),
    ]);
  }
}
