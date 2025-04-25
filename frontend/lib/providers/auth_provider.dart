import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  String? _email;
  String? _token;
  String? _accountType;
  String? _address;
  String? _commerceName;
  String? _commerceType;
  String? _phone;

  String? get email => _email;
  String? get token => _token;
  String? get accountType => _accountType;
  String? get address => _address;
  String? get commerceName => _commerceName;
  String? get commerceType => _commerceType;
  String? get phone => _phone;

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else {
      return 'http://10.0.2.2:5000';
    }
  }

  Future<void> signUp(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _email = email;
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Erreur inconnue lors de l\'inscription');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Échec de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _email = email;
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec de l\'envoi du code');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur d\'envoi du code: ${e.toString()}');
    }
  }

  Future<void> verifyCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'code': code,
        }),
      ).timeout(const Duration(seconds: 1000000)); // Ne pas toucher ici selon ta demande

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        throw HttpException(responseData['message'] ?? 'Échec de la vérification');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur de vérification: ${e.toString()}');
    }
  }

  Future<void> resendVerificationCode() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _email}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        throw HttpException(responseData['message'] ?? 'Échec du renvoi');
      }
    } catch (e) {
      throw HttpException('Erreur de renvoi: ${e.toString()}');
    }
  }

  Future<void> setAccountType(String accountType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/account-type'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'accountType': accountType,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _accountType = accountType;
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec de la définition du type de compte');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur de type de compte: ${e.toString()}');
    }
  }

  Future<void> setClientLocation({
    required String address,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/set-client-location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'address': address,
          'phone': phone, // Ajouté ici
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _address = address;
        _phone = phone; // Ajouté ici
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec de la définition de la localisation');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur de localisation: ${e.toString()}');
    }
  }

  Future<void> completeMerchantRegistration({
    required String commerceName,
    required String commerceType,
    required String address,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/complete-merchant-registration'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'commerceName': commerceName,
          'commerceType': commerceType,
          'address': address,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _commerceName = commerceName;
        _commerceType = commerceType;
        _address = address;
        _phone = phone;
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec de l\'enregistrement du commerçant');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur d\'enregistrement du commerçant: ${e.toString()}');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _email = email;
        _token = responseData['token'];
        _accountType = responseData['accountType'];
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec de la connexion');
      }
    } on TimeoutException catch (_) {
      throw HttpException('La requête a expiré');
    } on http.ClientException catch (e) {
      throw HttpException('Erreur réseau: ${e.message}');
    } catch (e) {
      throw HttpException('Erreur de connexion: ${e.toString()}');
    }
  }

  void logout() {
    _email = null;
    _token = null;
    _accountType = null;
    _address = null;
    _commerceName = null;
    _commerceType = null;
    _phone = null;
    notifyListeners();
  }

  // Ajouts

  bool get isAuthenticated {
    return _token != null;
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
         Uri.parse('http://localhost:5000/api/merchant/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _accountType = responseData['accountType'];
        _address = responseData['address'];
        _commerceName = responseData['commerceName'];
        _commerceType = responseData['commerceType'];
        _phone = responseData['phone'];
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Échec du chargement du profil');
      }
    } catch (e) {
      throw HttpException('Erreur lors du chargement du profil: ${e.toString()}');
    }
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
