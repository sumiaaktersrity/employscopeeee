import 'dart:convert';
import 'package:employscope/config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app_theme.dart';

/// Bearer token from the current Supabase session (what requireUser expects).
Map<String, String> authHeaders() {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  if (token == null) {
    throw Exception('You are not logged in. Please log in again.');
  }
  return {'Authorization': 'Bearer $token'};
}

class TemplateModel {
  final int id;
  final String name;
  final String? previewUrl;

  TemplateModel({required this.id, required this.name, this.previewUrl});

  factory TemplateModel.fromJson(Map<String, dynamic> j) => TemplateModel(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        previewUrl: j['previewUrl'] as String?,
      );
}

class Saved extends StatefulWidget {
  /// When true, tapping a template closes the screen and returns it.
  final bool pickMode;
  const Saved({super.key, this.pickMode = false});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  late Future<List<TemplateModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchTemplates();
  }

  // ---------- API calls ----------

  Uri _u([String path = '']) =>
      Uri.parse('${ApiConfig.baseUrl}/api/templates$path');

  String _err(http.Response r) {
    try {
      return (jsonDecode(r.body)['error'] ?? r.body).toString();
    } catch (_) {
      return 'Request failed (${r.statusCode})';
    }
  }

  Future<List<TemplateModel>> _fetchTemplates() async {
    final r = await http.get(_u(), headers: authHeaders());
    if (r.statusCode != 200) throw Exception(_err(r));
    return (jsonDecode(r.body) as List)
        .map((e) => TemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _createTemplate(String name, PlatformFile file) async {
    final bytes = await file.readAsBytes(); // file_picker 12+: no withData
    final req = http.MultipartRequest('POST', _u())
      ..headers.addAll(authHeaders()) // no Content-Type: http sets it
      ..fields['name'] = name
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: file.name));
    final r = await http.Response.fromStream(await req.send());
    if (r.statusCode != 201) throw Exception(_err(r));
  }

  Future<void> _removeTemplate(int id) async {
    final r = await http.delete(_u('/$id'), headers: authHeaders());
    if (r.statusCode != 200) throw Exception(_err(r));
  }

  // ---------- UI actions ----------

  void _reload() {
    setState(() {
      _future = _fetchTemplates();
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addTemplate() async {
    // file_picker 12+: FilePicker.pickFile returns PlatformFile? directly
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;

    final controller =
        TextEditingController(text: file.name.split('.').first);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.drawerFill,
        title: const Text('Template name',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: AppDecorations.underlineInput('Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // controller.dispose();
    if (name == null || name.isEmpty) return;

    try {
      await _createTemplate(name, file);
      _reload();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTemplate(TemplateModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.drawerFill,
        title: const Text('Delete template?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(t.name, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _removeTemplate(t.id);
      _reload();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        title: Text('EmployScope', style: AppTextStyles.logo),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big "+" box
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  onTap: _addTemplate,
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    alignment: Alignment.center,
                    decoration: AppDecorations.card(),
                    child: const Icon(Icons.add,
                        size: 44, color: AppColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 10),

                 Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 10),
                  child: Text(
                      widget.pickMode
                          ? 'Tap a template to use it, or add a new one'
                          : 'Add template',
                      style: AppTextStyles.sectionHeading),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: AppDecorations.card(),
                    child: FutureBuilder<List<TemplateModel>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  snap.error
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body,
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _reload,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        final items = snap.data!;
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No templates yet. Tap + to add one.',
                                style: AppTextStyles.body),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, i) => _card(items[i]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(TemplateModel t) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.smallCard),
      onTap: () {
        if (widget.pickMode) Navigator.pop(context, t);
      },
      child: Container(
        height: 80,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16, right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadii.smallCard),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            t.previewUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      t.previewUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.accentGap),
                    ),
                  )
                : const Icon(Icons.description_outlined,
                    color: AppColors.accentInfo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.name,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.accentGap),
              onPressed: () => _deleteTemplate(t),
            ),
          ],
        ),
      ),
    );
  }
}