import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_service.dart';
import 'dummy_data_service.dart';

class DataClearService {
  static Future<void> clearSubmittedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Only clear data if it was marked as submitted/completed
    final isSubmitted = prefs.getBool('full_process_completed') ?? false;
    
    if (isSubmitted) {
      // Clear all completion data to simulate server reset
      await prefs.remove('full_process_completed');
      await prefs.remove('vessel_submitted');
      await prefs.remove('vessel_fuel');
      await prefs.remove('vessel_ice');
      await prefs.remove('vessel_certificates');
      await prefs.remove('documents');
      
      print('Submitted data cleared on app restart (simulating server behavior)');
    } else {
      print('No submitted data found, keeping partial progress');
    }
  }
  
  static Future<void> clearAllDummyData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear attendance data
    await AttendanceService.clearAllData();
    
    // Clear any other dummy data keys if needed
    await prefs.remove('crew_registrations');
    await prefs.remove('attendance_records');
    await prefs.remove('admin_notifications');
    await prefs.remove('document_requirements');
    
    // Clear completion flags
    await prefs.remove('full_process_completed');
    await prefs.remove('vessel_fuel');
    await prefs.remove('vessel_ice');
    await prefs.remove('vessel_certificates');
    await prefs.remove('documents');
    
    print('All dummy data cleared successfully');
  }

  static Future<void> setupDummyData(String userEmail, String userRole) async {
    // Reset completion flags first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('full_process_completed', false);
    await prefs.remove('vessel_fuel');
    await prefs.remove('vessel_ice');
    await prefs.remove('vessel_certificates');
    await prefs.remove('documents');
    
    await DummyDataService.setupDummyData(userEmail, userRole);
    print('Dummy data setup completed for user: $userEmail with role: $userRole');
  }
}