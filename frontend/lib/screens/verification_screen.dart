import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart'; // Added import for PinCodeTextField
import '../providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .verifyCode(_codeController.text);

      // Safe navigation with proper mounted check
      if (!mounted) return;
      Navigator.pushNamed(context, '/account-type');
    } catch (error) {
      // Safe error display with proper mounted check
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      // Safe state update
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BALLOUCHI'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Validation E-mail',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Entez votre code à 4 chiffres'),
            const SizedBox(height: 30),
            PinCodeTextField( // Properly imported widget
              appContext: context,
              length: 4,
              controller: _codeController,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 50,
                activeFillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {},
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Resend code logic
              },
              child: const Text('Renvoyer le code'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}