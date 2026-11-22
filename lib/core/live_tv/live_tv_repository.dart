import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_channel.dart';
import 'm3u_parser.dart';

/// A built-in worldwide playlist. iptv-org publishes public, free-to-air
/// streams and keeps them grouped by country and language. The app only reads
/// the list; it hosts no channels and needs no local-network server.
class LiveTvPlaylist {
  const LiveTvPlaylist({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.url,
  });

  final String id;
  final String labelEn;
  final String labelAr;
  final String url;

  String label(bool arabic) => arabic ? labelAr : labelEn;
}

class LiveTvRepository {
  LiveTvRepository({Dio? dio, SharedPreferences? prefs})
      : _dio = dio ?? Dio(),
        _prefs = prefs;

  static const String customUrlKey = 'live_tv_custom_playlist_url';
  static const String lastUrlKey = 'live_tv_last_playlist_url';
  static const String favoritesKey = 'live_tv_favorite_channels';
  static const String defaultUrl =
      'https://iptv-org.github.io/iptv/index.m3u';

  static const List<LiveTvPlaylist> curated = [
    LiveTvPlaylist(
      id: 'world',
      labelEn: 'World · all channels',
      labelAr: 'العالم · كل القنوات',
      url: defaultUrl,
    ),
    LiveTvPlaylist(
      id: 'arabic',
      labelEn: 'Arabic',
      labelAr: 'العربية',
      url: 'https://iptv-org.github.io/iptv/languages/ara.m3u',
    ),
    LiveTvPlaylist(
      id: 'us',
      labelEn: 'United States',
      labelAr: 'الولايات المتحدة',
      url: 'https://iptv-org.github.io/iptv/countries/us.m3u',
    ),
    LiveTvPlaylist(
      id: 'gb',
      labelEn: 'United Kingdom',
      labelAr: 'المملكة المتحدة',
      url: 'https://iptv-org.github.io/iptv/countries/gb.m3u',
    ),
    LiveTvPlaylist(
      id: 'fr',
      labelEn: 'France',
      labelAr: 'فرنسا',
      url: 'https://iptv-org.github.io/iptv/countries/fr.m3u',
    ),
    LiveTvPlaylist(
      id: 'de',
      labelEn: 'Germany',
      labelAr: 'ألمانيا',
      url: 'https://iptv-org.github.io/iptv/countries/de.m3u',
    ),
    LiveTvPlaylist(
      id: 'tr',
      labelEn: 'Turkey',
      labelAr: 'تركيا',
      url: 'https://iptv-org.github.io/iptv/countries/tr.m3u',
    ),
    LiveTvPlaylist(
      id: 'in',
      labelEn: 'India',
      labelAr: 'الهند',
      url: 'https://iptv-org.github.io/iptv/countries/in.m3u',
    ),
    LiveTvPlaylist(
      id: 'jp',
      labelEn: 'Japan',
      labelAr: 'اليابان',
      url: 'https://iptv-org.github.io/iptv/countries/jp.m3u',
    ),
    LiveTvPlaylist(
      id: 'br',
      labelEn: 'Brazil',
      labelAr: 'البرازيل',
      url: 'https://iptv-org.github.io/iptv/countries/br.m3u',
    ),
  ];

  final Dio _dio;
  SharedPreferences? _prefs;

  final Map<String, List<LiveChannel>> _cache = {};
  final Map<String, DateTime> _cachedAt = {};
  static const _cacheTtl = Duration(minutes: 20);

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// The last playlist the viewer opened, or the worldwide default.
  Future<String> lastUrl() async {
    final p = await prefs;
    final saved = p.getString(lastUrlKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return defaultUrl;
  }

  Future<void> rememberUrl(String url) async {
    final p = await prefs;
    await p.setString(lastUrlKey, url.trim());
  }

  Future<String?> customUrl() async {
    final p = await prefs;
    final value = p.getString(customUrlKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> setCustomUrl(String url) async {
    final p = await prefs;
    await p.setString(customUrlKey, url.trim());
  }

  /// Channels the viewer starred. Ids, not URLs: a playlist refresh can move a
  /// stream without losing the favourite.
  Future<Set<String>> favorites() async {
    final p = await prefs;
    return (p.getStringList(favoritesKey) ?? const <String>[]).toSet();
  }

  /// Star or unstar one channel, returning the new state.
  Future<bool> toggleFavorite(String id) async {
    final p = await prefs;
    final ids = (p.getStringList(favoritesKey) ?? const <String>[]).toSet();
    final added = ids.add(id);
    if (!added) ids.remove(id);
    final list = ids.toList()..sort();
    await p.setStringList(favoritesKey, list);
    return added;
  }

  /// All playlist choices shown in the UI, including a saved custom URL.
  Future<List<LiveTvPlaylist>> sources(bool arabic) async {
    final custom = await customUrl();
    final out = List<LiveTvPlaylist>.from(curated);
    if (custom != null) {
      out.add(
        LiveTvPlaylist(
          id: 'custom',
          labelEn: 'My M3U playlist',
          labelAr: 'قائمة M3U الخاصة بي',
          url: custom,
        ),
      );
    }
    return out;
  }

  /// Downloads and parses [url]. Results are cached briefly so switching
  /// filters never refetches the 2.6 MB worldwide list.
  Future<List<LiveChannel>> load(String url, {bool force = false}) async {
    final clean = url.trim();
    if (clean.isEmpty) return const <LiveChannel>[];
    final cached = _cache[clean];
    final at = _cachedAt[clean];
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }

    final response = await _dio.get<String>(
      clean,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
        // iptv-org's full list is ~2.6 MB; give it room.
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final body = response.data ?? '';
    final result = parseM3u(body, baseUrl: clean);
    debugPrint(
      '[live tv] ${result.channels.length} channels from $clean '
      '(${result.skipped} skipped)',
    );
    _cache[clean] = result.channels;
    _cachedAt[clean] = DateTime.now();
    await rememberUrl(clean);
    return result.channels;
  }

  List<LiveChannel> filter(
    List<LiveChannel> channels, {
    String query = '',
    String country = '',
    String group = '',
  }) {
    final q = query.trim().toLowerCase();
    return channels.where((c) {
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      if (country.isNotEmpty && c.country != country) return false;
      if (group.isNotEmpty && c.group != group) return false;
      return true;
    }).toList(growable: false);
  }
}
