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

import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/spinner.dart';

class SongArtworkWidget extends StatelessWidget {
  const SongArtworkWidget({
    super.key,
    required this.size,
    required this.metadata,
    this.borderRadius = 10.0,
    this.errorWidgetIconSize = 20.0,
    this.showDuration = false,
    this.duration,
  });
  final double size;
  final MediaItem metadata;
  final double borderRadius;
  final double errorWidgetIconSize;
  final bool showDuration;
  final dynamic duration;

  @override
  Widget build(BuildContext context) {
    // Extract data from metadata
    final isLocal = metadata.extras?['isLocal'] == true;
    final imageBase64 = metadata.extras?['imageBase64'] as String?;
    final artworkPath = metadata.extras?['artWorkPath'] as String?;
    final lowResImageUrl = metadata.artUri?.toString() ?? '';
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (isLocal) {
      return _LocalArtwork(
        imageBase64: imageBase64,
        artworkPath: artworkPath,
        size: size,
        primaryColor: primaryColor,
        borderRadius: borderRadius,
        showDuration: showDuration,
        duration: duration,
        errorWidgetIconSize: errorWidgetIconSize,
      );
    }

    if (artworkPath != null && File(artworkPath).existsSync()) {
      return _OfflineArtwork(
        artworkPath: artworkPath,
        size: size,
        borderRadius: borderRadius,
      );
    }

    return _OnlineArtwork(
      lowResImageUrl: lowResImageUrl,
      size: size,
      borderRadius: borderRadius,
      showDuration: showDuration,
      primaryColor: primaryColor,
      duration: duration,
      errorWidgetIconSize: errorWidgetIconSize,
    );
  }
}

class _LocalArtwork extends StatelessWidget {
  const _LocalArtwork({
    required this.imageBase64,
    required this.artworkPath,
    required this.size,
    required this.primaryColor,
    required this.borderRadius,
    required this.showDuration,
    required this.duration,
    required this.errorWidgetIconSize,
  });

  final String? imageBase64;
  final String? artworkPath;
  final double size;
  final Color primaryColor;
  final double borderRadius;
  final bool showDuration;
  final dynamic duration;
  final double errorWidgetIconSize;

  @override
  Widget build(BuildContext context) {
    Widget artworkWidget;

    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      // Use base64 image
      try {
        final base64String =
            imageBase64!.contains(',')
                ? imageBase64!.split(',').last
                : imageBase64!;
        final bytes = base64Decode(base64String);
        artworkWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
        );
      } catch (e) {
        artworkWidget = NullArtworkWidget(iconSize: errorWidgetIconSize);
      }
    } else if (artworkPath != null && artworkPath!.isNotEmpty) {
      // Use file path
      artworkWidget = Image.file(
        File(artworkPath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder:
            (context, error, stackTrace) =>
                NullArtworkWidget(iconSize: errorWidgetIconSize),
      );
    } else {
      // No artwork available
      artworkWidget = NullArtworkWidget(iconSize: errorWidgetIconSize);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ColorFiltered(
              colorFilter:
                  showDuration
                      ? ColorFilter.mode(
                        Theme.of(context).colorScheme.primaryContainer,
                        BlendMode.multiply,
                      )
                      : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
              child: Opacity(
                opacity: showDuration ? 0.45 : 1.0,
                child: artworkWidget,
              ),
            ),
          ),
        ),
        if (showDuration && duration != null)
          SizedBox(
            width: size - 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '($duration)',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OfflineArtwork extends StatelessWidget {
  const _OfflineArtwork({
    required this.artworkPath,
    required this.size,
    required this.borderRadius,
  });

  final String artworkPath;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(File(artworkPath), fit: BoxFit.cover),
      ),
    );
  }
}

class _OnlineArtwork extends StatelessWidget {
  const _OnlineArtwork({
    required this.lowResImageUrl,
    required this.size,
    required this.borderRadius,
    required this.showDuration,
    required this.primaryColor,
    required this.duration,
    required this.errorWidgetIconSize,
  });

  final String lowResImageUrl;
  final double size;
  final double borderRadius;
  final bool showDuration;
  final Color primaryColor;
  final dynamic duration;
  final double errorWidgetIconSize;

  @override
  Widget build(BuildContext context) {
    if (lowResImageUrl.isEmpty) {
      return NullArtworkWidget(iconSize: errorWidgetIconSize);
    }

    final isImageSmall = lowResImageUrl.contains('default.jpg');

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CachedNetworkImage(
          key: ValueKey(lowResImageUrl),
          width: size,
          height: size,
          imageUrl: lowResImageUrl,
          memCacheWidth:
              (size * MediaQuery.of(context).devicePixelRatio).round(),
          memCacheHeight:
              (size * MediaQuery.of(context).devicePixelRatio).round(),
          imageBuilder:
              (context, imageProvider) => SizedBox(
                width: size,
                height: size,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Image(
                    color:
                        showDuration
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                    colorBlendMode: showDuration ? BlendMode.multiply : null,
                    opacity:
                        showDuration
                            ? const AlwaysStoppedAnimation(0.45)
                            : null,
                    image: imageProvider,
                    centerSlice:
                        isImageSmall ? const Rect.fromLTRB(1, 1, 1, 1) : null,
                  ),
                ),
              ),
          placeholder: (context, url) => const Spinner(),
          errorWidget:
              (context, url, error) =>
                  NullArtworkWidget(iconSize: errorWidgetIconSize),
        ),
        if (showDuration && duration != null)
          SizedBox(
            width: size - 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '($duration)',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
