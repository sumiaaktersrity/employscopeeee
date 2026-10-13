import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Upload-CV control for the dashboard.
///
/// Two states:
///  - empty: dashed drop area + white "UPLOAD CV" pill button
///           (mirrors the LOGIN pill on the Login screen)
///  - selected: shows the chosen file name with a "Change" outlined
///           pill button (mirrors the SIGN UP outlined pill)
///
/// Purely presentational — pass a callback for the actual file picker
/// logic (e.g. using `file_picker`) and drive [fileName]/[isUploading]
/// from your state management of choice.
class CVUploadButton extends StatelessWidget {
  final String? fileName;
  final bool isUploading;
  final VoidCallback onPickFile;
  final VoidCallback? onAnalyze;

  const CVUploadButton({
    super.key,
    required this.onPickFile,
    this.fileName,
    this.isUploading = false,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined,
                  color: AppColors.textPrimary, size: 20),
              SizedBox(width: 8),
              Text('Upload your CV', style: AppTextStyles.sectionHeading),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'PDF or DOCX, up to 5MB. We\'ll scan it against your target jobs.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),

          // Dashed drop zone
          DottedBorderBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Icon(
                    hasFile
                        ? Icons.insert_drive_file_outlined
                        : Icons.cloud_upload_outlined,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasFile ? fileName! : 'No file selected',
                    style: AppTextStyles.body.copyWith(
                      color: hasFile
                          ? AppColors.textPrimary
                          : AppColors.textPlaceholder,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _PillButton(
                  filled: true,
                  label: isUploading
                      ? 'UPLOADING...'
                      : (hasFile ? 'CHOOSE ANOTHER' : 'UPLOAD CV'),
                  onTap: isUploading ? null : onPickFile,
                  loading: isUploading,
                ),
              ),
              if (hasFile && onAnalyze != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _PillButton(
                    filled: false,
                    label: 'ANALYZE',
                    onTap: onAnalyze,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashed-border container standing in for a native drop zone.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.smallCard),
          color: Colors.white.withOpacity(0.03),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(AppRadii.smallCard),
    );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shared pill button matching LOGIN (filled) / SIGN UP (outlined) styles.
class _PillButton extends StatelessWidget {
  final bool filled;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PillButton({
    required this.filled,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnLight,
                      ),
                    )
                  : Text(label, style: AppTextStyles.buttonDark),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondaryButtonBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
              ),
              child: Text(label, style: AppTextStyles.buttonLight),
            ),
    );
  }
}