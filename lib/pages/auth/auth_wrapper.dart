import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'phone_input_page.dart';
import 'welcome_page.dart';
import '../main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB74D),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, check if they have a profile
          return FutureBuilder<bool>(
            future: AuthService().userExistsInFirestore(snapshot.data!.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                );
              }

              // If there's an error or no data, assume user needs to complete profile
              if (profileSnapshot.hasError || !profileSnapshot.hasData) {
                print('⚠️ [AUTH] Error checking user profile: ${profileSnapshot.error}');
                // Show phone input to start auth flow
                return const PhoneInputPage();
              }

              if (profileSnapshot.data == true) {
                // User has a profile, show main app
                return const MainNavigation();
              } else {
                // User doesn't have a profile, show phone input to start auth flow
                return const PhoneInputPage();
              }
            },
          );
        }

        // User is not signed in, show welcome page
        return const WelcomePage();
      },
    );
  }
} 