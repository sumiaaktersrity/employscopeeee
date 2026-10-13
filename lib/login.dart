import 'package:employscope/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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

  decoration: InputDecoration(
    hintText: 'Enter your email',
    hintStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    
  ),
),


TextField(

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
                     onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Dashboard(),
                        ),
                      );
                    },
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