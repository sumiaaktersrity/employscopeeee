
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUI extends StatefulWidget {
  const AdminUI({super.key});

  @override
  State<AdminUI> createState() => _AdminUIState();
}

class _AdminUIState extends State<AdminUI> {
  // Temporary sample data. No backend connection.
  final int totalUsers = 120;
  final int reportsToday = 4;

  final List<Map<String, String>> reports = [
    {
      'jobTitle': 'Junior Flutter Developer',
      'company': 'ABC Technologies',
      'description':
          'We are looking for a junior Flutter developer to work on mobile application development. Candidates should have basic knowledge of Dart and Flutter.',
      'reason':
          'The job description appears to contain misleading information about the salary.',
      'email': 'user1@example.com',
      'status': 'Pending',
    },
    {
      'jobTitle': 'Data Entry Operator',
      'company': 'XYZ Solutions',
      'description':
          'Data entry position requiring basic computer skills and spreadsheet knowledge. Full-time position.',
      'reason':
          'The employer is asking applicants to pay a registration fee.',
      'email': 'user2@example.com',
      'status': 'Pending',
    },
    {
      'jobTitle': 'Frontend Developer Intern',
      'company': 'Tech World',
      'description':
          'Internship opportunity for frontend developers with knowledge of HTML, CSS and JavaScript.',
      'reason': 'The company information seems inaccurate.',
      'email': 'user3@example.com',
      'status': 'Pending',
    },
  ];

  static const Color navy = Color.fromARGB(255, 4, 27, 45);
  static const Color deepPurple = Color.fromARGB(220, 45, 49, 74);
  static const Color lavender = Color.fromARGB(255, 199, 190, 229);
  static const Color paleLavender = Color.fromARGB(195, 175, 171, 197);

  void updateReport(int index, String status) {
    setState(() {
      reports[index]['status'] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: deepPurple,
        content: Text(
          'Report marked as $status (local only).',
          style: GoogleFonts.getFont(
            'IBM Plex Serif',
            color: Colors.white,
          ),
        ),
      ),
    );
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

  Widget reportCard(int index) {
    final report = reports[index];
    final status = report['status']!;

    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report['jobTitle']!,
                  style: headingStyle(19),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == 'Pending'
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
          Text(report['company']!, style: bodyStyle(14)),

          const SizedBox(height: 18),
          Text('JOB DESCRIPTION', style: headingStyle(13)),
          const SizedBox(height: 7),
          Text(
            report['description']!,
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
              report['reason']!,
              style: bodyStyle(14).copyWith(height: 1.5),
            ),
          ),

          const SizedBox(height: 16),
          Text('REPORTED BY', style: headingStyle(13)),
          const SizedBox(height: 5),
          Text(
            report['email']!,
            style: GoogleFonts.getFont(
              'IBM Plex Serif',
              color: const Color.fromARGB(255, 255, 130, 145),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (status == 'Pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => updateReport(index, 'Ignored'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(60, 58, 55, 84),
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
                    onPressed: () => updateReport(index, 'Removed'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(80, 120, 35, 55),
                      foregroundColor: Colors.redAccent.shade100,
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: headingStyle(27),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage users and reported job posts',
                style: bodyStyle(13),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  statCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people_outline,
                  ),
                  const SizedBox(width: 12),
                  statCard(
                    'Reports Today',
                    reportsToday.toString(),
                    Icons.flag_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 30),
              Text(
                'Reported Job Posts',
                style: headingStyle(20),
              ),
              const SizedBox(height: 15),

              ...List.generate(
                reports.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: reportCard(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
