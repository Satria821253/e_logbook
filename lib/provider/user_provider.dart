import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> setUser(UserModel user) async {
    _user = user;
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
      notifyListeners();
    }
  }

  void refreshProfilePicture() {
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
