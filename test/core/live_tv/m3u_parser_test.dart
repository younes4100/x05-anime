import 'package:flutter_test/flutter_test.dart';
import 'package:watch_app/core/live_tv/m3u_parser.dart';

void main() {
  test('parses EXTINF attributes, VLC headers and relative URLs', () {
    const m3u = '''
#EXTM3U
#EXTINF:-1 tvg-id="BBCWorld.news@HD" tvg-logo="/logo.png" tvg-country="gb" tvg-language="en" group-title="News",BBC World News
#EXTVLCOPT:http-user-agent=CustomAgent
#EXTVLCOPT:http-referrer=https://example.com/
/streams/bbc.m3u8
#EXTINF:-1 tvg-id="France24.fr@SD" group-title="News",France 24
https://example.com/france.m3u8
#EXTGRP:World
https://example.com/world.m3u8
''';

    final result = parseM3u(m3u, baseUrl: 'https://list.example.com/index.m3u');

    expect(result.channels, hasLength(2));
    final bbc = result.channels.firstWhere((c) => c.name == 'BBC World News');
    expect(bbc.url, 'https://list.example.com/streams/bbc.m3u8');
    expect(bbc.logo, 'https://list.example.com/logo.png');
    expect(bbc.country, 'GB');
    expect(bbc.language, 'en');
    expect(bbc.group, 'News');
    expect(bbc.headers['User-Agent'], 'CustomAgent');
    expect(bbc.headers['Referer'], 'https://example.com/');

    final france = result.channels.firstWhere((c) => c.name == 'France 24');
    expect(france.group, 'News');
  });

  test('skips malformed entries without throwing', () {
    const m3u = '''
#EXTM3U
#EXTINF:-1,Broken
not-a-stream
#EXTINF:-1,Good
https://example.com/good.m3u8
''';
    final result = parseM3u(m3u);
    expect(result.channels, hasLength(1));
    expect(result.channels.single.name, 'Good');
    expect(result.skipped, 1);
  });
}
