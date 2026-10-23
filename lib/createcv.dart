import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app_theme.dart'; // the design tokens file (AppColors, AppTextStyles, ...)

// TODO: replace with your real backend URL (or the matching ApiConfig value).
// Android emulator reaches your PC at 10.0.2.2. A real phone needs your PC's LAN IP.
const String _backendUrl = 'http://localhost:3000';

class CreateCvPage extends StatefulWidget {
  const CreateCvPage({super.key});

  @override
  State<CreateCvPage> createState() => _CreateCvPageState();
}

class _CreateCvPageState extends State<CreateCvPage> {
  final _jobTextCtrl = TextEditingController();
  final _jobUrlCtrl = TextEditingController();

  String? _pdfName;
  List<int>? _pdfBytes;
  bool _showForm = false;
  bool _showResults = false;
  bool _loading = false;
  String? _error;

  List<String> _requirements = [];

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
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pdfName = file.name;
        _pdfBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final text = _jobTextCtrl.text.trim();
    final url = _jobUrlCtrl.text.trim();
    final hasPdf = _pdfBytes != null;

    if (text.isEmpty && url.isEmpty && !hasPdf) {
      setState(() => _error = 'Add a job description, a URL, or a PDF first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _showResults = false;
    });

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw 'You are not logged in. Please log in again.';
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/api/job/requirements'),
      )..headers['Authorization'] = 'Bearer $token';

      if (text.isNotEmpty) request.fields['jobText'] = text;
      if (url.isNotEmpty) request.fields['jobUrl'] = url;
      if (hasPdf) {
        request.files.add(http.MultipartFile.fromBytes(
          'pdf',
          _pdfBytes!,
          filename: _pdfName ?? 'job.pdf',
        ));
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        throw (body['error'] ?? 'Something went wrong').toString();
      }

      final list = (body['requirements'] as List).map((e) => e.toString()).toList();
      if (list.isEmpty) {
        throw 'No requirements were found in that job post.';
      }

      setState(() {
        _requirements = list;
        _showResults = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          _error = null;
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
            enabled: !_loading,
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
            enabled: !_loading,
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
                onPressed: _loading ? null : _pickPdf,
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
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.accentGap,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonFill,
                foregroundColor: AppColors.textOnLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textOnLight,
                      ),
                    )
                  : const Text('OK', style: AppTextStyles.buttonDark),
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
          const Text('Key requirements', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 14),
          for (final r in _requirements)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.accentInfo,
                    ),
                  ),
                  Expanded(child: Text(r, style: AppTextStyles.body)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 14),
          const Text(
            'Want to create a CV tailored to these requirements?',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              // Not implemented yet.
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButtonFill,
                foregroundColor: AppColors.textOnLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
              ),
              child: const Text('Create tailored CV',
                  style: AppTextStyles.buttonDark),
            ),
          ),
        ],
      ),
    );
  }
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