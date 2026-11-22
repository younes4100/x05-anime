import 'package:equatable/equatable.dart';

/// One playable channel parsed from an M3U playlist.
///
/// Deliberately tiny: Live TV has no seasons, resume marks, trackers or
/// downloads. The player only needs a title, a stream URL and optional headers.
class LiveChannel extends Equatable {
  const LiveChannel({
    required this.id,
    required this.name,
    required this.url,
    this.group = '',
    this.logo,
    this.country = '',
    this.language = '',
    this.headers = const <String, String>{},
  });

  final String id;
  final String name;
  final String url;
  final String group;
  final String? logo;
  final String country;
  final String language;
  final Map<String, String> headers;

  String get subtitle {
    final parts = <String>[
      if (country.isNotEmpty) country.toUpperCase(),
      if (language.isNotEmpty) language.toUpperCase(),
      if (group.isNotEmpty) group,
    ];
    return parts.join(' · ');
  }

  /// Headers for the stream request. Some free-to-air hosts reject a bare
  /// request, so carry whatever the playlist declares plus a browser UA.
  Map<String, String> get playHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        ...headers,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        group,
        logo,
        country,
        language,
        headers,
      ];
}
