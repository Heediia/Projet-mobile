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
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType == 'commerçant'
                  ? Colors.green
                  : null, // Green if selected, default otherwise
            ),
            onPressed: () => _selectAccountType(context, 'commerçant'),
            child: const Text('Commerçant'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedType == 'client' ? Colors.green : null,
            ),
            onPressed: () => _selectAccountType(context, 'client'),
            child: const Text('Client'),
          ),
        ],
      ),
    );
  }
}
