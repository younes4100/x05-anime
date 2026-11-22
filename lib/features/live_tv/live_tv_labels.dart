import 'package:flutter/material.dart';

/// Small bilingual label set for Live TV.
///
/// Kept out of the generated ARB/l10n classes on purpose: this feature ships in
/// an APK that must not need a codegen pass, and every label here has an Arabic
/// and an English form so both audiences see their own language.
bool liveTvArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

String liveTvLabel(BuildContext context) =>
    liveTvArabic(context) ? 'التلفزيون المباشر' : 'Live TV';

String liveTvSubtitle(BuildContext context) => liveTvArabic(context)
    ? 'قنوات العالم المفتوحة · iptv-org'
    : 'Free-to-air channels worldwide · iptv-org';

String liveTvSourceLabel(BuildContext context) =>
    liveTvArabic(context) ? 'المصدر' : 'Source';

String liveTvSearchLabel(BuildContext context) =>
    liveTvArabic(context) ? 'ابحث عن قناة…' : 'Search channels…';

String liveTvCountryLabel(BuildContext context) =>
    liveTvArabic(context) ? 'كل الدول' : 'All countries';

String liveTvGroupLabel(BuildContext context) =>
    liveTvArabic(context) ? 'كل التصنيفات' : 'All categories';

String liveTvChannelsCount(BuildContext context, int count) =>
    liveTvArabic(context) ? '$count قناة' : '$count channels';

String liveTvCustomPlaylist(BuildContext context) =>
    liveTvArabic(context) ? 'قائمة M3U الخاصة بي' : 'My M3U playlist';

String liveTvAddPlaylist(BuildContext context) =>
    liveTvArabic(context) ? 'إضافة رابط M3U' : 'Add M3U URL';

String liveTvRefresh(BuildContext context) =>
    liveTvArabic(context) ? 'تحديث' : 'Refresh';

String liveTvLoading(BuildContext context) =>
    liveTvArabic(context) ? 'جارٍ تحميل القنوات…' : 'Loading channels…';

String liveTvEmpty(BuildContext context) =>
    liveTvArabic(context) ? 'لا توجد قنوات مطابقة' : 'No matching channels';

String liveTvError(BuildContext context, Object error) {
  final raw = error.toString();
  if (raw.contains('SocketException') ||
      raw.contains('Failed host') ||
      raw.contains('timeout')) {
    return liveTvArabic(context)
        ? 'تعذر الوصول لقائمة القنوات — تحقق من الإنترنت'
        : 'Cannot reach the channel list — check your internet';
  }
  return liveTvArabic(context)
      ? 'تعذر تحميل القنوات: $raw'
      : 'Could not load channels: $raw';
}

String liveTvPlaylistHint(BuildContext context) => liveTvArabic(context)
    ? 'الصق رابط قائمة M3U (مثال: https://example.com/list.m3u)'
    : 'Paste an M3U playlist URL (e.g. https://example.com/list.m3u)';

String liveTvSave(BuildContext context) =>
    liveTvArabic(context) ? 'حفظ' : 'Save';

String liveTvCancel(BuildContext context) =>
    liveTvArabic(context) ? 'إلغاء' : 'Cancel';

String liveTvInvalidUrl(BuildContext context) => liveTvArabic(context)
    ? 'أدخل رابطًا يبدأ بـ http أو https'
    : 'Enter a URL starting with http or https';

String liveTvAttribution(BuildContext context) => liveTvArabic(context)
    ? 'قنوات عامة من مشروع iptv-org. التطبيق لا يستضيف أي بث.'
    : 'Public channels from the iptv-org project. X05 hosts no streams.';

String liveTvFeatured(BuildContext context) =>
    liveTvArabic(context) ? 'قناة اليوم' : 'Featured channel';

String liveTvTopFive(BuildContext context) =>
    liveTvArabic(context) ? 'الأكثر مشاهدة' : 'Top channels';

String liveTvFavorites(BuildContext context) =>
    liveTvArabic(context) ? 'المفضلة' : 'Favourites';

String liveTvAllChannels(BuildContext context) =>
    liveTvArabic(context) ? 'كل القنوات' : 'All channels';

String liveTvLive(BuildContext context) =>
    liveTvArabic(context) ? 'مباشر' : 'LIVE';

String liveTvPlay(BuildContext context) =>
    liveTvArabic(context) ? 'شاهد الآن' : 'Watch now';

String liveTvClearFilters(BuildContext context) =>
    liveTvArabic(context) ? 'إزالة الفلاتر' : 'Clear filters';

String liveTvNoFavorites(BuildContext context) => liveTvArabic(context)
    ? 'لم تضف أي قناة للمفضلة بعد — اضغط على النجمة.'
    : 'No favourites yet — tap the star on any channel.';

String liveTvFavoriteAdded(BuildContext context, String name) =>
    liveTvArabic(context) ? 'أُضيفت $name للمفضلة' : '$name added to favourites';

String liveTvFavoriteRemoved(BuildContext context, String name) =>
    liveTvArabic(context)
        ? 'أُزيلت $name من المفضلة'
        : '$name removed from favourites';

String liveTvGuideSubtitle(BuildContext context) => liveTvArabic(context)
    ? 'دليل قنوات عالمي محدث لحظيًا'
    : 'A live guide to free channels around the world';
