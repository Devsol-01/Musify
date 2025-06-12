import 'package:flutter/services.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/formatter.dart';

class MusicService {
  static const MethodChannel _channel = MethodChannel('music_service');

  static Future<List<Map<String, dynamic>>> getSongs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSongs');

      // Convert each item to Map<String, dynamic> safely
      final rawSongs =
          result.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();

      // Convert to the expected layout format
      final formattedSongs = convertLocalSongsToLayout(rawSongs);

      return formattedSongs;
    } on PlatformException catch (e, stackTrace) {
      logger.log('Failed to get songs:', e, stackTrace);
      return [];
    } catch (e, stackTrace) {
      logger.log('Unexpected error in getSongs:', e, stackTrace);
      return [];
    }
  }

  // Get raw song data without formatting (if needed)
  static Future<List<Map<String, dynamic>>> getRawSongs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSongs');
      return result.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    } on PlatformException catch (e, stackTrace) {
      logger.log('Failed to get raw songs:', e, stackTrace);
      return [];
    }
  }
}
