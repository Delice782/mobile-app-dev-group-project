  
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
 
  static Future<void> saveUserCredentials(
    String userId,
    String token, {
    String? userName,
  }) async {
    final box = Hive.box(_boxName);
    final map = <String, dynamic>{'userId': userId, 'token': token};
    if (userName != null && userName.trim().isNotEmpty) {
      map['userName'] = userName.trim();
    }
    await box.put('userCredentials', map);
  }

  static Map? getUserCredentials() {
    final box = Hive.box(_boxName);
    return box.get('userCredentials');
  }

  static Future<void> clearUserCredentials() async {
    final box = Hive.box(_boxName);
    await box.delete('userCredentials');
    await box.delete(_knownPaidPaymentIdsKey);
  }

  static const String _knownPaidPaymentIdsKey = 'knownPaidPaymentIds';

  /// Payment IDs we have already notified for (baseline after first successful earnings fetch).
  static List<int> getKnownPaidPaymentIds() {
    final box = Hive.box(_boxName);
    final raw = box.get(_knownPaidPaymentIdsKey, defaultValue: <dynamic>[]);
    final out = <int>[];
    for (final e in raw) {
      if (e is int) {
        out.add(e);
      } else if (e is num) {
        out.add(e.toInt());
      }
    }
    return out;
  }

  static Future<void> setKnownPaidPaymentIds(Iterable<int> ids) async {
    final box = Hive.box(_boxName);
    await box.put(_knownPaidPaymentIdsKey, ids.toList());
  }

  static const String _pendingCollectionsKey = 'pendingCollectionSubmissions';

  static Future<void> enqueuePendingCollection(
      Map<String, dynamic> item) async {
    final list = getPendingCollections();
    list.add(item);
    await _setPendingCollections(list);
  }

  static List<Map<String, dynamic>> getPendingCollections() {
    final box = Hive.box(_boxName);
    final raw = box.get(_pendingCollectionsKey, defaultValue: <dynamic>[]);
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  static Future<void> _setPendingCollections(
      List<Map<String, dynamic>> list) async {
    final box = Hive.box(_boxName);
    await box.put(_pendingCollectionsKey, list);
  }

  static Future<void> removePendingCollectionAt(int index) async {
    final list = getPendingCollections();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await _setPendingCollections(list);
    }
  }

  static int get pendingCollectionCount => getPendingCollections().length;
}
 
 
