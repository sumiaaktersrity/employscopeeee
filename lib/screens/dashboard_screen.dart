import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/cv_service.dart';
import '../services/job_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cv_upload_button.dart';
import '../widgets/cv_analysis_results.dart';
import '../widgets/matched_jobs_section.dart';

/// Week 6 Dashboard: identical layout/theme to Week 5, now driven by the
/// Express + Supabase backend (upload -> parse -> analyze -> matched jobs).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _cvService = CvService();
  final _jobService = JobService();

  static const _maxBytes = 5 * 1024 * 1024;

  CvRecord? _cv;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  CvAnalysis? _analysis;
  List<JobModel> _matchedJobs = [];
  List<JobModel> _postedJobs = [];

  bool get _hasAnalysis => _analysis != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Load posted jobs, and restore the user's latest CV + analysis if any.
  Future<void> _bootstrap() async {
    try {
      final jobs = await _jobService.listJobs();
      final latest = await _cvService.latest();
      if (!mounted) return;
      setState(() {
        _postedJobs = jobs;
        _cv = latest.cv;
        if (latest.bundle != null) {
          _analysis = latest.bundle!.analysis;
          _matchedJobs = latest.bundle!.matchedJobs;
        }
      });
    } catch (e) {
      _toast(ApiClient.messageFrom(e));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
      withData: true, // bytes work on mobile and web
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return _toast('Could not read the selected file.');
    if (file.size > _maxBytes) return _toast('File is larger than 5MB.');

    setState(() => _isUploading = true);
    try {
      final cv = await _cvService.upload(file);
      if (!mounted) return;
      setState(() {
        _cv = cv;
        _analysis = null; // new CV -> previous analysis no longer applies
        _matchedJobs = [];
      });
    } catch (e) {
      _toast(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _analyze() async {
    final cv = _cv;
    if (cv == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    try {
      final bundle = await _cvService.analyze(cv.id);
      if (!mounted) return;
      setState(() {
        _analysis = bundle.analysis;
        _matchedJobs = bundle.matchedJobs;
      });
    } catch (e) {
      _toast(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;

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
                child: RefreshIndicator(
                  onRefresh: _bootstrap,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          fileName: _cv?.fileName,
                          isUploading: _isUploading || _isAnalyzing,
                          onPickFile: _pickFile,
                          onAnalyze: _analyze,
                        ),

                        const SizedBox(height: 20),

                        // 2. Analysis results (only once analyzed)
                        if (analysis != null) ...[
                          CVAnalysisResults(
                            matchScore: analysis.score,
                            skills: analysis.skillTags,
                            suggestions: analysis.suggestions,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 3. Matched / Posted jobs
                        MatchedJobsSection(
                          title: _hasAnalysis ? 'Matched Jobs' : 'Posted Jobs',
                          onSeeAll: () {},
                          jobs: (_hasAnalysis ? _matchedJobs : _postedJobs)
                              .map((j) => j.toListing())
                              .toList(),
                        ),
                      ],
                    ),
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

/// Header bar: hamburger + cursive "EmployScope" wordmark.
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

/// Drawer: solid navy fill, cursive logo, divider, icon + label nav items.
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