// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/hlsMasterPlaylist.dart';
import 'package:animestream/core/commons/hlsParser/hlsSegment.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';
import 'package:http/http.dart' as http;

class HlsParser {
  static Future<bool> isM3u8Playlist(String url,
      {Map<String, String>? customHeader}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    if (path.endsWith('.m3u8') || path.endsWith('.m3u')) return true;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(uri);
      customHeader?.forEach(request.headers.set);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-1023');
      final response =
          await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode != 200 && response.statusCode != 206)
        return false;

      final prefix = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 6))) {
        prefix.addAll(chunk.take(1024 - prefix.length));
        if (prefix.length >= 7) break;
      }
      return utf8
          .decode(prefix, allowMalformed: true)
          .trimLeft()
          .startsWith('#EXTM3U');
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, String> _parseAttributes(String line) {
    final attrs = <String, String>{};
    for (final m in RegExp(r'([A-Z0-9\-]+)=(".*?"|[^,]*)').allMatches(line)) {
      attrs[m.group(1)!] = m.group(2)!.replaceAll('"', '');
    }
    return attrs;
  }

  static Future<HlsMasterPlaylist> parseMasterPlaylist(
    String streamUrl, {
    Map<String, String>? customHeader,
  }) async {
    if (!await isM3u8Playlist(streamUrl, customHeader: customHeader)) {
      throw const FormatException('Not an HLS playlist');
    }
    final url = Uri.parse(streamUrl);
    final response = await http
        .get(url, headers: customHeader)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HLS playlist HTTP ${response.statusCode}');
    }
    return parseMaster(
        utf8.decode(response.bodyBytes), response.request?.url ?? url);
  }

  static HlsMasterPlaylist parseMaster(String content, Uri baseUri) {
    final lines = const LineSplitter()
        .convert(content)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    if (lines.firstOrNull != '#EXTM3U') {
      throw const FormatException('Not an HLS playlist');
    }

    final audio = <AudioStream>[];
    final video = <QualityStream>[];
    Map<String, String>? pendingVariant;
    for (final line in lines.skip(1)) {
      if (line.startsWith('#EXT-X-MEDIA:')) {
        final attrs = _parseAttributes(line.substring('#EXT-X-MEDIA:'.length));
        final group = attrs['GROUP-ID'];
        final rendition = attrs['URI'];
        if (attrs['TYPE'] == 'AUDIO' &&
            group != null &&
            rendition != null &&
            rendition.isNotEmpty) {
          final language = attrs['LANGUAGE'] ?? 'und';
          audio.add(AudioStream(
            groupId: group,
            name: attrs['NAME'] ?? language,
            language: language,
            channels: attrs['CHANNELS'] ?? '',
            url: baseUri.resolve(rendition).toString(),
          ));
        }
      } else if (line.startsWith('#EXT-X-STREAM-INF:')) {
        pendingVariant =
            _parseAttributes(line.substring('#EXT-X-STREAM-INF:'.length));
      } else if (!line.startsWith('#') && pendingVariant != null) {
        final resolution = pendingVariant['RESOLUTION'] ?? '??';
        final height = int.tryParse(resolution.split('x').last);
        video.add(QualityStream(
          url: baseUri.resolve(line).toString(),
          quality: height == null ? 'default' : '${height}p',
          resolution: resolution,
          bandwidth: int.tryParse(pendingVariant['BANDWIDTH'] ?? ''),
          audioGroup: pendingVariant['AUDIO'],
        ));
        pendingVariant = null;
      }
    }

    return video.isEmpty
        ? HlsMasterPlaylist.defaultStream(baseUri.toString())
        : HlsMasterPlaylist(audioStreams: audio, qualityStreams: video);
  }

  static Future<List<HlsSegment>> parseSegments(String url,
      {Map<String, String> customHeaders = const {}}) async {
    final List<HlsSegment> segments = [];
    final requestedUri = Uri.parse(url);
    final res = await http
        .get(requestedUri, headers: customHeaders)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HLS media playlist HTTP ${res.statusCode}');
    }
    final baseUri = res.request?.url ?? requestedUri;
    final lines = const LineSplitter().convert(utf8.decode(res.bodyBytes));
    if (lines.firstOrNull?.trim() != '#EXTM3U') {
      throw const FormatException('Not an HLS media playlist');
    }

    int sequenceNumber = 0;
    double duration = 0.0;
    HlsEncryptionKey? currentKey;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        sequenceNumber = int.tryParse(line.substring(22)) ?? 0;
      } else if (line.startsWith('#EXT-X-KEY:')) {
        final attrs = _parseAttributes(line.substring(11));
        final method = attrs['METHOD'] ?? "NONE";

        if (method == "NONE") {
          currentKey = null;
        } else {
          final uri = attrs['URI'];
          final iv = attrs['IV'];
          if (uri != null) {
            currentKey = HlsEncryptionKey(
                method: method, uri: baseUri.resolve(uri).toString(), iv: iv);
          }
        }
      } else if (line.startsWith('#EXT-X-MAP:')) {
        // fMP4 init segment (ftyp + moov). Byte-ranged maps aren't supported yet.
        final uri = _parseAttributes(line.substring(11))['URI'];
        if (uri != null) {
          segments.add(
            HlsSegment(
              url: baseUri.resolve(uri).toString(),
              duration: 0,
              sequenceNumber: sequenceNumber,
              encryptionKey: currentKey,
              isInit: true,
            ),
          );
        }
      } else if (line.startsWith('#EXTINF:')) {
        duration = double.tryParse(line.substring(8).split(',')[0]) ?? 0.0;
      } else if (!line.startsWith('#')) {
        final segmentUrl = baseUri.resolve(line).toString();
        segments.add(
          HlsSegment(
              url: segmentUrl,
              duration: duration,
              sequenceNumber: sequenceNumber++,
              encryptionKey: currentKey),
        );
      }
    }
    return segments;
  }
}
