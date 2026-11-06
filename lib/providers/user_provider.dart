import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _user;

  UserProfile? get user => _user;

  bool get isRegistered => _user != null;

  void register(UserProfile profile) {
    _user = profile;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
