import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 📥 Download / 📤 share the admin's posters and reels
///   • Download   → saved in the phone Gallery (album "Let's Speak")
///   • Share      → phone share menu: WhatsApp chat, WhatsApp Status ("My status"),
///                  Instagram Story / Reel / Feed, Telegram, Facebook …
/// The file is downloaded once and reused (no double data use).
class PromoShare {
  PromoShare._();

  static const String album = "Let's Speak";
  static const String playStore = 'https://play.google.com/store/apps/details?id=com.surendra.letsspeak';

  static final Map<String, String> _cache = {}; // url → local file

  static String _ext(String url, bool video) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    for (final e in ['.mp4', '.mov', '.webm', '.m4v', '.jpg', '.jpeg', '.png', '.webp', '.gif']) {
      if (path.endsWith(e)) return e;
    }
    return video ? '.mp4' : '.jpg';
  }

  /// Downloads the file into the app's temp folder (once). Throws on failure.
  static Future<String> _file(String url, {required bool video, String fallbackUrl = ''}) async {
    final cached = _cache[url];
    if (cached != null && File(cached).existsSync()) return cached;

    final dir = await getTemporaryDirectory();
    final name = 'letsspeak_${url.hashCode.toUnsigned(32)}${_ext(url, video)}';
    final file = File('${dir.path}/$name');
    if (await file.exists() && await file.length() > 0) {
      _cache[url] = file.path;
      return file.path;
    }

    Future<bool> fetch(String u) async {
      final client = http.Client();
      try {
        final res = await client.send(http.Request('GET', Uri.parse(u))).timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) return false;
        final sink = file.openWrite();
        await res.stream.pipe(sink);
        return await file.length() > 0;
      } catch (e) {
        debugPrint('Promo download error: $e');
        return false;
      } finally {
        client.close();
      }
    }

    var ok = await fetch(url);
    if (!ok && fallbackUrl.isNotEmpty && fallbackUrl != url) ok = await fetch(fallbackUrl);
    if (!ok) {
      if (await file.exists()) await file.delete();
      throw Exception('download failed');
    }
    _cache[url] = file.path;
    return file.path;
  }

  /// Text that goes with the shared poster / reel
  static String shareText(String title, String caption) {
    final parts = <String>[
      if (title.isNotEmpty) '📢 $title',
      if (caption.isNotEmpty) caption,
      "🎙 Let's Speak with Surendra — learn to speak English & Hindi.",
      if (!kIsWeb && Platform.isAndroid) 'Download the app: $playStore',
    ];
    return parts.join('\n');
  }

  /// Save to Gallery. Returns a message for the student.
  static Future<String> download({
    required String url,
    required bool video,
    String fallbackUrl = '',
  }) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) return 'Please allow Photos permission to save.';
      }
      final path = await _file(url, video: video, fallbackUrl: fallbackUrl);
      if (video) {
        await Gal.putVideo(path, album: album);
      } else {
        await Gal.putImage(path, album: album);
      }
      return video ? 'Reel saved in your Gallery ✅' : 'Poster saved in your Gallery ✅';
    } on GalException catch (e) {
      debugPrint('Gallery save error: ${e.type}');
      return e.type == GalExceptionType.notEnoughSpace
          ? 'Phone storage is full.'
          : 'Could not save. Please try again.';
    } catch (_) {
      return 'Could not download. Check your internet.';
    }
  }

  /// Open the phone share menu with the file. Returns an error message or null.
  static Future<String?> shareFile({
    required BuildContext context,
    required String url,
    required bool video,
    required String title,
    required String caption,
    String fallbackUrl = '',
  }) async {
    final origin = _origin(context);
    try {
      final path = await _file(url, video: video, fallbackUrl: fallbackUrl);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: video ? 'video/mp4' : 'image/jpeg')],
        text: shareText(title, caption),
        subject: title.isEmpty ? "Let's Speak" : title,
        sharePositionOrigin: origin, // iPad needs this
      ));
      return null;
    } catch (e) {
      debugPrint('Promo share error: $e');
      return 'Could not share. Check your internet.';
    }
  }

  /// Instagram link posts: share the link (the video itself belongs to Instagram)
  static Future<void> shareLink({
    required BuildContext context,
    required String link,
    required String title,
    required String caption,
  }) async {
    final origin = _origin(context);
    try {
      await SharePlus.instance.share(ShareParams(
        text: '${shareText(title, caption)}\n$link',
        sharePositionOrigin: origin,
      ));
    } catch (e) {
      debugPrint('Share link error: $e');
    }
  }

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) return box.localToGlobal(Offset.zero) & box.size;
    return null;
  }
}