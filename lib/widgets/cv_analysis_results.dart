import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkillTag {
  final String label;
  final SkillTagType type;
  const SkillTag(this.label, this.type);
}

enum SkillTagType { matched, missing, suggested }

/// Result card shown after a CV has been analyzed.
///
/// Displays an overall match score, a matched/missing skill breakdown as
/// chips, and a short list of improvement suggestions — all inside the
/// same translucent card used elsewhere in the app.
class CVAnalysisResults extends StatelessWidget {
  final int matchScore; // 0-100
  final List<SkillTag> skills;
  final List<String> suggestions;

  const CVAnalysisResults({
    super.key,
    required this.matchScore,
    required this.skills,
    this.suggestions = const [],
  });

  Color get _scoreColor {
    if (matchScore >= 75) return AppColors.accentGood;
    if (matchScore >= 45) return AppColors.accentWarn;
    return AppColors.accentGap;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_outlined,
                  color: AppColors.textPrimary, size: 20),
              SizedBox(width: 8),
              Text('CV Analysis Results', style: AppTextStyles.sectionHeading),
            ],
          ),
          const SizedBox(height: 18),

          // Score row
          Row(
            children: [
              _ScoreRing(score: matchScore, color: _scoreColor),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scoreLabel(matchScore),
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: _scoreColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Based on how closely your CV matches your target roles.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 16),
            const Text('Skill breakdown', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => _SkillChip(tag: s)).toList(),
            ),
          ],

          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 16),
            const Text('Suggestions', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 10),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_rounded,
                        color: AppColors.accentInfo, size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(s, style: AppTextStyles.body),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 75) return '$score% Strong Match';
    if (score >= 45) return '$score% Partial Match';
    return '$score% Needs Work';
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$score%',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final SkillTag tag;
  const _SkillChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    switch (tag.type) {
      case SkillTagType.matched:
        color = AppColors.accentGood;
        icon = Icons.check_circle_outline;
        break;
      case SkillTagType.missing:
        color = AppColors.accentGap;
        icon = Icons.remove_circle_outline;
        break;
      case SkillTagType.suggested:
        color = AppColors.accentInfo;
        icon = Icons.add_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            tag.label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}