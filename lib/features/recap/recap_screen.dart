import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/brand/x05_brand.dart';
import '../../core/di/injector.dart';
import '../../core/playback/resume_store.dart';
import '../../core/playback/watch_history.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// X05 Recap — a local, private snapshot of what the active profile has
/// watched. Every number comes from data the app already owns (watch history
/// and resume marks); nothing is uploaded and no provider is queried.
class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  late _RecapData _data;

  @override
  void initState() {
    super.initState();
    _data = _RecapData.collect();
  }

  Future<void> _share(_Copy copy) async {
    final text = copy.shareText(_data);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copy.copied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = _Copy.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _RecapBackdrop(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                    child: Row(
                      children: [
                        const BackButton(),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: const X05Wordmark(height: 19),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: copy.share,
                          onPressed: _data.hasAnything
                              ? () => _share(copy)
                              : null,
                          icon: const Icon(Icons.ios_share_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  sliver: SliverList.list(
                    children: [
                      _HeroCard(data: _data, copy: copy),
                      const SizedBox(height: 18),
                      if (!_data.hasAnything)
                        _EmptyCard(copy: copy)
                      else ...[
                        _StatGrid(data: _data, copy: copy),
                        const SizedBox(height: 18),
                        _ActivityCard(data: _data, copy: copy),
                        const SizedBox(height: 18),
                        if (_data.recent.isNotEmpty) ...[
                          _SectionTitle(
                            title: copy.topTitles,
                            trailing: copy.recentHint,
                          ),
                          const SizedBox(height: 12),
                          _RecentRail(entries: _data.recent, copy: copy),
                          const SizedBox(height: 18),
                        ],
                        _ProgressCard(data: _data, copy: copy),
                      ],
                      const SizedBox(height: 18),
                      _DailySpark(copy: copy),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'X05 ANIME • ${DateTime.now().year}',
                          style: AppText.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _RecapData {
  const _RecapData({
    required this.entries,
    required this.episodes,
    required this.tracked,
    required this.watchedMs,
    required this.titles,
    required this.inProgress,
    required this.streak,
    required this.monthly,
  });

  final List<HistoryEntry> entries;
  final int episodes;
  final int tracked;
  final int watchedMs;
  final int titles;
  final int inProgress;
  final int streak;

  /// Oldest → newest, six buckets, last bucket is the current month.
  final List<int> monthly;

  bool get hasAnything => titles > 0 || tracked > 0 || episodes > 0;

  double get hours => watchedMs / Duration.millisecondsPerHour;

  /// Hero/stat value: whole hours past 100, one decimal past 1, two below.
  String get hoursLabel {
    if (watchedMs <= 0) return '0';
    if (hours >= 100) return hours.round().toString();
    return hours.toStringAsFixed(hours >= 1 ? 1 : 2);
  }

  int get completionPercent {
    if (tracked <= 0) return 0;
    final pct = ((episodes / tracked) * 100).round();
    return pct < 0 ? 0 : (pct > 100 ? 100 : pct);
  }

  List<HistoryEntry> get recent => entries.take(8).toList();

  static _RecapData collect() {
    List<HistoryEntry> entries;
    ResumeStats stats;
    try {
      entries = sl<WatchHistory>().all();
      stats = sl<ResumeStore>().summary();
    } catch (_) {
      // A brand-new install can reach this before the stores finish opening.
      // Showing an honest empty recap beats crashing the page.
      entries = const [];
      stats = ResumeStats.empty;
    }

    final shows = <String>{
      for (final e in entries) '${e.sourceId}\u0000${e.showId}',
    };
    final finishedInHistory = entries.where((e) => e.finished).toList();
    final episodes = stats.finishedEpisodes > 0
        ? stats.finishedEpisodes
        : finishedInHistory.length;

    var watchedMs = stats.watchedMilliseconds;
    if (watchedMs <= 0) {
      watchedMs = finishedInHistory.fold<int>(
        0,
        (sum, e) => sum + e.duration.inMilliseconds,
      );
    }

    final inProgress = entries
        .where((e) => e.duration.inMilliseconds > 0 && !e.finished)
        .length;

    return _RecapData(
      entries: entries,
      episodes: episodes,
      tracked: math.max(stats.trackedEpisodes, entries.length),
      watchedMs: watchedMs,
      titles: shows.length,
      inProgress: inProgress,
      streak: _streak(entries),
      monthly: _monthly(entries),
    );
  }

  static int _streak(List<HistoryEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = <int>{
      for (final e in entries) _dayNumber(e.updatedAt),
    };
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(_dayNumber(cursor.millisecondsSinceEpoch))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(_dayNumber(cursor.millisecondsSinceEpoch))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _dayNumber(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static List<int> _monthly(List<HistoryEntry> entries) {
    final now = DateTime.now();
    final buckets = List<int>.filled(6, 0);
    for (final e in entries) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.updatedAt);
      final diff = (now.year - d.year) * 12 + now.month - d.month;
      if (diff >= 0 && diff < buckets.length) buckets[5 - diff]++;
    }
    return buckets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI
// ─────────────────────────────────────────────────────────────────────────────

class _RecapBackdrop extends StatelessWidget {
  const _RecapBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -140,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.22),
                    AppColors.accent.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -220,
            right: -160,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0B4BD6).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.copy});

  final _RecapData data;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final heroValue = data.hoursLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x332E86FF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123C8F), Color(0xFF0A1730), Color(0xFF070B14)],
          stops: [0, 0.52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.16),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const X05Mark(size: 58, glow: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.story,
                      style: AppText.title.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy.subtitle,
                      style: AppText.caption.copyWith(
                        color: const Color(0xFFB6C9E8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  heroValue,
                  style: AppText.largeTitle.copyWith(
                    fontSize: 58,
                    height: 0.92,
                    letterSpacing: -2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    copy.hours,
                    style: AppText.body.copyWith(
                      color: const Color(0xFFB6C9E8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.playlist_play_rounded,
                label: '${data.episodes} ${copy.episodesUnit}',
              ),
              _HeroChip(
                icon: Icons.auto_awesome_motion_rounded,
                label: '${data.titles} ${copy.titlesUnit}',
              ),
              _HeroChip(
                icon: Icons.local_fire_department_rounded,
                label: '${data.streak} ${copy.daysUnit}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9FC8FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data, required this.copy});

  final _RecapData data;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final hoursText = data.hoursLabel;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.36,
      children: [
        _StatCard(
          icon: Icons.play_circle_outline_rounded,
          value: '${data.episodes}',
          label: copy.episodes,
          tint: const Color(0xFF4DA3FF),
        ),
        _StatCard(
          icon: Icons.schedule_rounded,
          value: hoursText,
          label: copy.hours,
          tint: const Color(0xFF7BE0C3),
        ),
        _StatCard(
          icon: Icons.video_library_outlined,
          value: '${data.titles}',
          label: copy.titles,
          tint: const Color(0xFFFFC46B),
        ),
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          value: '${data.streak}',
          label: copy.streak,
          tint: const Color(0xFFFF7A8A),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.largeTitle.copyWith(
              fontSize: 30,
              height: 1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.data, required this.copy});

  final _RecapData data;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.monthly.fold<int>(0, (a, b) => math.max(a, b));
    final now = DateTime.now();
    final labels = <String>[
      for (var i = 5; i >= 0; i--)
        copy.monthShort(DateTime(now.year, now.month - i, 1)),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(copy.activity, style: AppText.headline),
              const Spacer(),
              Text(
                copy.lastSixMonths,
                style: AppText.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < data.monthly.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxValue == 0
                                  ? 0
                                  : data.monthly[i] / maxValue,
                            ),
                            duration: Duration(milliseconds: 500 + i * 70),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => Container(
                              height: math.max(5.0, 78 * v),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.accent,
                                    const Color(0xFF6FB4FF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: AppText.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data, required this.copy});

  final _RecapData data;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final pct = data.completionPercent / 100;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(copy.completion, style: AppText.headline),
              const Spacer(),
              Text(
                '${data.completionPercent}%',
                style: AppText.headline.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Dot(color: AppColors.accent),
              const SizedBox(width: 7),
              Text(
                '${data.episodes} ${copy.finishedUnit}',
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _Dot(color: const Color(0xFFFFB020)),
              const SizedBox(width: 7),
              Text(
                '${data.inProgress} ${copy.inProgressUnit}',
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _RecentRail extends StatelessWidget {
  const _RecentRail({required this.entries, required this.copy});

  final List<HistoryEntry> entries;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _RecentCard(entry: entries[i], copy: copy),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.entry, required this.copy});

  final HistoryEntry entry;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final cover = entry.cover;
    final ep = entry.episodeNumber;
    return SizedBox(
      width: 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: cover == null || cover.isEmpty
                  ? Container(
                      color: AppColors.surface2,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: cover,
                      httpHeaders: entry.coverHeaders,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.surface2,
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surface2,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            entry.showTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            ep == null
                ? copy.watchedLabel
                : '${copy.episodeShort} ${_episode(ep)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _episode(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.headline),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: AppText.caption.copyWith(color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.copy});
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          const X05Mark(size: 76),
          const SizedBox(height: 16),
          Text(copy.emptyTitle, style: AppText.headline),
          const SizedBox(height: 6),
          Text(
            copy.emptyBody,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DailySpark extends StatelessWidget {
  const _DailySpark({required this.copy});
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    final line = copy.dailyLine(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x262E86FF)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.dailySpark,
                  style: AppText.overline.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  line,
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy — English + Arabic. Other locales fall back to English here rather
// than growing every generated AppLocalizations class for one new feature.
// ─────────────────────────────────────────────────────────────────────────────

class _Copy {
  const _Copy({
    required this.story,
    required this.subtitle,
    required this.hours,
    required this.episodes,
    required this.titles,
    required this.streak,
    required this.episodesUnit,
    required this.titlesUnit,
    required this.daysUnit,
    required this.activity,
    required this.lastSixMonths,
    required this.topTitles,
    required this.recentHint,
    required this.completion,
    required this.finishedUnit,
    required this.inProgressUnit,
    required this.watchedLabel,
    required this.episodeShort,
    required this.emptyTitle,
    required this.emptyBody,
    required this.dailySpark,
    required this.share,
    required this.copied,
    required this.months,
    required this.dailyLines,
  });

  final String story;
  final String subtitle;
  final String hours;
  final String episodes;
  final String titles;
  final String streak;
  final String episodesUnit;
  final String titlesUnit;
  final String daysUnit;
  final String activity;
  final String lastSixMonths;
  final String topTitles;
  final String recentHint;
  final String completion;
  final String finishedUnit;
  final String inProgressUnit;
  final String watchedLabel;
  final String episodeShort;
  final String emptyTitle;
  final String emptyBody;
  final String dailySpark;
  final String share;
  final String copied;
  final List<String> months;
  final List<String> dailyLines;

  static _Copy of(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return isArabic ? _ar : _en;
  }

  String monthShort(DateTime date) => months[date.month - 1];

  String dailyLine(DateTime date) {
    final day = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return dailyLines[day % dailyLines.length];
  }

  String shareText(_RecapData data) {
    return 'X05 ANIME — Recap\n'
        '• ${data.episodes} $episodesUnit\n'
        '• ${data.hoursLabel} $hours\n'
        '• ${data.titles} $titlesUnit\n'
        '• ${data.streak} $daysUnit\n'
        '#X05ANIME';
  }

  static const _en = _Copy(
    story: 'Your watch story',
    subtitle: 'Your stats, your streak, and what you watched most.',
    hours: 'Hours',
    episodes: 'Episodes',
    titles: 'Titles',
    streak: 'Day streak',
    episodesUnit: 'episodes',
    titlesUnit: 'titles',
    daysUnit: 'days',
    activity: 'Activity',
    lastSixMonths: 'Last 6 months',
    topTitles: 'Most watched',
    recentHint: 'Recently',
    completion: 'Completion',
    finishedUnit: 'finished',
    inProgressUnit: 'in progress',
    watchedLabel: 'Watched',
    episodeShort: 'EP',
    emptyTitle: 'Nothing watched yet',
    emptyBody:
        'Start your first episode and your story will appear here. '
        'Everything stays on this device.',
    dailySpark: 'X05 DAILY SPARK',
    share: 'Share recap',
    copied: 'Recap copied',
    months: [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    dailyLines: [
      'Every episode opens a new world. Choose one worth staying in.',
      'The best stories are the ones you keep thinking about after the credits.',
      'A slow week is still part of the journey. Come back when you are ready.',
      'Great anime are built one unforgettable scene at a time.',
      'Watch less, feel more. Quality beats a queue every time.',
      'Your next favourite title is already waiting in your list.',
      'Take the break. The next season will still be there.',
      'The journey matters more than finishing the whole season tonight.',
    ],
  );

  static const _ar = _Copy(
    story: 'حكاية مشاهدتك',
    subtitle: 'إحصاءاتك، سلسلة أيامك، وأكثر ما شاهدت.',
    hours: 'ساعة',
    episodes: 'حلقات',
    titles: 'أعمال',
    streak: 'سلسلة أيام',
    episodesUnit: 'حلقة',
    titlesUnit: 'عملًا',
    daysUnit: 'يومًا',
    activity: 'النشاط',
    lastSixMonths: 'آخر ٦ أشهر',
    topTitles: 'الأكثر مشاهدة',
    recentHint: 'مؤخرًا',
    completion: 'نسبة الإكمال',
    finishedUnit: 'مكتملة',
    inProgressUnit: 'قيد المشاهدة',
    watchedLabel: 'تمت المشاهدة',
    episodeShort: 'حلقة',
    emptyTitle: 'لا توجد مشاهدات بعد',
    emptyBody:
        'ابدأ أول حلقة وستظهر قصتك هنا. كل شيء يبقى على هذا الجهاز.',
    dailySpark: 'شرارة X05 اليومية',
    share: 'مشاركة الملخص',
    copied: 'تم نسخ الملخص',
    months: [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ],
    dailyLines: [
      'كل حلقة تفتح عالمًا جديدًا. اختر عالمًا يستحق البقاء فيه.',
      'أجمل القصص هي التي تبقى في ذهنك بعد النهاية.',
      'الأسبوع الهادئ جزء من الرحلة أيضًا. عد عندما تكون جاهزًا.',
      'الأنمي العظيم يُصنع مشهدًا لا يُنسى في كل مرة.',
      'شاهد أقل وعِش أكثر. الجودة أهم من قائمة طويلة.',
      'عملك القادم المفضّل ينتظرك بالفعل في قائمتك.',
      'خذ استراحة. الموسم القادم سيبقى في مكانه.',
      'الرحلة أهم من إنهاء الموسم كله الليلة.',
    ],
  );
}
