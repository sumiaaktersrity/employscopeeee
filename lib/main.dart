import 'package:employscope/signup.dart';
import 'package:flutter/material.dart';
import '/login.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: const HomePage(),
    );
  }
}


// This is now BELOW MaterialApp
// So its context can access the Navigator.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 27, 45),
        title:  Text(
          'EmployScope',
         style: GoogleFonts.playwriteBeWal(
    fontSize: 15,
    color: const Color.fromARGB(195, 175, 171, 197),
  ),
        ),
      ),
      

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
          child: Container(
            width: 350,

            padding: const EdgeInsets.all(35),

            decoration: BoxDecoration(
              color: const Color.fromARGB(150, 20, 35, 50),

              borderRadius: BorderRadius.circular(30),

              border: Border.all(
                color: Colors.white30,
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
          'EmployScope',
         style: GoogleFonts.playwriteBeWal(
    fontSize: 15,
    color: const Color.fromARGB(195, 175, 171, 197),
  ),
        ),
                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'Your gateway to career success',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(
                  height: 45,
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          const Color.fromARGB(255, 4, 27, 45),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Signup(),
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
                      'SIGN UP',
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
    );
  }
}