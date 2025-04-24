import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';

class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() => _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commerceNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  XFile? _logoImage;
  XFile? _storeImage;

  String? _selectedCommerceType;

  final List<String> _commerceTypes = [
    'Pâtisserie',
    'Boucherie',
    'Fromagerie',
    'Poissonnerie',
    'Crémerie',
    'Primeur',
    'Chocolaterie',
    'Marché',
    'Superette',
    'Hôtel',
    'Restaurant',
  ];

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = pickedFile;
        } else {
          _storeImage = pickedFile;
        }
      });
    }
  }

  @override
  void dispose() {
    _commerceNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_storeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter une image de la devanture'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    try {
      await Provider.of<AuthProvider>(context, listen: false).completeMerchantRegistration(
        commerceName: _commerceNameController.text,
        commerceType: _selectedCommerceType ?? '',
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

  Widget _buildImageUploadCard({
    required XFile? image,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.green, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Image.file(
                        File(image.path),
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            const SizedBox(height: 10),
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
                        _buildImageUploadCard(
                          image: _logoImage,
                          label: 'Logo du commerce',
                          onTap: () => _pickImage(true),
                        ),
                        const SizedBox(height: 20),
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
                          child: DropdownButtonFormField<String>(
                            value: _selectedCommerceType,
                            decoration: const InputDecoration(
                              labelText: 'Type de commerce',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.category, color: Colors.green),
                            ),
                            items: _commerceTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCommerceType = value;
                              });
                            },
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Veuillez choisir un type' : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildImageUploadCard(
                          image: _storeImage,
                          label: 'Image de la devanture',
                          onTap: () => _pickImage(false),
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
}
