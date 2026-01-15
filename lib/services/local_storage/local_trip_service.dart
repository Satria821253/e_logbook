import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalTripService {
  static const String _keyTrips = 'local_trips';
  static const String _keyActiveTrip = 'active_trip';

  // Save trip to local
  static Future<void> saveTrip(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> trips = prefs.getStringList(_keyTrips) ?? [];
    trips.add(jsonEncode(tripData));
    
    await prefs.setStringList(_keyTrips, trips);
  }

  // Get all trips
  static Future<List<Map<String, dynamic>>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final trips = prefs.getStringList(_keyTrips) ?? [];
    
    return trips.map((trip) {
      return jsonDecode(trip) as Map<String, dynamic>;
    }).toList();
  }

  // Get trips by user
  static Future<List<Map<String, dynamic>>> getTripsByUser(String userId) async {
    final trips = await getAllTrips();
    return trips.where((trip) => trip['userId'] == userId).toList();
  }

  // Save active trip
  static Future<void> saveActiveTrip(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveTrip, jsonEncode(tripData));
  }

  // Get active trip
  static Future<Map<String, dynamic>?> getActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final activeTrip = prefs.getString(_keyActiveTrip);
    if (activeTrip != null) {
      return jsonDecode(activeTrip) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear active trip
  static Future<void> clearActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveTrip);
  }

  // Clear all trips
  static Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTrips);
  }
}
