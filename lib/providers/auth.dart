import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shop/models/http_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

const API_KEY = "AIzaSyAHogxevm3OYadMz3k8E9iGJUXB-2FYj1w";

class Auth with ChangeNotifier {
// class Auth with ChangeNotifier, DiagnosticableTreeMixin {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(StringProperty('_token', _token));
  //   properties.add(StringProperty('_expiryDate', _expiryDate.toString()));
  //   properties.add(StringProperty('_userId', _userId));
  // }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }

    return null;
  }

  String get userId {
    return _userId;
  }

  bool get isAuth {
    return token != null;
  }

  Future<void> _authenticate(
    String email,
    String password,
    String urlSegment,
  ) async {
    final url =
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$API_KEY";

    try {
      final res = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final data = json.decode(res.body);

      if (data['error'] != null) {
        throw HttpException(data['error']['message']);
      }

      _token = data['idToken'];
      _userId = data['localId'];
      _expiryDate = DateTime.now().add(
        Duration(seconds: int.parse(data['expiresIn'])),
      );

      _autoLogout();

      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
        'userData',
        json.encode({
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate.toIso8601String(),
        }),
      );
    } catch (error) {
      print(error);
      print(error.toString());
      throw error;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, "signUp");
  }

  Future<void> signIn(String email, String password) async {
    return _authenticate(email, password, "signInWithPassword");
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('userData')) return false;

    final data =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    final expiryDate = DateTime.parse(data['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) return false;

    _token = data['token'];
    _userId = data['userId'];
    _expiryDate = expiryDate;

    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;

    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    notifyListeners();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }

    _authTimer = Timer(
      Duration(seconds: _expiryDate.difference(DateTime.now()).inSeconds),
      logout,
    );
  }
}
