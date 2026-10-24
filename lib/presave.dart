import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:employscope/config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app_theme.dart'; // AppColors, AppTextStyles, AppRadii, AppDecorations

/// Colors taken from the dashboard screen (navy -> purple -> lavender).
class _PreColors {
  _PreColors._();

  static const Color navy = Color.fromARGB(255, 4, 27, 45);

  static const LinearGradient page = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 4, 27, 45),
      Color.fromARGB(255, 45, 49, 74),
      Color.fromARGB(255, 72, 66, 128),
      Color.fromARGB(255, 169, 167, 215),
    ],
  );

  static const Color glassFill = Color(0x1AFFFFFF); // white ~10%
  static const Color glassBorder = Color(0x40FFFFFF); // white ~25%
}

class _EduRow {
  final degree = TextEditingController();
  final institution = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final gpa = TextEditingController();

  bool get isEmpty =>
      degree.text.trim().isEmpty &&
      institution.text.trim().isEmpty &&
      start.text.trim().isEmpty &&
      end.text.trim().isEmpty &&
      gpa.text.trim().isEmpty;

  void dispose() {
    degree.dispose();
    institution.dispose();
    start.dispose();
    end.dispose();
    gpa.dispose();
  }
}

class _Contact {
  _Contact(String labelText, {this.fixed = false, this.type})
      : label = TextEditingController(text: labelText);

  final TextEditingController label;
  final TextEditingController value = TextEditingController();
  final bool fixed; // fixed = Phone/Email/GitHub/LinkedIn, label not editable
  final TextInputType? type;

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class PresavePage extends StatefulWidget {
  const PresavePage({super.key});

  @override
  State<PresavePage> createState() => _PresavePageState();
}

class _PresavePageState extends State<PresavePage> {
  // Which section is currently being edited. Nothing is editable until the
  // pencil on that section is pressed.
  bool _editName = false;
  bool _editPhoto = false;
  bool _editBio = false;
  bool _editEdu = false;
  bool _editContact = false;
  bool _editAddress = false;
  bool _editSkills = false;
  bool _editExp = false;
  bool _editPart = false;

  Uint8List? _photoBytes; // newly picked photo, uploaded when Save is pressed

  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _address = TextEditingController();

  final List<_EduRow> _edu = [];
  final List<_Contact> _contacts = [
    _Contact('Phone', fixed: true, type: TextInputType.phone),
    _Contact('Email', fixed: true, type: TextInputType.emailAddress),
    _Contact('GitHub', fixed: true, type: TextInputType.url),
    _Contact('LinkedIn', fixed: true, type: TextInputType.url),
  ];
  final List<TextEditingController> _skills = [];
  final List<TextEditingController> _experiences = [];
  final List<TextEditingController> _participations = [];

  @override
  void dispose() {
    _bio.dispose();
    _address.dispose();
    _name.dispose();
    for (final e in _edu) {
      e.dispose();
    }
    for (final c in _contacts) {
      c.dispose();
    }
    for (final c in [..._skills, ..._experiences, ..._participations]) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------- backend wiring

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _photoUrl; // signed link from the server
  String _photoName = 'photo.jpg';
  bool _removePhoto = false;
  String _accountEmail = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _headers({bool json = false}) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) throw 'You are not logged in. Please log in again.';
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  String _apiError(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {}
    return 'Server error (${r.statusCode})';
  }

  String _errText(Object e) => e.toString();
  List<String> _strings(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  void _fillList(List<TextEditingController> target, dynamic src) {
    for (final c in target) {
      _later(c.dispose);
    }
    target.clear();
    for (final s in _strings(src)) {
      target.add(TextEditingController(text: s));
    }
  }

  void _applyProfile(Map<String, dynamic> d) {
    _bio.text = (d['bio'] ?? '').toString();
    _address.text = (d['address'] ?? '').toString();
    _name.text = (d['name'] ?? '').toString();
    _accountEmail = (d['email'] ?? '').toString();
    _photoUrl = d['photoUrl']?.toString();
    _photoBytes = null;
    _removePhoto = false;

    // Education rows
    for (final r in _edu) {
      _later(r.dispose);
    }
    _edu.clear();
    final edu = d['education'];
    if (edu is List) {
      for (final e in edu) {
        if (e is! Map) continue;
        final row = _EduRow();
        row.degree.text = (e['degree'] ?? '').toString();
        row.institution.text = (e['institution'] ?? '').toString();
        row.start.text = (e['start'] ?? '').toString();
        row.end.text = (e['end'] ?? '').toString();
        row.gpa.text = (e['gpa'] ?? '').toString();
        _edu.add(row);
      }
    }

    // Contacts: saved values go into the fixed rows when the label matches,
    // everything else becomes a custom "other" row.
    for (final c in _contacts) {
      if (c.fixed) c.value.clear();
    }
    _contacts.removeWhere((c) {
      if (!c.fixed) _later(c.dispose);
      return !c.fixed;
    });
    final contacts = d['contacts'];
    if (contacts is List) {
      for (final e in contacts) {
        if (e is! Map) continue;
        final label = (e['label'] ?? '').toString();
        final value = (e['value'] ?? '').toString();
        if (value.isEmpty) continue;
        final match = _contacts.where(
            (c) => c.fixed && c.label.text.toLowerCase() == label.toLowerCase());
        if (match.isNotEmpty) {
          match.first.value.text = value;
        } else {
          final c = _Contact(label);
          c.value.text = value;
          _contacts.add(c);
        }
      }
    }
    // No saved email yet: start from the account email.
    final emailRow =
        _contacts.firstWhere((c) => c.fixed && c.label.text == 'Email');
    if (emailRow.value.text.isEmpty) emailRow.value.text = _accountEmail;

    _fillList(_skills, d['skills']);
    _fillList(_experiences, d['experiences']);
    _fillList(_participations, d['participations']);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/profile'),
              headers: _headers())
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw _apiError(res);
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _applyProfile(d));
    } catch (e) {
      if (mounted) setState(() => _loadError = _errText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!,
                textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(
                    color: AppColors.secondaryButtonBorder, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Controllers are disposed after the next frame so a TextField that is
  // still on screen never touches an already-disposed controller.
  void _later(VoidCallback f) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => f());

  void _pruneList(List<TextEditingController> list) {
    list.removeWhere((c) {
      final empty = c.text.trim().isEmpty;
      if (empty) _later(c.dispose);
      return empty;
    });
  }

  void _pruneEdu() {
    _edu.removeWhere((r) {
      if (r.isEmpty) _later(r.dispose);
      return r.isEmpty;
    });
  }

  void _pruneContacts() {
    _contacts.removeWhere((c) {
      final drop = !c.fixed && c.value.text.trim().isEmpty;
      if (drop) _later(c.dispose);
      return drop;
    });
  }

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name;
      _removePhoto = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    // Close every section first so empty entries are cleaned up.
    setState(() {
      _editName = _editPhoto = _editBio = _editAddress = false;
      _editEdu = _editContact = _editSkills = _editExp = _editPart = false;
      _pruneEdu();
      _pruneContacts();
      _pruneList(_skills);
      _pruneList(_experiences);
      _pruneList(_participations);
      _saving = true;
    });

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'bio': _bio.text.trim(),
      'address': _address.text.trim(),
      'education': [
        for (final r in _edu)
          {
            'degree': r.degree.text.trim(),
            'institution': r.institution.text.trim(),
            'start': r.start.text.trim(),
            'end': r.end.text.trim(),
            'gpa': r.gpa.text.trim(),
          }
      ],
      'contacts': [
        for (final c in _contacts)
          if (c.value.text.trim().isNotEmpty)
            {'label': c.label.text.trim(), 'value': c.value.text.trim()}
      ],
      'skills': [for (final c in _skills) c.text.trim()],
      'experiences': [for (final c in _experiences) c.text.trim()],
      'participations': [for (final c in _participations) c.text.trim()],
      if (_removePhoto) 'removePhoto': true,
    };

    try {
      final res = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/api/profile'),
            headers: _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw _apiError(res);
      _removePhoto = false;

      // A newly picked photo is uploaded as part of Save.
      String? photoError;
      if (_photoBytes != null) {
        try {
          final req = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/api/profile/photo'),
          )
            ..headers.addAll(_headers())
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              _photoBytes!,
              filename: _photoName,
            ));
          final streamed = await req.send().timeout(const Duration(seconds: 60));
          final pr = await http.Response.fromStream(streamed);
          if (pr.statusCode != 200) throw _apiError(pr);
          final url = (jsonDecode(pr.body) as Map)['photoUrl']?.toString();
          if (mounted) {
            setState(() {
              _photoUrl = url;
              _photoBytes = null;
            });
          }
        } catch (e) {
          photoError = e is String ? e : 'Could not upload the photo.';
        }
      }

      _snack(photoError == null
          ? 'Saved.'
          : 'Saved, but the photo was not uploaded: $photoError');
    } catch (e) {
      _snack(_errText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PreColors.navy,
      appBar: AppBar(
        backgroundColor: _PreColors.navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text('EmployScope', style: AppTextStyles.logo),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _PreColors.page),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _loadError != null
                  ? _errorView()
                  : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pre Saved Information',
                    style: AppTextStyles.screenTitle),
                const SizedBox(height: 6),
                const Text(
                  'Tap the pencil on a section to change it.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 18),
                _namePane(),
                _photoPane(),
                _bioPane(),
                _educationPane(),
                _contactPane(),
                _addressPane(),
                _listPane(
                  title: 'Skills',
                  hint: 'Skill (e.g. Flutter)',
                  addLabel: 'Add skill',
                  items: _skills,
                  editing: _editSkills,
                  onToggle: () => setState(() {
                    if (_editSkills) _pruneList(_skills);
                    _editSkills = !_editSkills;
                  }),
                ),
                _listPane(
                  title: 'Experiences',
                  hint: 'Role, employer, dates, what you did',
                  addLabel: 'Add experience',
                  items: _experiences,
                  editing: _editExp,
                  maxLines: 4,
                  onToggle: () => setState(() {
                    if (_editExp) _pruneList(_experiences);
                    _editExp = !_editExp;
                  }),
                ),
                _listPane(
                  title: 'Participations',
                  hint: 'Club, event, volunteering, competition',
                  addLabel: 'Add participation',
                  items: _participations,
                  editing: _editPart,
                  maxLines: 3,
                  onToggle: () => setState(() {
                    if (_editPart) _pruneList(_participations);
                    _editPart = !_editPart;
                  }),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButtonFill,
                      foregroundColor: AppColors.textOnLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pillButton),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnLight,
                            ),
                          )
                        : const Text('Save', style: AppTextStyles.buttonDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------- shared pieces

  /// Glass pane: blurred, translucent, hairline border, title + edit pencil.
  Widget _pane({
    required String title,
    required bool editing,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 18),
            decoration: BoxDecoration(
              color: _PreColors.glassFill,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: _PreColors.glassBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyles.sectionHeading),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: editing ? 'Done' : 'Edit',
                      icon: Icon(
                        editing ? Icons.check : Icons.edit_outlined,
                        size: 18,
                        color: editing
                            ? AppColors.accentGood
                            : AppColors.textSecondary,
                      ),
                      onPressed: onToggle,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    TextInputType? type,
  }) {
    return TextField(
      key: ObjectKey(c),
      controller: c,
      maxLines: maxLines,
      minLines: 1,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: AppDecorations.underlineInput(hint),
    );
  }

  Widget _viewText(String text, String empty) {
    final t = text.trim();
    return Text(
      t.isEmpty ? empty : t,
      style: t.isEmpty ? AppTextStyles.caption : AppTextStyles.body,
    );
  }

  Widget _addButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(foregroundColor: AppColors.accentInfo),
      ),
    );
  }

  Widget _removeButton(VoidCallback onPressed) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: 'Remove',
      icon: const Icon(Icons.close, size: 18, color: AppColors.accentGap),
      onPressed: onPressed,
    );
  }

  // ---------------------------------------------------------------- name

  Widget _namePane() {
    return _pane(
      title: 'Name',
      editing: _editName,
      onToggle: () => setState(() => _editName = !_editName),
      child: _editName
          ? _input(_name, 'Full name (shown at the top of your CV)')
          : _viewText(_name.text, 'No name yet'),
    );
  }

  // --------------------------------------------------------------- photo

  Widget _photoPane() {
    return _pane(
      title: 'Photo',
      editing: _editPhoto,
      onToggle: () => setState(() => _editPhoto = !_editPhoto),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(AppRadii.smallCard),
              border: Border.all(color: _PreColors.glassBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoBytes != null
                ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                : (_photoUrl != null
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_outline,
                            size: 48,
                            color: AppColors.textPlaceholder),
                      )
                    : const Icon(Icons.person_outline,
                        size: 48, color: AppColors.textPlaceholder)),
          ),
          if (_editPhoto) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_outlined, size: 18),
                  label: Text((_photoBytes == null && _photoUrl == null)
                      ? 'Choose photo'
                      : 'Change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                        color: AppColors.secondaryButtonBorder, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
                if (_photoBytes != null || _photoUrl != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _photoBytes = null;
                      _photoUrl = null;
                      _removePhoto = true;
                    }),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentGap),
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- bio

  Widget _bioPane() {
    return _pane(
      title: 'Bio',
      editing: _editBio,
      onToggle: () => setState(() => _editBio = !_editBio),
      child: _editBio
          ? _input(_bio, 'A short summary about you (2 to 4 lines)',
              maxLines: 5)
          : _viewText(_bio.text, 'No bio yet'),
    );
  }

  // ----------------------------------------------------------- education

  Widget _educationPane() {
    return _pane(
      title: 'Education',
      editing: _editEdu,
      onToggle: () => setState(() {
        if (_editEdu) _pruneEdu();
        _editEdu = !_editEdu;
      }),
      child: _editEdu ? _educationEdit() : _educationView(),
    );
  }

  Widget _educationView() {
    final rows = _edu.where((r) => !r.isEmpty).toList();
    if (rows.isEmpty) return _viewText('', 'No education added yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [r.degree.text.trim(), r.institution.text.trim()]
                      .where((s) => s.isNotEmpty)
                      .join(', '),
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  [
                    if (r.start.text.trim().isNotEmpty ||
                        r.end.text.trim().isNotEmpty)
                      '${r.start.text.trim()} - ${r.end.text.trim()}',
                    if (r.gpa.text.trim().isNotEmpty)
                      'GPA ${r.gpa.text.trim()}',
                  ].join('  |  '),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _educationEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _edu.length; i++)
          Container(
            key: ObjectKey(_edu[i]),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(AppRadii.smallCard),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _removeButton(() => setState(() {
                        final row = _edu.removeAt(i);
                        _later(row.dispose);
                      })),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      _input(_edu[i].degree, 'Degree (e.g. BSc in CSE)'),
                      const SizedBox(height: 6),
                      _input(_edu[i].institution, 'Institution'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _input(_edu[i].start, 'Start')),
                          const SizedBox(width: 10),
                          Expanded(child: _input(_edu[i].end, 'End')),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _input(_edu[i].gpa, 'GPA',
                                type: TextInputType.number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        _addButton('Add education', () => setState(() => _edu.add(_EduRow()))),
      ],
    );
  }

  // ------------------------------------------------------------- contact

  Widget _contactPane() {
    return _pane(
      title: 'Contact details',
      editing: _editContact,
      onToggle: () => setState(() {
        if (_editContact) _pruneContacts();
        _editContact = !_editContact;
      }),
      child: _editContact ? _contactEdit() : _contactView(),
    );
  }

  Widget _contactView() {
    final filled =
        _contacts.where((c) => c.value.text.trim().isNotEmpty).toList();
    if (filled.isEmpty) return _viewText('', 'No contact details yet');

    return Column(
      children: [
        for (final c in filled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(c.label.text.trim(), style: AppTextStyles.caption),
                ),
                Expanded(
                  child: Text(c.value.text.trim(), style: AppTextStyles.body),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contactEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _contacts.length; i++)
          Padding(
            key: ObjectKey(_contacts[i]),
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 96,
                  child: _contacts[i].fixed
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_contacts[i].label.text,
                              style: AppTextStyles.caption),
                        )
                      : _input(_contacts[i].label, 'Label'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _input(_contacts[i].value, 'Value',
                      type: _contacts[i].type),
                ),
                if (!_contacts[i].fixed)
                  _removeButton(() => setState(() {
                        final c = _contacts.removeAt(i);
                        _later(c.dispose);
                      }))
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        const SizedBox(height: 4),
        _addButton('Add other', () => setState(() => _contacts.add(_Contact(''))))
      ],
    );
  }

  // ------------------------------------------------------------- address

  Widget _addressPane() {
    return _pane(
      title: 'Address',
      editing: _editAddress,
      onToggle: () => setState(() => _editAddress = !_editAddress),
      child: _editAddress
          ? _input(_address, 'Address', maxLines: 2)
          : _viewText(_address.text, 'No address yet'),
    );
  }

  // ----------------------------------- skills / experiences / participations

  Widget _listPane({
    required String title,
    required String hint,
    required String addLabel,
    required List<TextEditingController> items,
    required bool editing,
    required VoidCallback onToggle,
    int maxLines = 1,
  }) {
    return _pane(
      title: title,
      editing: editing,
      onToggle: onToggle,
      child: editing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Row(
                    key: ObjectKey(items[i]),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _input(items[i], hint, maxLines: maxLines),
                      ),
                      _removeButton(() => setState(() {
                            final c = items.removeAt(i);
                            _later(c.dispose);
                          })),
                    ],
                  ),
                const SizedBox(height: 4),
                _addButton(addLabel, () {
                  setState(() => items.add(TextEditingController()));
                }),
              ],
            )
          : _listView(items),
    );
  }

  Widget _listView(List<TextEditingController> items) {
    final filled = items.where((c) => c.text.trim().isNotEmpty).toList();
    if (filled.isEmpty) return _viewText('', 'Nothing added yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in filled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 10),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: AppColors.accentInfo,
                  ),
                ),
                Expanded(
                  child: Text(c.text.trim(), style: AppTextStyles.body),
                ),
              ],
            ),
          ),
      ],
    );
  }
}