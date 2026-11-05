import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.api,
    required this.prefs,
    bool startReady = false,
  }) : booting = !startReady {
    api.onUnauthorized = _forceSignOut;
  }

  final ApiClient api;
  final SharedPreferences prefs;

  User? user;
  bool booting;
  String? bootError;

  bool get isAdmin => user?.isAdmin ?? false;

  Future<void> boot() async {
    bootError = null;
    booting = true;
    notifyListeners();

    final saved = prefs.getString('token');
    if (saved == null || saved.isEmpty) {
      user = null;
      booting = false;
      notifyListeners();
      return;
    }

    api.token = saved;
    try {
      user = await api.me();
      bootError = null;
    } on ApiException catch (error) {
      user = null;
      if (error.status == 401 || error.status == 403) {
        api.token = null;
        await prefs.remove('token');
      } else {
        bootError = error.message;
      }
    } catch (error) {
      user = null;
      bootError = error.toString();
    } finally {
      booting = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final signedIn = await api.login(email.trim(), password);
    await prefs.setString('token', api.token!);
    user = signedIn;
    bootError = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    await prefs.remove('token');
    user = null;
    notifyListeners();
  }

  void _forceSignOut() {
    api.token = null;
    user = null;
    prefs.remove('token');
    notifyListeners();
  }
}
