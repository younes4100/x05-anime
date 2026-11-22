import 'live_channel.dart';

/// Result of parsing an M3U playlist: playable channels plus honest counts.
class M3uParseResult {
  const M3uParseResult({
    required this.channels,
    required this.skipped,
    required this.totalLines,
  });

  final List<LiveChannel> channels;
  final int skipped;
  final int totalLines;
}

/// Parses the subset of M3U/HLS playlists that matters for channel playback.
///
/// Supports `#EXTINF`, `#EXTGRP`, `#EXTVLCOPT` / `#KODIPROP` header lines,
/// BOM/CRLF, relative URLs and comment lines. Encrypted or malformed entries
/// are skipped and counted rather than crashing the whole channel list.
class M3uParser {
  const M3uParser();

  static final RegExp _attr = RegExp(r'([\w-]+)="([^"]*)"');
  static final RegExp _countryFromId = RegExp(
    r'\.([a-z]{2})(?:@[^.]*)?$',
    caseSensitive: false,
  );

  M3uParseResult parse(String raw, {String baseUrl = ''}) {
    var text = raw;
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    final lines = text.split(RegExp(r'\r?\n'));
    final channels = <LiveChannel>[];
    final seen = <String>{};
    var skipped = 0;

    String? pendingName;
    Map<String, String> pendingAttrs = const {};
    Map<String, String> pendingHeaders = const {};
    var groupOverride = '';

    void clearPending() {
      pendingName = null;
      pendingAttrs = const {};
      pendingHeaders = const {};
      groupOverride = '';
    }

    void acceptUrl(String rawUrl) {
      final name = pendingName;
      if (name == null || name.trim().isEmpty) {
        clearPending();
        return;
      }
      final url = _absolute(rawUrl, baseUrl);
      // Snapshot everything before clearing — clearPending() resets the
      // pending maps that build the channel below.
      final attrs = pendingAttrs;
      final headers = pendingHeaders;
      final group = groupOverride;
      clearPending();
      if (url.isEmpty ||
          (!url.startsWith('http://') && !url.startsWith('https://'))) {
        skipped++;
        return;
      }
      final tvgId = attrs['tvg-id'] ?? '';
      final resolvedGroup = group.isNotEmpty
          ? group
          : attrs['group-title'] ?? '';
      final logo = _absolute(attrs['tvg-logo'] ?? '', baseUrl);
      final id = '${tvgId.isNotEmpty ? tvgId : name}|$url';
      if (!seen.add(id)) return;
      channels.add(
        LiveChannel(
          id: id,
          name: name.trim(),
          url: url,
          group: resolvedGroup,
          logo: logo.isEmpty ? null : logo,
          country: (attrs['tvg-country'] ?? _inferCountry(tvgId))
              .toUpperCase(),
          language: attrs['tvg-language'] ?? '',
          headers: Map<String, String>.from(headers),
        ),
      );
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#EXTM3U')) continue;

      if (line.startsWith('#EXTINF:')) {
        if (pendingName != null) skipped++;
        final body = line.substring('#EXTINF:'.length).trim();
        final comma = body.indexOf(',');
        pendingName = comma >= 0 ? body.substring(comma + 1).trim() : '';
        final attrPart = comma >= 0 ? body.substring(0, comma) : body;
        final attrs = <String, String>{};
        for (final m in _attr.allMatches(attrPart)) {
          attrs[m.group(1)!.toLowerCase()] = m.group(2)!;
        }
        pendingAttrs = attrs;
        continue;
      }
      if (line.startsWith('#EXTGRP:')) {
        groupOverride = line.substring('#EXTGRP:'.length).trim();
        continue;
      }
      if (line.startsWith('#EXTVLCOPT:') || line.startsWith('#KODIPROP:')) {
        final kv = line.substring(line.indexOf(':') + 1).trim();
        final eq = kv.indexOf('=');
        if (eq > 0) {
          final key = kv.substring(0, eq).trim().toLowerCase();
          final value = kv.substring(eq + 1).trim();
          if (key == 'http-user-agent' || key == 'user-agent') {
            pendingHeaders = {...pendingHeaders, 'User-Agent': value};
          } else if (key == 'http-referrer' || key == 'referer') {
            pendingHeaders = {...pendingHeaders, 'Referer': value};
          } else if (key == 'http-origin') {
            pendingHeaders = {...pendingHeaders, 'Origin': value};
          }
        }
        continue;
      }
      if (line.startsWith('#')) continue;
      acceptUrl(line);
    }
    if (pendingName != null) skipped++;

    channels.sort((a, b) {
      final c = a.country.compareTo(b.country);
      if (c != 0) return c;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return M3uParseResult(
      channels: List.unmodifiable(channels),
      skipped: skipped,
      totalLines: lines.length,
    );
  }

  String _absolute(String value, String baseUrl) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('//')) return 'https:$v';
    if (baseUrl.isEmpty) return '';
    final base = Uri.tryParse(baseUrl);
    if (base == null) return '';
    return base.resolveUri(Uri.parse(v)).toString();
  }

  String _inferCountry(String tvgId) {
    final m = _countryFromId.firstMatch(tvgId);
    return m?.group(1)?.toUpperCase() ?? '';
  }
}

/// Convenience top-level parser so callers don't need to hold an instance.
M3uParseResult parseM3u(String raw, {String baseUrl = ''}) =>
    const M3uParser().parse(raw, baseUrl: baseUrl);
