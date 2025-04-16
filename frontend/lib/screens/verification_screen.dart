import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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

      if (!mounted) return;
      Navigator.pushNamed(context, '/account-type');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
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
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: Image.asset(
                'assets/images/ballouchi_logo.png',
                height: 180,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Validation E-mail',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your 4-digit code',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _codeController,
                keyboardType: TextInputType.number,
                onChanged: (value) {},
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  inactiveColor: Colors.grey.shade300,
                  activeColor: Colors.green,
                  selectedColor: Colors.green,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                ),
                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Logic to resend code
              },
              child: const Text(
                'Renvoyer le code',
                style: TextStyle(color: Colors.green),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      elevation: 6,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}
