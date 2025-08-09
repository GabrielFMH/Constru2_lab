import 'package:flutter/material.dart';
import '../../logica/logicaSesion.dart';
import '../../logica/logicaNotificaciones.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final NotificacionesService _notificacionesService =
      NotificacionesService.instance;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    _notificacionesService.setNotificationsEnabled(value);
    notifyListeners();
  }

  void logout(BuildContext context) {
    _authService.handleLogout(context);
  }

  void deleteAccount(BuildContext context) {
    _authService.handleDeleteAccount(context);
  }
}
