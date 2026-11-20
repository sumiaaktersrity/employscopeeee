import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adminui.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _adminIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _adminIdCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 4, 27, 45),
              Color.fromARGB(220, 160, 172, 232),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: const Color.fromARGB(111, 20, 35, 50),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color.fromARGB(55, 255, 255, 255),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 25,
                    spreadRadius: 3,
                    color: Color.fromARGB(70, 0, 0, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EmployScope\n',
                    style: GoogleFonts.playwriteBeWal(
                      fontSize: 20,
                      color: const Color.fromARGB(195, 175, 171, 197),
                    ),
                  ),
                  const Text(
                    'Admin Login',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(195, 175, 171, 197),
                    ),
                  ),
                  const SizedBox(height: 35),
                  TextField(
                    controller: _adminIdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter Admin ID No.',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter admin email',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter password',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      // TEMPORARY: no credential verification or endpoint.
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminUI(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to user login',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}