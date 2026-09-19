import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

/// Voice note widget.
/// Playback of an existing .m4a file is supported via audioplayers.
/// On-device recording is not available in this build (requires the `record`
/// package which needs additional Gradle tooling). Facilitators use the
/// text note field for observations.
class VoiceNoteWidget extends StatefulWidget {
  final String? existingPath;
  final ValueChanged<String>? onSaved;
  final String prefix;

  const VoiceNoteWidget({
    super.key,
    this.existingPath,
    this.onSaved,
    this.prefix = 'voice_note',
  });

  @override
  State<VoiceNoteWidget> createState() => _VoiceNoteWidgetState();
}

class _VoiceNoteWidgetState extends State<VoiceNoteWidget> {
  final _audio = AudioService.instance;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _audio.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  Future<void> _togglePlay() async {
    if (widget.existingPath == null) return;
    if (_playing) {
      await _audio.pause();
    } else {
      await _audio.play(widget.existingPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.existingPath != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.mic_none_outlined, size: 18.sp, color: AppTheme.unicefBlueSolid),
          SizedBox(width: 8.w),
          Text('Note Vocale',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        ]),
        SizedBox(height: 8.h),

        if (hasFile) ...[
          // Playback controls for existing recording
          Row(children: [
            _ControlButton(
              icon: _playing ? Icons.pause : Icons.play_arrow,
              color: AppTheme.minproffGreen,
              label: _playing ? 'Pause' : 'Écouter',
              onTap: _togglePlay,
            ),
            SizedBox(width: 8.w),
            _ControlButton(
              icon: Icons.stop,
              color: Colors.grey[600]!,
              label: 'Arrêter',
              onTap: () => _audio.stop(),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.minproffGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text('Fichier audio disponible',
                  style: TextStyle(fontSize: 10.sp, color: AppTheme.minproffGreen,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ] else ...[
          // Info message — recording not available
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14.sp, color: AppTheme.warningOrange),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Enregistrement audio non disponible dans cette version. '
                  'Utilisez le champ "Notes de Visite" pour vos observations.',
                  style: TextStyle(fontSize: 11.sp, color: AppTheme.warningOrange, height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
