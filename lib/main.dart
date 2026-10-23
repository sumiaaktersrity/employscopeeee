import 'package:employscope/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:employscope/config/api_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:employscope/app_theme.dart'; // adjust path if app_theme.dart is elsewhere

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env'); // must run before ApiConfig is read
  debugPrint('SUPABASE_URL = "${ApiConfig.supabaseUrl}"');
  debugPrint('anon key length = ${ApiConfig.supabaseAnonKey.length}');
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );
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

/// Landing colors (blue + purple), kept here so app_theme.dart stays untouched.
class _LandingColors {
  _LandingColors._();

  static const Color navy = AppColors.drawerFill; // 0xFF14233A
  static const Color purple = Color(0xFF5F5792); // eyeballed from reference

  // Page background, diagonal top-left -> bottom-right.
  static const LinearGradient page = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, purple],
    stops: [0.0, 1.0],
  );

  // Tint over the photo so it blends with the page and keeps text readable.
  static final LinearGradient photoTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      navy.withOpacity(0),
      purple.withOpacity(0),
      navy.withOpacity(0),
    ],
    stops: const [0.0, 0.55, 1.0],
  );
}

// This is below MaterialApp, so its context can access the Navigator.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Swap for your own image and list it under flutter > assets in pubspec.yaml.
  static const String photoAsset = 'assets/image.png';

  @override
  Widget build(BuildContext context) {
    final photoWidth = MediaQuery.of(context).size.width - 32; // 16px side inset

    return Scaffold(
      backgroundColor: _LandingColors.navy,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _LandingColors.page),
        child: Column(
          children: [
            // Photo covering most of the page with big oval bottom corners.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                // Straight sides, shallow wide curve across the whole bottom.
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(photoWidth / 2, 70),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      photoAsset,
                      fit: BoxFit.cover,
                      // Plain navy until the real image is added.
                      errorBuilder: (_, __, ___) =>
                          Container(color: _LandingColors.navy),
                    ),
                    Container(
                      decoration:
                          BoxDecoration(gradient: _LandingColors.photoTint),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(78, 58, 58, 58),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           
                            Text(
                              'EmployScope',
                              style: AppTextStyles.logo.copyWith(fontSize: 24),
                                     
                            ),
                            const SizedBox(height: 30),
                            
                            Text(
                              '     Tailor your CV,\n     tailor your career',
                               style: GoogleFonts.getFont(
            'IBM Plex Serif',
            color: const Color.fromARGB(255, 247, 247, 248),
            fontSize: 17,
            
            //fontFamily: 
          ),
                            ),
                            const SizedBox(height: 70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // Buttons in the gradient strip under the photo.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
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
                            backgroundColor: AppColors.primaryButtonFill,
                            foregroundColor: AppColors.textOnLight,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pillButton),
                            ),
                          ),
                          child: const Text('LOGIN',
                              style: AppTextStyles.buttonDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 52,
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
                              color: AppColors.secondaryButtonBorder,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pillButton),
                            ),
                          ),
                          child: const Text('SIGN UP',
                              style: AppTextStyles.buttonLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}