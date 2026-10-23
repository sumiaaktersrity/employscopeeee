import 'package:employscope/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, AuthException;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter your email and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Container(// main body
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

          child: Center(// center the login form
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
        Text(
          'Login',
         style: TextStyle(
    fontSize: 20,
    color: const Color.fromARGB(195, 175, 171, 197),
  ),
        ),

                  const SizedBox(
                    height: 12,
                  ),

                 

                  const SizedBox(
                    height: 45,
                  ),

                 
                  TextField(
  controller: _emailCtrl,
  keyboardType: TextInputType.emailAddress,
  decoration: InputDecoration(
    hintText: 'Enter your email',
    hintStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    
  ),
),


TextField(
  controller: _passCtrl,
  obscureText: true,
  decoration: InputDecoration(
    hintText: 'Enter your password',
    hintStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    
  ),
),

 

                  const SizedBox(
                    height: 20,
                  ),

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
                          borderRadius:
                              BorderRadius.circular(15),
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
                ],
              ),
            ),
          ),
        ),
      )
    ;    
  }
}