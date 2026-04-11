import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'api_service.dart';
import 'notification.dart';
import 'offline_storage.dart';

/// Sends queued waste submissions when the device is back online (same APIs as live submit).
class PendingSubmissionSync {
  static Future<int> flushAll() async {
    var synced = 0;
    while (true) {
      final list = OfflineStorageService.getPendingCollections();
      if (list.isEmpty) break;
      final item = list.first;
      try {
        String photoPath = '';
        final local = item['localPhotoPath']?.toString();
        if (local != null && local.isNotEmpty) {
          final f = File(local);
          if (await f.exists()) {
            photoPath = await ApiService.uploadCollectionPhoto(f);
          }
        }
        final agg = item['aggregatorID'];
        int? aggregatorId;
        if (agg is num && agg.toInt() > 0) {
          aggregatorId = agg.toInt();
        }
        await ApiService.submitCollection(
          plasticTypeId: (item['plasticTypeID'] as num).toInt(),
          weight: (item['weight'] as num).toDouble(),
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          location: item['location']?.toString() ?? '',
          notes: item['notes']?.toString() ?? '',
          photoPath: photoPath,
          aggregatorId: aggregatorId,
        );
        if (!kIsWeb) {
          final w = item['weight'];
          final weightKg = w is num
              ? w.toDouble()
              : double.tryParse(w?.toString() ?? '');
          final name = item['plasticTypeName']?.toString().trim();
          await NotificationService.instance.notifyWasteSubmissionSent(
            weightKg: weightKg,
            plasticTypeLabel:
                name != null && name.isNotEmpty ? name : null,
          );
        }
        await OfflineStorageService.removePendingCollectionAt(0);
        synced++;
      } catch (_) {
        break;
      }
    }
    return synced;
  }
}
