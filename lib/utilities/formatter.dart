/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final wordsPatternForSongTitle = RegExp(
  r'\b(official music video|official lyric video|official lyrics video|official video|official 4k video|official audio|lyric video|lyrics video|official hd video|lyric visualizer|lyric vizualizer|official visualizer|lyrics|lyric)\b',
  caseSensitive: false,
);

final replacementsForSongTitle = {
  '[': '',
  ']': '',
  '(': '',
  ')': '',
  '|': '',
  '&amp;': '&',
  '&#039;': "'",
  '&quot;': '"',
};

String formatSongTitle(String title) {
  final pattern = RegExp(
    replacementsForSongTitle.keys.map(RegExp.escape).join('|'),
  );

  var finalTitle =
      title
          .replaceAllMapped(
            pattern,
            (match) => replacementsForSongTitle[match.group(0)] ?? '',
          )
          .trimLeft();

  finalTitle = finalTitle.replaceAll(wordsPatternForSongTitle, '');

  return finalTitle;
}

Map<String, dynamic> returnSongLayout(
  int index,
  Video song, {
  String? playlistImage,
}) => {
  'id': index,
  'ytid': song.id.toString(),
  'title': formatSongTitle(
    song.title.split('-')[song.title.split('-').length - 1],
  ),
  'artist': song.title.split('-')[0],
  'image': playlistImage ?? song.thumbnails.standardResUrl,
  'lowResImage': playlistImage ?? song.thumbnails.lowResUrl,
  'highResImage': playlistImage ?? song.thumbnails.maxResUrl,
  'duration': song.duration?.inSeconds,
  'isLive': song.isLive,
};

Map<String, dynamic> returnLocalSongLayout(
  Map<String, dynamic> localSong,
  int index,
) {
  final title = localSong['title'] as String? ?? 'Unknown';
  final artist = localSong['artist'] as String? ?? 'Unknown Artist';
  final duration = localSong['duration'] as int? ?? 0;
  final path = localSong['path'] as String? ?? '';
  final id = localSong['id'] as int? ?? 0;
  final albumArtUri = localSong['albumArtUri'] as String?;
  final albumArtBase64 = localSong['albumArtBase64'] as String?;

  return {
    'id': index,
    'localId': id, // Keep the original MediaStore ID
    'ytid': null, // No YouTube ID for local songs
    'title': title,
    'artist': artist,
    'image': albumArtUri, // Use album art URI
    'lowResImage': albumArtUri,
    'highResImage': albumArtUri,
    'imageBase64': albumArtBase64, // Base64 encoded image
    'duration': duration ~/ 1000, // Convert milliseconds to seconds
    'isLive': false,
    'isLocal': true, // Flag to identify local songs
    'audioPath': path, // File path for playback
    'artworkPath': null, // Will be set if artwork is available as file
  };
}

// Batch converter for multiple songs
List<Map<String, dynamic>> convertLocalSongsToLayout(
  List<Map<String, dynamic>> localSongs,
) {
  return localSongs.asMap().entries.map((entry) {
    final index = entry.key;
    final song = entry.value;
    return returnLocalSongLayout(song, index);
  }).toList();
}

String formatDuration(int audioDurationInSeconds) {
  final duration = Duration(seconds: audioDurationInSeconds);

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return [
    if (hours > 0) hours.toString().padLeft(2, '0'),
    minutes.toString().padLeft(2, '0'),
    seconds.toString().padLeft(2, '0'),
  ].join(':');
}
