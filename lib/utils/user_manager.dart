import 'package:flutter/foundation.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // 'User' or 'Provider'
  final bool isBlocked;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.isBlocked = false,
  });
}

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;

  UserManager._internal() {
    _users.addAll([
      AppUser(id: '1', name: 'Ramesh Kumar', phone: '9876543210', role: 'User'),
      AppUser(id: '2', name: 'Suresh Patel', phone: '9876543211', role: 'Provider'),
      AppUser(id: '3', name: 'Mahesh Yadav', phone: '9876543212', role: 'User'),
      AppUser(id: '4', name: 'Dinesh Singh', phone: '9876543213', role: 'Provider', isBlocked: true),
    ]);
  }

  final List<AppUser> _users = [];

  List<AppUser> get users => List.unmodifiable(_users);

  void toggleUserBlockStatus(String id) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      final old = _users[index];
      _users[index] = AppUser(
        id: old.id,
        name: old.name,
        phone: old.phone,
        role: old.role,
        isBlocked: !old.isBlocked,
      );
      notifyListeners();
    }
  }
}
