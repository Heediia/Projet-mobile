import 'package:flutter/material.dart';
import 'package:frontend/screens/signin_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/verification_screen.dart';
import 'package:frontend/screens/account_type_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/merchant_registration_screen.dart';
import 'package:frontend/screens/client_location_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/welcome_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ballouchi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/account-type': (context) => const AccountTypeScreen(),
        '/merchant-registration': (context) => const MerchantRegistrationScreen(),
       '/client-location': (context) => const ClientLocationScreen(),
       
       



      },
      debugShowCheckedModeBanner: false,
    );
  }
}