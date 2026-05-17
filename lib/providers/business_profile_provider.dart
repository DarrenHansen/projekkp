import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/business_profile.dart';
import '../models/bank_account.dart';

/// Business Profile Provider
class BusinessProfileProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;

  BusinessProfile _profile = BusinessProfile();
  bool _isLoading = false;

  BusinessProfile get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBusinessProfile();
      if (data != null) {
        _profile = BusinessProfile.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error loading business profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(BusinessProfile profile) async {
    try {
      await _dbHelper.saveBusinessProfile(profile.toMap());
      _profile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving business profile: $e');
    }
    return false;
  }
}
