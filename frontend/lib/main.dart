import 'package:flutter/material.dart';
import 'package:frontend/screens/signin_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/verification_screen.dart';
import 'package:frontend/screens/account_type_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/account-type': (context) => const AccountTypeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}