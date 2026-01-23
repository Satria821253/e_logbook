import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'getAPi/vessel_service.dart';
import 'getAPi/document_service.dart';

class RealtimeUpdateService {
  static Timer? _pollingTimer;
  static final Map<String, List<Function>> _listeners = {}; // Changed to List<Function>
  static Map<String, dynamic>? _lastVesselData;
  static List<dynamic>? _lastDocuments;
  static Map<String, dynamic>? _lastCertificates;
  static List<dynamic>? _lastBBMData;
  static List<dynamic>? _lastIceData;
  static Map<String, dynamic>? _lastUserProfile;
  
  // Polling interval (30 detik)
  static const Duration _pollingInterval = Duration(seconds: 30);

  /// Start polling untuk auto-update
  static void startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      print('⚠️ Polling already running');
      return;
    }

    print('🔄 Starting real-time polling...');
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await _checkForUpdates();
    });
    
    // Check immediately on start
    _checkForUpdates();
  }

  /// Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('⏹️ Polling stopped');
  }

  /// Register listener untuk data tertentu
  static void addListener(String key, Function callback) {
    if (_listeners[key] == null) {
      _listeners[key] = [];
    }
    _listeners[key]!.add(callback);
    print('👂 Listener registered: $key (total: ${_listeners[key]!.length})');
  }

  /// Remove listener
  static void removeListener(String key) {
    _listeners.remove(key);
    print('🔇 Listener removed: $key');
  }
  
  /// Get listener (untuk manual trigger)
  static List<Function>? getListener(String key) {
    return _listeners[key];
  }

  /// Check for updates dari backend
  static Future<void> _checkForUpdates() async {
    try {
      print('\n========== POLLING CHECK START ==========');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('⚠️ No auth token, skipping polling');
        return;
      }

      final changes = <String>[];

      // Check vessel data
      final vesselData = await VesselService().getVesselData();
      if (vesselData != null) {
        if (_lastVesselData == null) {
          _lastVesselData = vesselData;
        } else {
          // Compare vessel data
          final lastUpdated = _lastVesselData!['kapal']?['updatedAt'];
          final currentUpdated = vesselData['kapal']?['updatedAt'];
          
          if (lastUpdated != currentUpdated) {
            print('🔔 Vessel data changed!');
            changes.add('vessel');
            _lastVesselData = vesselData;
          }
        }
      }

      // Check documents - DETAIL CHECK untuk detect status changes
      try {
        final docResponse = await DocumentService.getDocuments();
        if (docResponse['success'] == true) {
          final docs = docResponse['documents'] as List;
          
          if (_lastDocuments == null) {
            _lastDocuments = docs;
          } else {
            bool hasDocumentChanges = false;
            
            // Check count change (dokumen dihapus atau ditambah)
            if (docs.length != _lastDocuments!.length) {
              print('🔔 Document count changed: ${_lastDocuments!.length} → ${docs.length}');
              hasDocumentChanges = true;
            }
            
            // Check jika ada dokumen baru atau hilang (compare by ID)
            if (!hasDocumentChanges) {
              final currentIds = docs.map((d) => d['id']).toSet();
              final lastIds = _lastDocuments!.map((d) => d['id']).toSet();
              
              if (!currentIds.containsAll(lastIds) || !lastIds.containsAll(currentIds)) {
                print('🔔 Document IDs changed (added/removed)');
                hasDocumentChanges = true;
              }
            }
            
            // Check status changes untuk setiap dokumen (by ID, bukan index)
            if (!hasDocumentChanges && docs.isNotEmpty) {
              for (var doc in docs) {
                final oldDoc = _lastDocuments!.firstWhere(
                  (d) => d['id'] == doc['id'],
                  orElse: () => {},
                );
                
                if (oldDoc.isEmpty) {
                  // Dokumen baru
                  print('🔔 New document added: ${doc['jenisDokumen']}');
                  hasDocumentChanges = true;
                  break;
                }
                
                // Check status change
                if (oldDoc['status'] != doc['status']) {
                  print('🔔 Document status changed: ${doc['jenisDokumen']} → ${doc['status']}');
                  hasDocumentChanges = true;
                  break;
                }
                
                // Check rejection reason
                if (doc['status'] == 'rejected' && 
                    oldDoc['alasanPenolakan'] != doc['alasanPenolakan']) {
                  print('🔔 Document rejection reason updated');
                  hasDocumentChanges = true;
                  break;
                }
                
                // Check file path change (dokumen diupload ulang)
                if (oldDoc['filePath'] != doc['filePath']) {
                  print('🔔 Document file changed: ${doc['jenisDokumen']}');
                  hasDocumentChanges = true;
                  break;
                }
              }
            }
            
            if (hasDocumentChanges) {
              changes.add('documents');
              _lastDocuments = docs;
            }
          }
        }
      } catch (e) {
        print('⚠️ Error checking documents: $e');
      }

      // Check certificates
      try {
        final certData = await VesselService().getVesselDocuments(forceRefresh: false);
        final certs = certData['sertifikatJalan'] as List?;
        
        if (_lastCertificates == null) {
          _lastCertificates = {'count': certs?.length ?? 0};
        } else {
          final lastCount = _lastCertificates!['count'] ?? 0;
          final currentCount = certs?.length ?? 0;
          
          if (lastCount != currentCount) {
            print('🔔 Certificates changed: $lastCount → $currentCount');
            changes.add('certificates');
            _lastCertificates = {'count': currentCount};
          }
        }
        
        // Check BBM data
        final bbmData = certData['dataBahanBakar'] as List?;
        if (bbmData != null) {
          if (_lastBBMData == null) {
            _lastBBMData = bbmData;
          } else if (_hasListChanged(_lastBBMData!, bbmData)) {
            print('🔔 BBM data changed');
            changes.add('bbm');
            _lastBBMData = bbmData;
          }
        }
        
        // Check Ice data
        final iceData = certData['dataEs'] as List?;
        if (iceData != null) {
          if (_lastIceData == null) {
            _lastIceData = iceData;
          } else if (_hasListChanged(_lastIceData!, iceData)) {
            print('🔔 Ice data changed');
            changes.add('ice');
            _lastIceData = iceData;
          }
        }
      } catch (e) {
        print('⚠️ Error checking vessel documents: $e');
      }
      
      // Check user profile changes
      try {
        final userDataStr = prefs.getString('user_data');
        if (userDataStr != null) {
          if (_lastUserProfile == null) {
            _lastUserProfile = {'data': userDataStr};
          } else if (_lastUserProfile!['data'] != userDataStr) {
            print('🔔 User profile changed');
            changes.add('profile');
            _lastUserProfile = {'data': userDataStr};
          }
        }
      } catch (e) {
        print('⚠️ Error checking user profile: $e');
      }

      if (changes.isNotEmpty) {
        print('🔔 Changes detected: ${changes.join(", ")}');
        _notifyListeners(changes);
      } else {
        print('✅ No changes detected');
      }
      
      print('========== POLLING CHECK END ==========\n');
    } catch (e) {
      print('⚠️ Polling error: $e');
      print('========== POLLING CHECK END (ERROR) ==========\n');
    }
  }

  /// Notify all listeners
  static void _notifyListeners(List<String> changes) {
    print('📢 Notifying listeners for changes: ${changes.join(", ")}');
    print('👂 Active listeners: ${_listeners.keys.join(", ")}');
    
    for (var change in changes) {
      final listeners = _listeners[change];
      if (listeners != null && listeners.isNotEmpty) {
        print('🔔 Calling ${listeners.length} listener(s) for: $change');
        for (var listener in listeners) {
          try {
            listener();
            print('✅ Listener called successfully');
          } catch (e) {
            print('❌ Error calling listener $change: $e');
          }
        }
      } else {
        print('⚠️ No listener registered for: $change');
      }
    }
    
    // Notify global listener
    final globalListeners = _listeners['global'];
    if (globalListeners != null && globalListeners.isNotEmpty) {
      print('🔔 Calling ${globalListeners.length} global listener(s)');
      for (var listener in globalListeners) {
        try {
          listener(changes);
          print('✅ Global listener called successfully');
        } catch (e) {
          print('❌ Error calling global listener: $e');
        }
      }
    }
  }

  /// Helper to check if list data changed
  static bool _hasListChanged(List oldList, List newList) {
    if (oldList.length != newList.length) return true;
    
    for (int i = 0; i < oldList.length; i++) {
      final oldItem = oldList[i];
      final newItem = newList[i];
      
      // Compare by ID if available
      if (oldItem is Map && newItem is Map) {
        if (oldItem['id'] != newItem['id']) return true;
        if (oldItem['updatedAt'] != newItem['updatedAt']) return true;
      }
    }
    return false;
  }

  /// Force refresh all data
  static Future<void> forceRefresh() async {
    print('🔄 Force refreshing all data...');
    _lastVesselData = null;
    _lastDocuments = null;
    _lastCertificates = null;
    _lastBBMData = null;
    _lastIceData = null;
    _lastUserProfile = null;
    await _checkForUpdates();
  }
}
