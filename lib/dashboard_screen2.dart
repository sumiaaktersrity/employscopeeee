import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '/services/models.dart';
import '/services/api_client.dart';
import '/services/cv_service.dart';
import 'services/job_service.dart';
import 'app_theme.dart';
import 'cv_upload_button.dart';
import 'widgets/cv_analysis_results.dart';
import '/widgets/matched_jobs_section.dart';

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
  List<JobModel> _savedJobs = []; // Week 10: targeted jobs

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
    await _loadSaved();
  }

  /// Week 10: kept separate so a failure here never affects Weeks 5-9 data.
  Future<void> _loadSaved() async {
    try {
      final saved = await _jobService.listSaved();
      if (!mounted) return;
      setState(() => _savedJobs = saved);
    } catch (e) {
      _toast(ApiClient.messageFrom(e));
    }
  }

  /// Week 10: bookmark / un-bookmark a job (optimistic, reverts on error).
  Future<void> _toggleSave(JobListing l) async {
    final id = l.id;
    if (id == null) return;
    final previous = List<JobModel>.from(_savedJobs);
    final wasSaved = previous.any((j) => j.id == id);

    if (!wasSaved) {
      final src = [..._matchedJobs, ..._postedJobs].where((j) => j.id == id);
      if (src.isEmpty) return;
      final j = src.first;
      setState(() => _savedJobs = [
            JobModel(
                id: j.id,
                title: j.title,
                company: j.company,
                location: j.location),
            ...previous,
          ]);
    } else {
      setState(() => _savedJobs = previous.where((j) => j.id != id).toList());
    }

    try {
      if (wasSaved) {
        await _jobService.unsaveJob(id);
      } else {
        await _jobService.saveJob(id);
      }
    } catch (e) {
      if (mounted) setState(() => _savedJobs = previous);
      _toast(ApiClient.messageFrom(e));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickFile() async {
    // file_picker 12+: FilePicker.pickFile returns PlatformFile? directly
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
    );
    if (file == null) return;

    // Bytes are read lazily now, and the size check uses the actual length.
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return _toast('Could not read the selected file.');
    if (bytes.length > _maxBytes) return _toast('File is larger than 5MB.');

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
    final savedIds = _savedJobs.map((j) => j.id).toSet();

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
                          onToggleSave: _toggleSave,
                          jobs: (_hasAnalysis ? _matchedJobs : _postedJobs)
                              .map((j) =>
                                  j.toListing(isSaved: savedIds.contains(j.id)))
                              .toList(),
                        ),

                        const SizedBox(height: 20),

                        // 4. Targeted jobs (Week 10)
                        MatchedJobsSection(
                          title: 'Targeted Jobs',
                          emptyText:
                              'No targeted jobs yet. Tap the bookmark on any job to save it here.',
                          onToggleSave: _toggleSave,
                          jobs: _savedJobs
                              .map((j) => j.toListing(isSaved: true))
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
          Text('EmployScope', style: AppTextStyles.logo),
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
              Text('EmployScope', style: AppTextStyles.logo),
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