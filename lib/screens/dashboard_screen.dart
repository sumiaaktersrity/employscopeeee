import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/cv_upload_button.dart';
import '../widgets/cv_analysis_results.dart';
import '../widgets/matched_jobs_section.dart';

/// Week 5 Dashboard: same header, drawer, and background treatment as your
/// existing screens (screenshots 2 & 4), with the new CV Upload, Analysis
/// Results, and Matched Jobs sections wired in below the hero area.
///
/// Replace the TODOs with your actual state management / API calls
/// (upload handler, analysis service, job-matching service).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _fileName;
  bool _isUploading = false;
  bool _hasAnalysis = false;

  Future<void> _pickFile() async {
    // TODO: replace with real file_picker logic.
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isUploading = false;
      _fileName = 'John_Doe_CV.pdf';
      _hasAnalysis = false;
    });
  }

  Future<void> _analyze() async {
    // TODO: replace with real analysis API call.
    setState(() => _hasAnalysis = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      drawer: const _AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _DashboardHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your CV & Job Matches',
                          style: AppTextStyles.screenTitle),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload your CV to get an instant match score and tailored job recommendations.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 20),

                      // 1. Upload button
                      CVUploadButton(
                        fileName: _fileName,
                        isUploading: _isUploading,
                        onPickFile: _pickFile,
                        onAnalyze: _analyze,
                      ),

                      const SizedBox(height: 20),

                      // 2. Analysis results (only once analyzed)
                      if (_hasAnalysis)
                        CVAnalysisResults(
                          matchScore: 78,
                          skills: const [
                            SkillTag('Flutter', SkillTagType.matched),
                            SkillTag('REST APIs', SkillTagType.matched),
                            SkillTag('Firebase', SkillTagType.matched),
                            SkillTag('CI/CD', SkillTagType.missing),
                            SkillTag('Unit Testing', SkillTagType.missing),
                            SkillTag('State Mgmt (Bloc)', SkillTagType.suggested),
                          ],
                          suggestions: const [
                            'Add measurable outcomes to your last role (e.g. "reduced load time by 30%").',
                            'List a testing framework — most target roles ask for it explicitly.',
                            'Mention any CI/CD tools you\'ve used, even briefly.',
                          ],
                        ),

                      if (_hasAnalysis) const SizedBox(height: 20),

                      // 3. Matched / Posted jobs
                      MatchedJobsSection(
                        title: _hasAnalysis ? 'Matched Jobs' : 'Posted Jobs',
                        onSeeAll: () {},
                        jobs: _hasAnalysis
                            ? const [
                                JobListing(
                                  title: 'Mobile App Developer',
                                  company: 'Nova Tech',
                                  location: 'Dhaka, BD',
                                  matchPercent: 88,
                                ),
                                JobListing(
                                  title: 'Flutter Engineer',
                                  company: 'Brightside Labs',
                                  location: 'Remote',
                                  matchPercent: 74,
                                ),
                                JobListing(
                                  title: 'Junior Software Engineer',
                                  company: 'Orbit Systems',
                                  location: 'Dhaka, BD',
                                  matchPercent: 52,
                                ),
                              ]
                            : const [
                                JobListing(
                                  title: 'Mobile App Developer',
                                  company: 'Nova Tech',
                                  location: 'Dhaka, BD',
                                  showMatch: false,
                                ),
                                JobListing(
                                  title: 'Flutter Engineer',
                                  company: 'Brightside Labs',
                                  location: 'Remote',
                                  showMatch: false,
                                ),
                              ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header bar: hamburger + cursive "EmployScope" wordmark, matching
/// screenshot 2 / 4.
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          const Text('EmployScope', style: AppTextStyles.logo),
        ],
      ),
    );
  }
}

/// Drawer matching screenshot 4 exactly: solid navy fill, cursive logo,
/// divider, then icon + label nav items.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerFill,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EmployScope', style: AppTextStyles.logo),
              const SizedBox(height: 24),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),
              _DrawerItem(icon: Icons.home_outlined, label: 'Saved Templates'),
              _DrawerItem(
                  icon: Icons.description_outlined, label: 'Your Career goals'),
              _DrawerItem(
                  icon: Icons.work_outline, label: 'Skill Gap analysis'),
              _DrawerItem(icon: Icons.settings_outlined, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DrawerItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 16),
          Text(label,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}