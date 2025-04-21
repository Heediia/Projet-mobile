import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() => _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commerceNameController = TextEditingController();
  final _commerceTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _commerceNameController.dispose();
    _commerceTypeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    try {
      await Provider.of<AuthProvider>(context, listen: false).completeMerchantRegistration(
        commerceName: _commerceNameController.text,
        commerceType: _commerceTypeController.text,
        address: _addressController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/merchant-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Informations du commerce',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _commerceNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du commerce',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.store, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true 
                                ? 'Veuillez entrer le nom' 
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _commerceTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Type de commerce',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.category, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true 
                                ? 'Veuillez entrer le type' 
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.location_on, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true 
                                ? 'Veuillez entrer l\'adresse' 
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.phone, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true 
                                ? 'Veuillez entrer le téléphone' 
                                : null,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Valider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}