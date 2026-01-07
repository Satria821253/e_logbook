import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance_records';

  static Future<List<AttendanceModel>> getAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? attendanceJson = prefs.getString(_attendanceKey);
    
    if (attendanceJson == null) return [];
    
    final List<dynamic> attendanceList = json.decode(attendanceJson);
    return attendanceList.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  static Future<void> saveAttendanceRecord(AttendanceModel attendance) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAttendanceRecords();
    
    records.add(attendance);
    
    final String attendanceJson = json.encode(
      records.map((record) => record.toJson()).toList()
    );
    
    await prefs.setString(_attendanceKey, attendanceJson);
  }

  static Future<void> markAttendance(AttendanceModel attendance) async {
    await saveAttendanceRecord(attendance);
  }

  static Future<List<AttendanceModel>> getCrewAttendance(String crewName) async {
    final records = await getAttendanceRecords();
    return records.where((record) => record.crewName == crewName).toList();
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attendanceKey);
  }
}