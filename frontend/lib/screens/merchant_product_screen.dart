import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MerchantProductScreen extends StatefulWidget {
  const MerchantProductScreen({super.key});

  @override
  State<MerchantProductScreen> createState() => _MerchantProductScreenState();
}

class _MerchantProductScreenState extends State<MerchantProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _productPriceController = TextEditingController();
  XFile? _productImage;

  Future<void> _pickProductImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImage = pickedFile;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter une image du produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Implémentez ici la logique pour envoyer les données au backend (produit, image, etc.)
    // Exemple : await uploadProductToBackend(_productNameController.text, _productDescriptionController.text, _productPriceController.text, _productImage);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produit ajouté avec succès'),
        backgroundColor: Colors.green,
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
            const Icon(Icons.camera_alt, color: Colors.green, size: 30),
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
                      child: Builder(
                        builder: (_) {
                          try {
                            final file = File(image.path);
                            if (file.existsSync()) {
                              return Image.file(
                                file,
                                height: 50,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return const Text(
                                'Fichier image introuvable',
                                style: TextStyle(color: Colors.red),
                              );
                            }
                          } catch (e) {
                            return const Text(
                              'Erreur de lecture de l’image',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                        },
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
                    'Ajouter un produit',
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
                            controller: _productNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du produit',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.label, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Veuillez entrer le nom du produit'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _productDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description du produit',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.description, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Veuillez entrer une description'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldCard(
                          child: TextFormField(
                            controller: _productPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prix',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Veuillez entrer le prix'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildImageUploadCard(
                          image: _productImage,
                          label: 'Image du produit',
                          onTap: _pickProductImage,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitProduct,
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
                              'Ajouter le produit',
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
