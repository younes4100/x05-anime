import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/ui/settings_widgets.dart';
import '../admin_repository.dart';

/// In-app admin console for X05 ANIME.
///
/// Sign-in uses Supabase Auth with the public publishable key and every read or
/// write is checked again by the server (`is_admin()` + RLS). No secret is
/// bundled, no token is persisted, and the app's normal session is untouched.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminRepository _repo = AdminRepository();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final TextEditingController _anTitleAr = TextEditingController();
  final TextEditingController _anTitleEn = TextEditingController();
  final TextEditingController _anBodyAr = TextEditingController();
  final TextEditingController _anBodyEn = TextEditingController();

  final TextEditingController _relVersion = TextEditingController();
  final TextEditingController _relUrl = TextEditingController();
  final TextEditingController _relNotesAr = TextEditingController();
  final TextEditingController _relNotesEn = TextEditingController();

  final TextEditingController _adminEmail = TextEditingController();

  AdminSession? _session;
  bool _busy = false;
  String? _error;
  String? _notice;
  int _tab = 0;
  Map<String, dynamic> _stats = const <String, dynamic>{};

  final Map<String, List<Map<String, dynamic>>> _rows =
      <String, List<Map<String, dynamic>>>{
    'announcements': <Map<String, dynamic>>[],
    'releases': <Map<String, dynamic>>[],
    'reports': <Map<String, dynamic>>[],
    'users': <Map<String, dynamic>>[],
    'admins': <Map<String, dynamic>>[],
  };
  final Set<String> _loading = <String>{};

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _emailCtrl,
      _passwordCtrl,
      _anTitleAr,
      _anTitleEn,
      _anBodyAr,
      _anBodyEn,
      _relVersion,
      _relUrl,
      _relNotesAr,
      _relNotesEn,
      _adminEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  String _friendly(Object error) {
    final raw = error is AdminException ? error.message : error.toString();
    switch (raw) {
      case 'not_admin':
        return _t(
          'هذا الحساب غير مسموح له بالدخول إلى لوحة الأدمن.',
          'This account is not in the admin allowlist.',
        );
      case 'auth_failed':
      case 'Invalid login credentials':
        return _t('البريد أو كلمة المرور غير صحيحة.', 'Invalid email or password.');
      default:
        return raw;
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = _t('أدخل البريد وكلمة المرور.', 'Enter email and password.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _repo.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      _passwordCtrl.clear();
      if (!mounted) return;
      setState(() => _session = session);
      await _loadAll();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logout() {
    setState(() {
      _session = null;
      _error = null;
      _notice = null;
      _stats = const <String, dynamic>{};
      for (final key in _rows.keys) {
        _rows[key] = <Map<String, dynamic>>[];
      }
      _passwordCtrl.clear();
    });
  }

  Future<void> _loadAll() async {
    final session = _session;
    if (session == null) return;
    await Future.wait<void>(<Future<void>>[
      _loadStats(session),
      _loadTable(
        'announcements',
        () => _repo.select('app_announcements', session.token),
      ),
      _loadTable(
        'releases',
        () => _repo.select('app_releases', session.token, order: 'published_at.desc'),
      ),
      _loadTable('reports', () => _repo.select('app_reports', session.token)),
      _loadTable('users', () => _repo.listUsers(session.token)),
      _loadTable(
        'admins',
        () => _repo.select('admin_emails', session.token, order: 'email.asc'),
      ),
    ]);
  }

  Future<void> _loadStats(AdminSession session) async {
    try {
      final data = await _repo.stats(session.token);
      if (mounted) setState(() => _stats = data);
    } catch (e) {
      if (mounted) setState(() => _notice = _friendly(e));
    }
  }

  Future<void> _loadTable(
    String key,
    Future<List<Map<String, dynamic>>> Function() loader,
  ) async {
    setState(() => _loading.add(key));
    try {
      final rows = await loader();
      if (mounted) setState(() => _rows[key] = rows);
    } catch (e) {
      if (mounted) setState(() => _notice = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading.remove(key));
    }
  }

  Future<void> _act(Future<void> Function() action, String success) async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) setState(() => _notice = success);
      await _loadAll();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _str(Map<String, dynamic> row, String key) =>
      (row[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: settingsAppBar(
        _t('لوحة الأدمن', 'Admin panel'),
        actions: <Widget>[
          if (_session != null)
            IconButton(
              tooltip: _t('خروج', 'Sign out'),
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _session == null ? _buildLogin() : _buildConsole(),
      ),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            color: AppColors.settingsCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 46,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t('دخول الأدمن', 'Admin sign in'),
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'الوصول مقتصر على البريد المسموح به في Supabase فقط.',
                      'Access is limited to the Supabase admin allowlist.',
                    ),
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  _field(
                    _emailCtrl,
                    _t('البريد الإلكتروني', 'Email'),
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _passwordCtrl,
                    _t('كلمة المرور', 'Password'),
                    obscure: true,
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppText.caption.copyWith(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _busy ? _t('جارٍ الدخول…', 'Signing in…') : _t('دخول', 'Sign in'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t(
                      'لا تُحفظ كلمة المرور أو رمز الدخول على الجهاز.',
                      'No password or access token is stored on this device.',
                    ),
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsole() {
    final labels = <String>[
      _t('نظرة عامة', 'Overview'),
      _t('إعلانات', 'Announcements'),
      _t('إصدارات', 'Releases'),
      _t('بلاغات', 'Reports'),
      _t('مستخدمون', 'Users'),
      _t('أدمن', 'Admins'),
    ];
    return Column(
      children: <Widget>[
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _notice!,
              style: AppText.caption.copyWith(color: Colors.greenAccent),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _error!,
              style: AppText.caption.copyWith(color: Colors.redAccent),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: <Widget>[
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(labels[i]),
                    selected: _tab == i,
                    onSelected: (_) => setState(() => _tab = i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: <Widget>[
              _panel(<Widget>[_overview()]),
              _announcementsPanel(),
              _releasesPanel(),
              _reportsPanel(),
              _usersPanel(),
              _adminsPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(16),
    children: children,
  );

  Widget _overview() {
    final entries = <MapEntry<String, dynamic>>[
      MapEntry(_t('المستخدمون', 'Users'), _stats['users']),
      MapEntry(_t('الإعلانات', 'Announcements'), _stats['announcements']),
      MapEntry(_t('الإصدارات', 'Releases'), _stats['releases']),
      MapEntry(_t('بلاغات مفتوحة', 'Open reports'), _stats['open_reports']),
    ];
    return Card(
      color: AppColors.settingsCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _t('بيانات مباشرة من Supabase', 'Live data from Supabase'),
              style: AppText.headline,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final e in entries)
                  SizedBox(
                    width: 150,
                    child: Card(
                      color: AppColors.surface2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: <Widget>[
                            Text(
                              '${e.value ?? 0}',
                              style: AppText.largeTitle.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(e.key, style: AppText.caption),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _session?.email ?? '',
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementsPanel() {
    final rows = _rows['announcements'] ?? const <Map<String, dynamic>>[];
    return _panel(<Widget>[
      Card(
        color: AppColors.settingsCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              _field(_anTitleAr, _t('العنوان بالعربية', 'Title (Arabic)')),
              const SizedBox(height: 10),
              _field(_anTitleEn, _t('العنوان بالإنجليزية', 'Title (English)')),
              const SizedBox(height: 10),
              _field(_anBodyAr, _t('النص بالعربية', 'Body (Arabic)'), maxLines: 3),
              const SizedBox(height: 10),
              _field(_anBodyEn, _t('النص بالإنجليزية', 'Body (English)'), maxLines: 3),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () => _act(() async {
                    await _repo.insert('app_announcements', _token!, <String, dynamic>{
                      'title_ar': _anTitleAr.text.trim(),
                      'title_en': _anTitleEn.text.trim(),
                      'body_ar': _anBodyAr.text.trim(),
                      'body_en': _anBodyEn.text.trim(),
                      'active': true,
                    });
                    _anTitleAr.clear();
                    _anTitleEn.clear();
                    _anBodyAr.clear();
                    _anBodyEn.clear();
                  }, _t('تم نشر الإعلان.', 'Announcement published.')),
                  child: Text(_t('نشر إعلان', 'Publish announcement')),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_loading.contains('announcements'))
        const Center(child: CircularProgressIndicator())
      else
        for (final row in rows)
          _dataTile(
            title: _str(row, 'title_ar').isEmpty
                ? _str(row, 'title_en')
                : _str(row, 'title_ar'),
            subtitle: _str(row, 'body_ar').isEmpty
                ? _str(row, 'body_en')
                : _str(row, 'body_ar'),
            badge: row['active'] == true ? _t('مفعّل', 'Active') : _t('مخفي', 'Hidden'),
            actions: <Widget>[
              _textButton(
                row['active'] == true ? _t('إخفاء', 'Hide') : _t('إظهار', 'Show'),
                () => _act(() => _repo.update(
                  'app_announcements',
                  _token!,
                  _str(row, 'id'),
                  <String, dynamic>{'active': row['active'] != true},
                ), _t('تم التحديث.', 'Updated.')),
              ),
              _textButton(
                _t('حذف', 'Delete'),
                () => _act(() => _repo.delete(
                  'app_announcements',
                  _token!,
                  _str(row, 'id'),
                ), _t('تم الحذف.', 'Deleted.')),
                danger: true,
              ),
            ],
          ),
    ]);
  }

  Widget _releasesPanel() {
    final rows = _rows['releases'] ?? const <Map<String, dynamic>>[];
    return _panel(<Widget>[
      Card(
        color: AppColors.settingsCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              _field(_relVersion, _t('الإصدار (مثال 1.0)', 'Version (e.g. 1.0)')),
              const SizedBox(height: 10),
              _field(_relUrl, _t('رابط APK', 'APK URL')),
              const SizedBox(height: 10),
              _field(_relNotesAr, _t('ملاحظات بالعربية', 'Notes (Arabic)'), maxLines: 2),
              const SizedBox(height: 10),
              _field(_relNotesEn, _t('ملاحظات بالإنجليزية', 'Notes (English)'), maxLines: 2),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () => _act(() async {
                    await _repo.insert('app_releases', _token!, <String, dynamic>{
                      'version': _relVersion.text.trim(),
                      'apk_url': _relUrl.text.trim(),
                      'notes_ar': _relNotesAr.text.trim(),
                      'notes_en': _relNotesEn.text.trim(),
                      'published': true,
                    });
                    _relVersion.clear();
                    _relUrl.clear();
                    _relNotesAr.clear();
                    _relNotesEn.clear();
                  }, _t('تم نشر الإصدار.', 'Release published.')),
                  child: Text(_t('نشر إصدار', 'Publish release')),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_loading.contains('releases'))
        const Center(child: CircularProgressIndicator())
      else
        for (final row in rows)
          _dataTile(
            title: 'v${_str(row, 'version')}',
            subtitle: _str(row, 'apk_url'),
            badge: row['published'] == true ? _t('منشور', 'Published') : _t('مسودة', 'Draft'),
            actions: <Widget>[
              _textButton(
                row['published'] == true ? _t('إلغاء', 'Unpublish') : _t('نشر', 'Publish'),
                () => _act(() => _repo.update(
                  'app_releases',
                  _token!,
                  _str(row, 'id'),
                  <String, dynamic>{'published': row['published'] != true},
                ), _t('تم التحديث.', 'Updated.')),
              ),
              _textButton(
                _t('حذف', 'Delete'),
                () => _act(() => _repo.delete(
                  'app_releases',
                  _token!,
                  _str(row, 'id'),
                ), _t('تم الحذف.', 'Deleted.')),
                danger: true,
              ),
            ],
          ),
    ]);
  }

  Widget _reportsPanel() {
    final rows = _rows['reports'] ?? const <Map<String, dynamic>>[];
    return _panel(<Widget>[
      if (_loading.contains('reports'))
        const Center(child: CircularProgressIndicator())
      else
        for (final row in rows)
          _dataTile(
            title: _str(row, 'title'),
            subtitle: _str(row, 'details'),
            badge: _str(row, 'status'),
            actions: <Widget>[
              _textButton(
                _t('حذف', 'Delete'),
                () => _act(() => _repo.delete(
                  'app_reports',
                  _token!,
                  _str(row, 'id'),
                ), _t('تم الحذف.', 'Deleted.')),
                danger: true,
              ),
            ],
          ),
    ]);
  }

  Widget _usersPanel() {
    final rows = _rows['users'] ?? const <Map<String, dynamic>>[];
    return _panel(<Widget>[
      if (_loading.contains('users'))
        const Center(child: CircularProgressIndicator())
      else
        for (final row in rows)
          _dataTile(
            title: _str(row, 'email'),
            subtitle: _str(row, 'created_at'),
            badge: null,
            actions: const <Widget>[],
          ),
    ]);
  }

  Widget _adminsPanel() {
    final rows = _rows['admins'] ?? const <Map<String, dynamic>>[];
    final me = _session?.email.toLowerCase() ?? '';
    return _panel(<Widget>[
      Card(
        color: AppColors.settingsCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _field(_adminEmail, _t('بريد أدمن جديد', 'New admin email')),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => _act(() async {
                  final email = _adminEmail.text.trim().toLowerCase();
                  if (email.isEmpty) return;
                  await _repo.insert('admin_emails', _token!, <String, dynamic>{
                    'email': email,
                  });
                  _adminEmail.clear();
                }, _t('تمت الإضافة.', 'Admin added.')),
                child: Text(_t('إضافة', 'Add')),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_loading.contains('admins'))
        const Center(child: CircularProgressIndicator())
      else
        for (final row in rows)
          _dataTile(
            title: _str(row, 'email'),
            subtitle: null,
            badge: null,
            actions: <Widget>[
              if (_str(row, 'email').toLowerCase() != me)
                _textButton(
                  _t('إزالة', 'Remove'),
                  () => _act(() => _repo.delete(
                    'admin_emails',
                    _token!,
                    _str(row, 'email'),
                    column: 'email',
                  ), _t('تمت الإزالة.', 'Removed.')),
                  danger: true,
                ),
            ],
          ),
    ]);
  }

  String? get _token => _session?.token;

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      maxLines: maxLines,
      style: AppText.body,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dataTile({
    required String title,
    String? subtitle,
    String? badge,
    required List<Widget> actions,
  }) {
    return Card(
      color: AppColors.settingsCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppText.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (badge != null && badge.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      badge,
                      style: AppText.caption.copyWith(color: AppColors.accent),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onPressed, {bool danger = false}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: danger ? Colors.redAccent : AppColors.accent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(60, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppText.caption),
    );
  }
}
