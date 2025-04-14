import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException

class AuthProvider with ChangeNotifier {
  String? _email;
  String? _token;
  String? get email => _email;
  String? get token => _token;

  // Get the correct base URL based on platform
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // For web builds
    } else {
      return 'http://10.0.2.2:5000'; // For mobile (Android/iOS)
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
        throw HttpException(responseData['message'] ?? 'Unknown error during signup');
      }
    } on TimeoutException catch (_) {
      throw HttpException('Request timed out');
    } on http.ClientException catch (e) {
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      throw HttpException('Failed to sign up: ${e.toString()}');
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
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 200) {
        throw HttpException(responseData['message'] ?? 'Verification failed');
      }
    } on TimeoutException catch (_) {
      throw HttpException('Request timed out');
    } on http.ClientException catch (e) {
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      throw HttpException('Verification error: ${e.toString()}');
    }
  }

  Future<void> setAccountType(String accountType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/set-account-type'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'accountType': accountType,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      
      if (response.statusCode != 200) {
        throw HttpException(responseData['message'] ?? 'Failed to set account type');
      }
    } on TimeoutException catch (_) {
      throw HttpException('Request timed out');
    } on http.ClientException catch (e) {
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      throw HttpException('Account type error: ${e.toString()}');
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
        notifyListeners();
      } else {
        throw HttpException(responseData['message'] ?? 'Login failed');
      }
    } on TimeoutException catch (_) {
      throw HttpException('Request timed out');
    } on http.ClientException catch (e) {
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      throw HttpException('Login error: ${e.toString()}');
    }
  }

  void logout() {
    _email = null;
    _token = null;
    notifyListeners();
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  
  @override
  String toString() => message;
}