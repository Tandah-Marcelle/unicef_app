import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable glass-morphism styled input field — consistent across
/// LoginScreen, AddFamilySheet and GroupSessionScreen.
class GlassField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final String? helper;
  final IconData icon;
  final bool obscure;
  final int? maxLength;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool isRequired;
  final int? maxLines;
  final String? initialValue;

  const GlassField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.helper,
    this.obscure = false,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.isRequired = true,
    this.maxLines = 1,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscure ? 1 : maxLines,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint + (isRequired ? '' : ' (optionnel)'),
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
        helperText: helper,
        helperStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
        helperMaxLines: 2,
        counterText: '',
        prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF00AEEF)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
      ),
    );
  }
}

/// Glass-style DropdownButtonFormField with matching decoration.
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  const GlassDropdown({
    super.key,
    this.value,
    required this.hint,
    required this.icon,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF00AEEF)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 1.8),
        ),
      ),
      items: items,
    );
  }
}
