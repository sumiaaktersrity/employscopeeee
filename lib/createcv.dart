import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart'; // the design tokens file (AppColors, AppTextStyles, ...)

class CreateCvPage extends StatefulWidget {
  const CreateCvPage({super.key});

  @override
  State<CreateCvPage> createState() => _CreateCvPageState();
}

class _CreateCvPageState extends State<CreateCvPage> {
  final _jobTextCtrl = TextEditingController();
  final _jobUrlCtrl = TextEditingController();

  String? _pdfName;
  bool _showForm = false;
  bool _showResults = false;

  // Hardcoded for now: requirement name -> match percentage.
  final List<_Requirement> _requirements = const [
    _Requirement('Flutter / Dart development', 90),
    _Requirement('REST API integration', 75),
    _Requirement('Firebase / backend basics', 60),
    _Requirement('State management (Provider / Bloc)', 40),
    _Requirement('Unit & widget testing', 25),
  ];

  int get _overallMatch =>
      (_requirements.map((r) => r.match).reduce((a, b) => a + b) /
              _requirements.length)
          .round();

  @override
  void dispose() {
    _jobTextCtrl.dispose();
    _jobUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file != null) {
      setState(() => _pdfName = file.name);
    }
  }

  Color _colorFor(int match) {
    if (match >= 75) return AppColors.accentGood;
    if (match >= 50) return AppColors.accentWarn;
    return AppColors.accentGap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text('EmployScope', style: AppTextStyles.logo),
      ),
      drawer: const _AppDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCreateCvButton(),
                  const SizedBox(height: 14),
                  const Text(
                    'Post your targeted job and create a tailored CV '
                    'highlighting the requirements of your targeted job.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  if (_showForm) ...[
                    const SizedBox(height: 24),
                    _buildInputCard(),
                  ],
                  if (_showResults) ...[
                    const SizedBox(height: 24),
                    _buildResultsCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCvButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () => setState(() {
          _showForm = true;
          _showResults = false;
        }),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButtonFill,
          foregroundColor: AppColors.textOnLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
        ),
        child: const Text('Create CV', style: AppTextStyles.buttonDark),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: AppRadii.smallCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Post your job description',
              style: AppTextStyles.sectionHeading),
          const SizedBox(height: 6),
          TextField(
            controller: _jobTextCtrl,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: AppDecorations.underlineInput(
                'Paste the job description here'),
          ),
          const SizedBox(height: 20),
          const Text('Post your job URL', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 6),
          TextField(
            controller: _jobUrlCtrl,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: AppDecorations.underlineInput('https://...'),
          ),
          const SizedBox(height: 20),
          const Text('Post recruitment post PDF',
              style: AppTextStyles.sectionHeading),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Choose PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(
                      color: AppColors.secondaryButtonBorder, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pdfName ?? 'No file selected',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _showResults = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonFill,
                foregroundColor: AppColors.textOnLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
              ),
              child: const Text('OK', style: AppTextStyles.buttonDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: AppRadii.smallCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Key requirements',
                    style: AppTextStyles.sectionHeading),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _colorFor(_overallMatch).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  border: Border.all(color: _colorFor(_overallMatch)),
                ),
                child: Text(
                  '$_overallMatch% match',
                  style: TextStyle(
                    color: _colorFor(_overallMatch),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final r in _requirements) ...[
            Row(
              children: [
                Expanded(
                  child: Text(r.name, style: AppTextStyles.body),
                ),
                Text(
                  '${r.match}%',
                  style: TextStyle(
                    color: _colorFor(r.match),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: r.match / 100,
                minHeight: 8,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(_colorFor(r.match)),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Requirement {
  final String name;
  final int match;
  const _Requirement(this.name, this.match);
}

/// Placeholder drawer styled with the app tokens.
/// Replace this with your existing sidebar widget so both stay identical.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerFill,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('EmployScope', style: AppTextStyles.logo),
            ),
            const Divider(color: AppColors.cardBorder),
            _item(context, Icons.dashboard_outlined, 'Dashboard'),
            _item(context, Icons.description_outlined, 'Create CV'),
            _item(context, Icons.logout, 'Logout'),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      onTap: () => Navigator.pop(context),
    );
  }
}