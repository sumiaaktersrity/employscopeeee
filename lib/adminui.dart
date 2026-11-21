
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_client.dart';

class AdminUI extends StatefulWidget {
  const AdminUI({super.key});

  @override
  State<AdminUI> createState() => _AdminUIState();
}

class _AdminUIState extends State<AdminUI> {
  List<Map<String, dynamic>> reports = [];
  bool loading = true;
  bool actionLoading = false;
  String? loadError;

  static const Color navy = Color.fromARGB(255, 4, 27, 45);
  static const Color deepPurple = Color.fromARGB(220, 45, 49, 74);
  static const Color lavender = Color.fromARGB(255, 199, 190, 229);
  static const Color paleLavender = Color.fromARGB(195, 175, 171, 197);

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final response = await ApiClient.dio.get('/api/jobs/admin/reports');
      final raw = response.data['reports'] as List<dynamic>? ?? [];

      if (!mounted) return;

      setState(() {
        reports = raw
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = ApiClient.messageFrom(e);
      });
    }
  }

  int get reportsToday {
    final now = DateTime.now();

    return reports.where((report) {
      final raw = report['createdAt'];
      if (raw == null) return false;

      final date = DateTime.tryParse(raw.toString())?.toLocal();
      if (date == null) return false;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  void snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: deepPurple,
        content: Text(
          message,
          style: GoogleFonts.getFont('IBM Plex Serif', color: Colors.white),
        ),
      ),
    );
  }

  Future<void> ignoreReport(int reportId) async {
    await performAction(
      reportId,
      '/api/jobs/admin/reports/$reportId/ignore',
      'Report ignored.',
    );
  }

  Future<void> removeJob(int reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: deepPurple,
        title: Text('Remove Job?', style: headingStyle(20)),
        content: Text(
          'This will deactivate the job and mark every report against it as Removed. The job will no longer be available to users.',
          style: bodyStyle(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'REMOVE JOB',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await performAction(
      reportId,
      '/api/jobs/admin/reports/$reportId/remove-job',
      'Job removed. All reports for this job have been marked Removed.',
    );
  }

  Future<void> performAction(
    int reportId,
    String endpoint,
    String successMessage,
  ) async {
    if (actionLoading) return;

    setState(() => actionLoading = true);

    try {
      await ApiClient.dio.patch(endpoint);
      snack(successMessage);
      await fetchReports();
    } catch (e) {
      snack(ApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  TextStyle headingStyle(double size) {
    return GoogleFonts.getFont(
      'IBM Plex Serif',
      color: lavender,
      fontSize: size,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle bodyStyle(double size) {
    return GoogleFonts.getFont(
      'IBM Plex Serif',
      color: Colors.white,
      fontSize: size,
    );
  }

  Widget glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(100, 58, 55, 84),
            Color.fromARGB(75, 45, 49, 74),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(100, 202, 190, 231),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Expanded(
      child: glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: paleLavender, size: 27),
            const SizedBox(height: 12),
            Text(value, style: headingStyle(27)),
            const SizedBox(height: 5),
            Text(title, style: bodyStyle(13)),
          ],
        ),
      ),
    );
  }

  Widget reportCard(Map<String, dynamic> report) {
    final status = (report['status'] ?? 'Pending').toString();
    final pending = status == 'Pending';

    final reportId = report['id'] is int
        ? report['id'] as int
        : int.tryParse(report['id'].toString());

    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (report['jobTitle'] ?? 'Unknown job').toString(),
                  style: headingStyle(19),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: pending
                      ? Colors.orangeAccent
                      : status == 'Removed'
                          ? Colors.redAccent
                          : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            (report['company'] ?? 'Unknown company').toString(),
            style: bodyStyle(14),
          ),

          const SizedBox(height: 18),
          Text('JOB DESCRIPTION', style: headingStyle(13)),
          const SizedBox(height: 7),
          Text(
            (report['description'] ?? 'No description available').toString(),
            style: bodyStyle(14).copyWith(height: 1.5),
          ),

          const SizedBox(height: 18),
          Text('REASON FOR REPORT', style: headingStyle(13)),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(70, 4, 27, 45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(100, 202, 190, 231),
              ),
            ),
            child: Text(
              (report['reason'] ?? '').toString(),
              style: bodyStyle(14).copyWith(height: 1.5),
            ),
          ),

          const SizedBox(height: 16),
          Text('REPORTED BY', style: headingStyle(13)),
          const SizedBox(height: 5),
          Text(
            (report['email'] ?? 'Unknown reporter').toString(),
            style: GoogleFonts.getFont(
              'IBM Plex Serif',
              color: const Color.fromARGB(255, 255, 130, 145),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (pending && reportId != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: actionLoading ? null : () => ignoreReport(reportId),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(60, 58, 55, 84),
                      foregroundColor: lavender,
                      side: const BorderSide(
                        color: Color.fromARGB(180, 202, 190, 231),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      'IGNORE',
                      style: GoogleFonts.getFont(
                        'IBM Plex Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: actionLoading ? null : () => removeJob(reportId),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(80, 120, 35, 55),
                      foregroundColor: Colors.redAccent.shade100,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      'REMOVE',
                      style: GoogleFonts.getFont(
                        'IBM Plex Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: paleLavender,
        elevation: 0,
        title: Text(
          'EmployScope',
          style: GoogleFonts.playwriteBeWal(
            fontSize: 15,
            color: paleLavender,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : fetchReports,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 4, 27, 45),
              Color.fromARGB(220, 45, 49, 74),
              Color.fromARGB(220, 72, 66, 128),
              Color.fromARGB(220, 169, 167, 215),
            ],
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Dashboard', style: headingStyle(27)),
                    const SizedBox(height: 6),
                    Text(
                      'Manage users and reported job posts',
                      style: bodyStyle(13),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        statCard(
                          'Total Reports',
                          reports.length.toString(),
                          Icons.flag_outlined,
                        ),
                        const SizedBox(width: 12),
                        statCard(
                          'Reports Today',
                          reportsToday.toString(),
                          Icons.today_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Text('Reported Job Posts', style: headingStyle(20)),
                    const SizedBox(height: 15),

                    if (loadError != null)
                      glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Could not load reports', style: headingStyle(17)),
                            const SizedBox(height: 8),
                            Text(loadError!, style: bodyStyle(13)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: fetchReports,
                              child: const Text('RETRY'),
                            ),
                          ],
                        ),
                      )
                    else if (reports.isEmpty)
                      glassCard(
                        child: Text(
                          'No job reports have been submitted yet.',
                          style: bodyStyle(14),
                        ),
                      )
                    else
                      ...reports.map(
                        (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: reportCard(report),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
