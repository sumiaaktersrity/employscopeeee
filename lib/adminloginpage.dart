
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'adminui.dart';
import 'services/api_client.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _adminIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _adminIdCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _login() async {
    final adminId = _adminIdCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (adminId.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Fill in all fields');
      return;
    }

    setState(() => _loading = true);

    final supabase = Supabase.instance.client;

    try {
      // Step 1: Authenticate using Supabase email/password.
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      if (res.user == null) {
        throw const AuthException('Login failed');
      }

      // Step 2: Ask the backend to verify the user's admin role.
      // ApiClient automatically attaches the Supabase access token.
      final response = await ApiClient.dio.get('/jobs/admin/me');

      final returnedAdminId =
          response.data['adminId'].toString();

      // Step 3: Compare the typed Admin ID with public.User.id.
      if (returnedAdminId != adminId) {
        await supabase.auth.signOut();
        _snack('Invalid admin credentials');
        return;
      }

      // Step 4: Open the admin panel only after both checks pass.
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminUI()),
      );
    } on AuthException catch (e) {
      _snack(e.message);
    } on DioException catch (e) {
      await supabase.auth.signOut();
      _snack(ApiClient.messageFrom(e));
    } catch (e) {
      await supabase.auth.signOut();
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter Admin ID No.',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter admin email',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _loading ? null : _login(),
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
                      onPressed: _loading ? null : _login,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
