import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> loadUser() async {
    _user = await UserService.getUser();
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    await UserService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> updateVesselInfo({
    required String vesselName,
    required String vesselNumber,
    required String captainName,
    required int crewCount,
    List<String>? crewNames,
  }) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: _user!.role,
        vesselName: vesselName,
        vesselNumber: vesselNumber,
        captainName: captainName,
        crewCount: crewCount,
        crewNames: crewNames,
      );
      await UserService.saveUser(_user!);
      notifyListeners();
    }
  }

  Future<void> updateRole(String role) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: role,
        vesselName: _user!.vesselName,
        vesselNumber: _user!.vesselNumber,
        captainName: _user!.captainName,
        crewCount: _user!.crewCount,
        crewNames: _user!.crewNames,
      );
      await UserService.saveUser(_user!);
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(String path) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: _user!.role,
        vesselName: _user!.vesselName,
        vesselNumber: _user!.vesselNumber,
        captainName: _user!.captainName,
        crewCount: _user!.crewCount,
        crewNames: _user!.crewNames,
        profilePicture: path,
      );
      await UserService.saveUser(_user!);
      notifyListeners();
    }
  }

  // Force refresh profile picture to clear cache
  void refreshProfilePicture() {
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    await UserService.clearUser();
    notifyListeners();
  }
}
