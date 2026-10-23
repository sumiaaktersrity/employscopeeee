import 'package:employscope/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, AuthException;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter an email and a password.');
      return;
    }
    setState(() => _loading = true);
    try {
      // Name is optional. When given, it is stored as user metadata.
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: name.isEmpty ? null : {'name': name},
      );
      if (!mounted) return;
      _snack(res.session == null
          ? 'Account created. Check your email to confirm, then log in.'
          : 'Account created. Please log in.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on AuthException catch (e) {
      debugPrint('SIGNUP AuthException -> message: ${e.message} | status: ${e.statusCode} | type: ${e.runtimeType}');
      _snack(e.message);
    } catch (e, st) {
      debugPrint('SIGNUP other error -> $e\n$st');
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // main body
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
          // center the signup form
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
                const Text(
                  'FILL IN THE FORM TO REGISTER',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 57,
                ),

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(
                        color: Color.fromARGB(92, 255, 255, 255)),
                  ),
                ),

                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(
                        color: Color.fromARGB(92, 255, 255, 255)),
                  ),
                ),

                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: const TextStyle(
                        color: Color.fromARGB(92, 255, 255, 255)),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: OutlinedButton(
                    onPressed: _loading ? null : _signUp,
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

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'N.B: add information in presaved information section after login to have a better experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(160, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}