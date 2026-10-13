import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import "dashboard_screen2.dart";
import 'tempatesave.dart';
//import '/login.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 4, 27, 45),
        iconTheme: const IconThemeData(
    color: Color.fromARGB(255, 84, 70, 122), // change the hamburger icon color here
  ),
        title:  Text(
          'EmployScope',
         style: GoogleFonts.playwriteBeWal(
    fontSize: 15,
    color: const Color.fromARGB(195, 175, 171, 197),
  ),
        ),
      ),

      drawer: Drawer(
    backgroundColor: const Color.fromARGB(255, 2, 24, 40),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 4, 27, 45),
                      Color.fromARGB(220, 45, 49, 74),
                    ],)
          ),
          child: Text(
            'EmployScope',
            style: GoogleFonts.playwriteBeWal(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
       ListTile(
  leading: const Icon(Icons.home, color: Colors.white),
  title: const Text('Saved Templates', style: TextStyle(color: Colors.white)),
  onTap: () {
    Navigator.pop(context); // close the drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Saved()),
    );
  },
),
        ListTile(
          leading: const Icon(Icons.description, color: Colors.white),
          title: const Text('Your Career goals', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCvPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.work, color: Colors.white),
          title: const Text('Skill Gap analysis', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ),
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            // Top section: image + title text
            Expanded(
               // more room so both lines of text fit
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 4, 27, 45),
                      Color.fromARGB(220, 45, 49, 74),
                    ],
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                   height: double.infinity,
                  
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/image.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:  [Container(

                          decoration: BoxDecoration(
                            
                            gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(69, 4, 27, 45),
                      Color.fromARGB(66, 45, 49, 74),
                    ],
                  ),

                          ),
                          child:Column(
                            children: [
                              Text(
  'EmployScope\n',
  style: GoogleFonts.playwriteBeWal(
    fontSize: 20,
    color: Colors.white,
  ),
),
Text(
  'Tailor your CV, tailor your career',
   style: GoogleFonts.getFont(
            'IBM Plex Serif',
            color: const Color.fromARGB(255, 247, 247, 248),
            fontSize: 12,
            //fontFamily: 
          ),
),
                            ]
                          ),
                        ),
                          
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Middle section
          Expanded(
  child: Container(
    alignment: Alignment.center,
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
   
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color.fromARGB(97, 58, 55, 84),
                side: const BorderSide(
                  color: Color.fromARGB(189, 202, 190, 231),
                  width: 0,
                ),
                shadowColor: const Color.fromARGB(217, 38, 39, 41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'Create CV',
                style: GoogleFonts.getFont(
                  'IBM Plex Serif',
                  color: const Color.fromARGB(255, 199, 190, 229),
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color.fromARGB(97, 58, 55, 84),
                side: const BorderSide(
                  color: Color.fromARGB(189, 202, 190, 231),
                  width: 0,
                ),
                shadowColor: const Color.fromARGB(217, 38, 39, 41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'Search Available Jobs\n',
                style: GoogleFonts.getFont(
                  'IBM Plex Serif',
                  color: const Color.fromARGB(255, 199, 190, 229),
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color.fromARGB(97, 58, 55, 84),
                side: const BorderSide(
                  color: Color.fromARGB(189, 202, 190, 231),
                  width: 0,
                ),
                shadowColor: const Color.fromARGB(217, 38, 39, 41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'Skill Gap Analysis\n',
                style: GoogleFonts.getFont(
                  'IBM Plex Serif',
                  color: const Color.fromARGB(255, 199, 190, 229),
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color.fromARGB(97, 58, 55, 84),
                side: const BorderSide(
                  color: Color.fromARGB(189, 202, 190, 231),
                  width: 0,
                ),
                shadowColor: const Color.fromARGB(217, 38, 39, 41),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                'Targeted Skills and Career Goals\n',
                style: GoogleFonts.getFont(
                  'IBM Plex Serif',
                  color: const Color.fromARGB(255, 199, 190, 229),
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
            // Bottom section
          
          ],
        ),
      ),
    );
  }
}


