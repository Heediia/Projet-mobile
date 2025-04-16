import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String? _selectedType;
  bool _showOptions = false;

  Future<void> _selectAccountType(BuildContext context, String type) async {
    setState(() {
      _selectedType = type;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .setAccountType(type);

      if (!context.mounted) return;

      Navigator.pushNamed(
        context,
        type == 'commerçant' ? '/merchant-dashboard' : '/client-dashboard',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }
  }

  Widget _buildTypeOption(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAccountType(context, type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade100),
            boxShadow: [
              BoxShadow(
               color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: isSelected ? Colors.white : Colors.green),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ballouchi_logo.png',
              height: 180,
            ),
            const SizedBox(height: 40),
            const Text(
              "Choisissez votre type de compte",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Cliquez pour afficher les options",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                setState(() {
                  _showOptions = !_showOptions;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.green.shade100),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                     color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      "Choisir un type de compte",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_showOptions)
              Row(
                children: [
                  _buildTypeOption('Client', 'client', Icons.person),
                  const SizedBox(width: 20),
                  _buildTypeOption('Commerçant', 'commerçant', Icons.storefront),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
