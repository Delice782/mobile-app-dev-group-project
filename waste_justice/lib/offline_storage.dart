  
import 'package:hive_flutter/hive_flutter.dart';

class OfflineStorageService {
  static const String _boxName = 'wasteJusticeBox';
 
  static Future<void> saveRequest(Map<String, dynamic> request) async {
    final box = Hive.box(_boxName);
    final List requests = box.get('pendingRequests', defaultValue: []); 
    requests.add(request); 
    await box.put('pendingRequests', requests); 
    print('Request saved offline');
  }
 
  static List getPendingRequests() {
    final box = Hive.box(_boxName);
    return box.get('pendingRequests', defaultValue: []);
  }

  static Future<void> clearSyncedRequests() async {
    final box = Hive.box(_boxName);
    await box.delete('pendingRequests');
  }
 
  static Future<void> savePrices(Map<String, dynamic> prices) async {
    final box = Hive.box(_boxName);
    await box.put('cachedPrices', prices);
  }

  static Map? getCachedPrices() {
    final box = Hive.box(_boxName);
    return box.get('cachedPrices');
  }
 
  static Future<void> saveUserCredentials(String userId, String token) async {
    final box = Hive.box(_boxName);
    await box.put('userCredentials', {'userId': userId, 'token': token});
  }

  static Map? getUserCredentials() {
    final box = Hive.box(_boxName);
    return box.get('userCredentials');
  }
}
 
 
