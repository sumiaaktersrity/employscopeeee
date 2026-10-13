import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JobListing {
  final String title;
  final String company;
  final String location;
  final int matchPercent; // 0-100, null-safe: pass 0 for "posted jobs" mode
  final bool showMatch;

  const JobListing({
    required this.title,
    required this.company,
    required this.location,
    this.matchPercent = 0,
    this.showMatch = true,
  });
}

/// Wraps either "Matched Jobs" (CV-driven recommendations, with a match %)
/// or "Posted Jobs" (plain listings) in one reusable card, so both flows
/// share the exact same visual container as the rest of the dashboard.
class MatchedJobsSection extends StatelessWidget {
  final String title;
  final List<JobListing> jobs;
  final void Function(JobListing)? onTapJob;
  final VoidCallback? onSeeAll;

  const MatchedJobsSection({
    super.key,
    required this.title,
    required this.jobs,
    this.onTapJob,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_outline,
                      color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: AppTextStyles.sectionHeading),
                ],
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.accentInfo,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No jobs to show yet. Upload and analyze your CV to see matches.',
                style: AppTextStyles.body,
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < jobs.length; i++) ...[
                  _JobTile(job: jobs[i], onTap: () => onTapJob?.call(jobs[i])),
                  if (i != jobs.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.cardBorder, height: 1),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final JobListing job;
  final VoidCallback onTap;
  const _JobTile({required this.job, required this.onTap});

  Color get _matchColor {
    if (job.matchPercent >= 75) return AppColors.accentGood;
    if (job.matchPercent >= 45) return AppColors.accentWarn;
    return AppColors.accentGap;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.smallCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job.company} · ${job.location}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (job.showMatch) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _matchColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${job.matchPercent}%',
                  style: TextStyle(
                    color: _matchColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}