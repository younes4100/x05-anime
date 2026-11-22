import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/live_tv/live_channel.dart';
import '../../core/live_tv/live_tv_repository.dart';
import '../../core/models/episode.dart';
import '../../core/models/video_source.dart';
import '../../core/playback/resume_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/frosted_surface.dart';
import '../player/player_screen.dart';
import 'live_tv_labels.dart';

/// A dedicated Live TV destination.
///
/// A guide-style screen: featured channel, a five-channel top row, favourites,
/// source/category filters and a glass card grid. The list is a public M3U
/// playlist over the internet (no LAN, no local server); every card plays
/// through the same [PlayerScreen] every other stream uses.
class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key, this.showBack = false});

  /// Tab use suppresses the back arrow; pushed instances keep it.
  final bool showBack;

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  late final LiveTvRepository _repo;
  final TextEditingController _search = TextEditingController();

  List<LiveTvPlaylist> _sources = LiveTvRepository.curated;
  List<LiveChannel> _channels = const [];
  Set<String> _favorites = const <String>{};
  String _url = LiveTvRepository.defaultUrl;
  String _country = '';
  String _group = '';
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _repo = sl<LiveTvRepository>();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final sources = await _repo.sources(liveTvArabic(context));
    final last = await _repo.lastUrl();
    final favorites = await _repo.favorites();
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _url = sources.any((s) => s.url == last)
          ? last
          : LiveTvRepository.defaultUrl;
      _favorites = favorites;
    });
    await _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await _repo.load(_url, force: force);
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _country = '';
        _group = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickSource(String url) async {
    setState(() => _url = url);
    await _load();
  }

  Future<void> _addPlaylist() async {
    final custom = await _repo.customUrl();
    if (!mounted) return;
    final controller = TextEditingController(text: custom ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(liveTvAddPlaylist(ctx)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: liveTvPlaylistHint(ctx),
            filled: true,
            fillColor: AppColors.accent.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(liveTvCancel(ctx)),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (!value.startsWith('http://') &&
                  !value.startsWith('https://')) {
                Navigator.of(ctx).pop();
                return;
              }
              Navigator.of(ctx).pop(value);
            },
            child: Text(liveTvSave(ctx)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || saved.isEmpty) {
      if (saved == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(liveTvInvalidUrl(context))),
        );
      }
      return;
    }
    await _repo.setCustomUrl(saved);
    if (!mounted) return;
    final sources = await _repo.sources(liveTvArabic(context));
    if (!mounted) return;
    setState(() => _sources = sources);
    await _pickSource(saved);
  }

  Future<void> _toggleFavorite(LiveChannel channel) async {
    final added = await _repo.toggleFavorite(channel.id);
    if (!mounted) return;
    setState(() {
      final next = Set<String>.from(_favorites);
      if (added) {
        next.add(channel.id);
      } else {
        next.remove(channel.id);
      }
      _favorites = next;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? liveTvFavoriteAdded(context, channel.name)
              : liveTvFavoriteRemoved(context, channel.name),
        ),
      ),
    );
  }

  List<String> _choices(String Function(LiveChannel) select) {
    final set = <String>{};
    for (final c in _channels) {
      final value = select(c).trim();
      if (value.isNotEmpty) set.add(value);
    }
    final out = set.toList()..sort();
    return out;
  }

  List<LiveChannel> get _filtered => _repo.filter(
        _channels,
        query: _search.text,
        country: _country,
        group: _group,
      );

  /// Favourites first, then playlist order, deduplicated. The "Top channels"
  /// strip is deliberately five wide — it is the guide's front page.
  List<LiveChannel> _topFive(List<LiveChannel> pool) {
    final ordered = <LiveChannel>[
      ...pool.where((c) => _favorites.contains(c.id)),
      ...pool,
    ];
    final seen = <String>{};
    return ordered.where((c) => seen.add(c.id)).take(5).toList();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _country = '';
      _group = '';
    });
  }

  void _open(LiveChannel channel) {
    final ep = Episode(
      id: channel.id,
      title: channel.name,
      url: channel.url,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          sourceId: 'live:iptv',
          episodes: [ep],
          startIndex: 0,
          resume: sl<ResumeStore>(),
          localOnly: true,
          showTitle: channel.name,
          resolveSources: (_) async => [
            VideoSource(
              url: channel.url,
              quality: 'Live',
              label: channel.name,
              container: SourceContainer.hls,
              headers: channel.playHeaders,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const Spacer(),
          ?action,
        ],
      ),
    );
  }

  Widget _sourceChips(BuildContext context, bool arabic) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _sources.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _sources[i];
          return ChoiceChip(
            label: Text(s.label(arabic)),
            selected: s.url == _url,
            onSelected: (_) => unawaited(_pickSource(s.url)),
            avatar: Icon(
              s.id == 'custom'
                  ? Icons.link_rounded
                  : Icons.public_rounded,
              size: 16,
            ),
          );
        },
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    return FakeFrost(
      opacity: 0.5,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearFilters,
                ),
          hintText: liveTvSearchLabel(context),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext context, bool arabic) {
    final countries = _choices((c) => c.country);
    final groups = _choices((c) => c.group);
    final accent = AppColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonFormField<String>(
                initialValue: _country.isEmpty ? null : _country,
                isDense: true,
                decoration: InputDecoration(
                  labelText: liveTvCountryLabel(context),
                  border: InputBorder.none,
                ),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(liveTvCountryLabel(context)),
                  ),
                  for (final c in countries)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (value) => setState(() => _country = value ?? ''),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: groups.take(24).length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return ChoiceChip(
                  label: Text(liveTvGroupLabel(context)),
                  selected: _group.isEmpty,
                  onSelected: (_) => setState(() => _group = ''),
                );
              }
              final g = groups.take(24).toList()[i - 1];
              return ChoiceChip(
                label: Text(g),
                selected: _group == g,
                onSelected: (_) => setState(() => _group = g),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _channelStrip(
    BuildContext context,
    String title,
    List<LiveChannel> channels, {
    Widget? action,
  }) {
    if (channels.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _sectionHeader(context, title, action: action),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = channels[i];
              return SizedBox(
                width: 172,
                child: _ChannelCard(
                  channel: c,
                  compact: true,
                  favorite: _favorites.contains(c.id),
                  onPlay: () => _open(c),
                  onFavorite: () => unawaited(_toggleFavorite(c)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    ThemeData theme,
    LiveChannel? featured,
    bool arabic,
  ) {
    final accent = AppColors.accent;
    final logo = featured?.logo;
    return SliverAppBar(
      expandedHeight: 268,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: widget.showBack ? const BackButton() : null,
      actions: [
        IconButton(
          tooltip: liveTvRefresh(context),
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => unawaited(_load(force: true)),
        ),
        IconButton(
          tooltip: liveTvAddPlaylist(context),
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () => unawaited(_addPlaylist()),
        ),
      ],
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.38),
                  accent.withValues(alpha: 0.08),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          if (logo != null)
            Positioned.fill(
              child: Image.network(
                logo,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.15),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.live_tv_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      liveTvLabel(context).toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  featured?.name ?? liveTvGuideSubtitle(context),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  featured?.subtitle ?? liveTvSubtitle(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: featured == null
                          ? null
                          : () => _open(featured),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(liveTvPlay(context)),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (featured != null)
                      _FavoriteButton(
                        favorite: _favorites.contains(featured.id),
                        onPressed: () => unawaited(_toggleFavorite(featured)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerMessage(BuildContext context, Widget icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arabic = liveTvArabic(context);
    final theme = Theme.of(context);
    final accent = AppColors.accent;
    final filtered = _filtered;
    final top = _topFive(filtered);
    final favorites = filtered
        .where((c) => _favorites.contains(c.id))
        .toList(growable: false);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 4 : width >= 640 ? 3 : 2;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _hero(
            context,
            theme,
            top.isNotEmpty ? top.first : null,
            arabic,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                liveTvGuideSubtitle(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _sourceChips(context, arabic)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: _searchField(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Text(
                    liveTvChannelsCount(context, filtered.length),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (_country.isNotEmpty || _group.isNotEmpty || _search.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                      label: Text(liveTvClearFilters(context)),
                    ),
                ],
              ),
            ),
          ),
          if (!_loading && _error == null) ...[
            SliverToBoxAdapter(
              child: _channelStrip(
                context,
                liveTvTopFive(context),
                top,
              ),
            ),
            if (favorites.isNotEmpty)
              SliverToBoxAdapter(
                child: _channelStrip(
                  context,
                  liveTvFavorites(context),
                  favorites,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _filterBar(context, arabic),
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionHeader(context, liveTvAllChannels(context)),
            ),
          ],
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _centerMessage(
                context,
                const CircularProgressIndicator(),
                liveTvLoading(context),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _centerMessage(
                context,
                Icon(Icons.wifi_off_rounded, size: 44, color: accent),
                liveTvError(context, _error!),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _centerMessage(
                context,
                Icon(Icons.search_off_rounded, size: 44, color: accent),
                liveTvEmpty(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final c = filtered[i];
                    return _ChannelCard(
                      channel: c,
                      favorite: _favorites.contains(c.id),
                      onPlay: () => _open(c),
                      onFavorite: () => unawaited(_toggleFavorite(c)),
                    );
                  },
                  childCount: filtered.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Text(
                liveTvAttribution(context),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  const _ChannelLogo(this.channel, {this.size = 44});

  final LiveChannel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: channel.logo == null
            ? _logoFallback(context, size)
            : Image.network(
                channel.logo!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _logoFallback(context, size),
              ),
      ),
    );
  }

  Widget _logoFallback(BuildContext context, double size) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.35),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Icon(Icons.tv_rounded, size: size * 0.5, color: Colors.white),
      );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 5, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: favorite ? '★' : '☆',
      icon: Icon(
        favorite ? Icons.star_rounded : Icons.star_border_rounded,
        color: favorite ? Colors.amber : null,
      ),
      onPressed: onPressed,
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.favorite,
    required this.onPlay,
    required this.onFavorite,
    this.compact = false,
  });

  final LiveChannel channel;
  final bool favorite;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    return FakeFrost(
      opacity: 0.55,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ChannelLogo(channel, size: compact ? 36 : 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (channel.subtitle.isNotEmpty)
                      const SizedBox(height: 3),
                    if (channel.subtitle.isNotEmpty)
                      Text(
                        channel.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              _FavoriteButton(favorite: favorite, onPressed: onFavorite),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: compact ? 50 : 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.play_circle_fill_rounded,
                  size: compact ? 30 : 38,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                onPressed: onPlay,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LiveBadge(liveTvLive(context)),
              const Spacer(),
              if (!compact)
                FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(liveTvPlay(context)),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
