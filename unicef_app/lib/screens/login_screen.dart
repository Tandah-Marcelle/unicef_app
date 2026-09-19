import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'nav_hub_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _idController  = TextEditingController();
  final _pinController = TextEditingController();
  bool _rememberMe   = false;
  bool _isOfflineMode = false;
  bool _obscurePin   = true;
  bool _isLoading    = false;
  bool _btnPressed   = false;

  static const _blue = Color(0xFF00AEEF);

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavHubScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0277BD), Color(0xFF00AEEF), Color(0xFF29B6F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(height: 16.h),

                    // ── LOGO HEADER ────────────────────────────────────
                    _buildLogoHeader()
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: -0.25),

                    SizedBox(height: 20.h),

                    // ── GLASS CARD ─────────────────────────────────────
                    _buildGlassCard()
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.2),

                    const Spacer(),

                    SizedBox(height: 20.h),

                    // ── FOOTER ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 12.sp, color: Colors.white70),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            'Données sécurisées · Hors ligne jusqu\'à la synchronisation',
                            style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── LOGO HEADER ─────────────────────────────────────────────────────────────
  Widget _buildLogoHeader() {
    return Column(
      children: [
        // Logos row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _logoBox('assets/images/unicef_logo.png', 'UNICEF',
                const Color(0xFF00AEEF)),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              height: 44.h,
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            _logoBox('assets/images/minproff_logo.png', 'MINPROFF',
                const Color(0xFF008751)),
          ],
        ),
        SizedBox(height: 8.h),
        // Motto
        Text(
          'Pour chaque enfant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontStyle: FontStyle.italic,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'ComMobi-Tracker',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'MINPROFF · UNICEF Cameroun',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _logoBox(String asset, String fallback, Color fallbackColor) {
    return Container(
      width: 76.w,
      height: 52.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(fallback,
                style: TextStyle(
                    fontSize: 10.sp,
                    color: fallbackColor,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // ── GLASS CARD ──────────────────────────────────────────────────────────────
  Widget _buildGlassCard() {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── OFFLINE BADGE ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _isOfflineMode
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: _isOfflineMode ? Colors.orange : Colors.green,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOfflineMode ? Icons.wifi_off : Icons.wifi,
                    size: 15.sp,
                    color: _isOfflineMode ? Colors.orange : Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isOfflineMode
                          ? 'Mode Hors-Ligne · Auth Locale'
                          : 'En Ligne · Auth Serveur',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: _isOfflineMode ? Colors.orange : Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    value: _isOfflineMode,
                    onChanged: (v) => setState(() => _isOfflineMode = v),
                    activeColor: Colors.orange,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── ID FIELD ──────────────────────────────────
            _glassField(
              controller: _idController,
              hint: 'ID Facilitateur / Numéro de téléphone',
              helper: 'Réservé aux facilitateurs de terrain MINPROFF / UNICEF.',
              icon: Icons.person_outline,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
              ],
              validator: (v) => v == null || v.trim().length < 6
                  ? 'Entrez un ID ou numéro valide'
                  : null,
            ).animate().fadeIn(delay: 400.ms),
            SizedBox(height: 14.h),

            // ── PIN FIELD ─────────────────────────────────
            _glassField(
              controller: _pinController,
              hint: 'Code PIN',
              icon: Icons.lock_outline,
              obscure: _obscurePin,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.length < 4 ? 'PIN minimum 4 chiffres' : null,
              suffix: IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20.sp,
                  color: Colors.grey[500],
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ).animate().fadeIn(delay: 500.ms),
            SizedBox(height: 12.h),

            // ── REMEMBER ME ───────────────────────────────
            Row(
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: _blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r)),
                  ),
                ),
                SizedBox(width: 8.w),
                Text('Se souvenir de moi',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
              ],
            ).animate().fadeIn(delay: 600.ms),
            SizedBox(height: 22.h),

            // ── LOGIN BUTTON ──────────────────────────────
            GestureDetector(
              onTapDown: (_) => setState(() => _btnPressed = true),
              onTapUp: (_) => setState(() => _btnPressed = false),
              onTapCancel: () => setState(() => _btnPressed = false),
              onTap: _isLoading ? null : _handleLogin,
              child: AnimatedScale(
                scale: _btnPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  height: 54.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0277BD), Color(0xFF00AEEF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            'CONNEXION',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  // ── STYLED INPUT FIELD ───────────────────────────────────────────────────────
  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
    bool obscure = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
        helperText: helper,
        helperStyle: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
        helperMaxLines: 2,
        counterText: '',
        prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF00AEEF)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: Color(0xFF00AEEF), width: 1.8),
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
