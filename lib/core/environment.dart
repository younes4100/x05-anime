/// Public compile-time application settings.
class Environment {
  // Public Supabase configuration. Override for staging builds with --dart-define.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qewqhswybbeffdosdboj.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_IxLW__LOzTYFhy3oAwBBCg_pyK4ezax',
  );

  // Keep saved sessions when the auth host changes.
  static const String supabaseSessionStorageKey =
      'sb-qewqhswybbeffdosdboj-auth-token';

  // Supabase issues auth tokens; all app cloud-data sync uses the VPS.
  static const String vpsSyncUrl = String.fromEnvironment(
    'VPS_SYNC_URL',
    defaultValue: 'https://sync.x05-anime.example',
  );

  /// Password-reset landing page.
  /// Password-reset landing. Supabase now drives reset (via the auth `site_url`,
  /// which points at this same page); kept for reference. Not used by the
  /// Supabase AuthCubit, which calls `resetPasswordForEmail`.
  static const String passwordResetUrl = 'https://x05-anime.pages.dev/';

  /// Base of the X05 website (landing + reset + the share "open" page).
  static const String siteBaseUrl = 'https://x05-anime.pages.dev';

  /// Share links point here. The page opens the app if installed (via the
  /// [openLinkScheme] scheme below), otherwise offers the download. Its domain
  /// uses the same domain as the password-reset page.
  static const String siteOpenUrl = '$siteBaseUrl/open/';

  /// TV pairing page on the website. Used when someone opens a shared/https
  /// pair link in a browser; the page can hand off to the app via
  /// `x05://pair`. App-facing TV QRs encode the deeplink directly.
  static const String sitePairUrl = '$siteBaseUrl/pair/';

  /// The "open" page redirects to `x05://open?…`; an installed app catches
  /// it (see [OpenLinkService] + the Android manifest intent-filter).
  static const String openLinkScheme = trackerRedirectScheme; // 'x05'
  static const String openLinkHost = 'open';
  static const String pairLinkHost = 'pair';

  // Provisioned backend ids (see docs / setup).
  static const String databaseId = 'main';
  static const String mylistCollectionId = 'mylist';
  static const String historyCollectionId = 'history';
  static const String watchRoomsCollectionId = 'watch_rooms';
  static const String roomParticipantsCollectionId = 'room_participants';
  static const String roomMessagesCollectionId = 'room_messages';
  static const String avatarsBucketId = 'avatars';
  static const String backupsCollectionId = 'backups';

  // ── Tracker OAuth ──────────────────────────────────────────────────────────
  // All redirects share the x05:// scheme; each has its own host with a
  // matching Android intent-filter. Client secrets are embedded where the
  // provider's token exchange requires it (MAL = PKCE, no secret; Simkl needs
  // one) — standard for these APIs and low-risk.
  static const String trackerRedirectScheme = 'x05';

  // AniList — implicit grant (token in URL fragment, 1-year, no secret).
  static const String anilistClientId = '43052';
  static const String anilistRedirectHost = 'anilist-auth';
  static String get anilistRedirectUri =>
      '$trackerRedirectScheme://$anilistRedirectHost';

  // MyAnimeList — OAuth2 PKCE (plain), no client secret.
  static const String malClientId = 'ac006943589381143c4c4e54eac93a89';
  static const String malRedirectHost = 'mal-auth';
  static String get malRedirectUri =>
      '$trackerRedirectScheme://$malRedirectHost';

  // Simkl wants these on EVERY request (url params + a real User-Agent), or
  // the call is invisible in their debug log and they can't help when
  // something breaks. See https://api.simkl.org/conventions/headers.
  static const String simklAppName = 'x05';
  static const String simklApiHost = 'api.simkl.com';
  static const String simklDataHost = 'data.simkl.in';

  // Simkl — OAuth2 authorization-code (needs the secret to exchange the code).
  static const String simklClientId =
      '8b847b09206ccdb0b3de4cc1293d6dd7d355821f5c179c57315da8ba9030eb53';
  static const String simklClientSecret =
      '34ba8e5ac7c8a5c27926dfdf78205e5b913de9928361cb5a243558239298c96d';
  static const String simklRedirectHost = 'simkl-auth';
  static String get simklRedirectUri =>
      '$trackerRedirectScheme://$simklRedirectHost';

  // Back-compat alias (older AniList code referenced this name).
  // ── MangaBaka ────────────────────────────────────────────────────────────
  //
  // Manga/manhwa/manhua only — no anime list, which is why `supportsReading`
  // is the one thing it answers true to.
  //
  // A PUBLIC OAuth client: no secret, PKCE (S256) instead, which is the right
  // shape for an installed app — anything shipped in the APK can be extracted.
  // Endpoints come from https://mangabaka.org/.well-known/openid-configuration
  // (the `.org` host; `api.mangabaka.org/.well-known/*` is 404). MangaBaka's
  // own API docs mention neither OAuth nor tokens, so prefer the discovery
  // document over the docs if they ever disagree.
  static const String mangabakaClientId = 'EkBIEASsBsfRvPKGevUZIcRLSdubVHPK';
  static const String mangabakaRedirectHost = 'mangabaka-auth';
  static String get mangabakaRedirectUri =>
      '$trackerRedirectScheme://$mangabakaRedirectHost';
  static const String mangabakaAuthorizeUrl =
      'https://mangabaka.org/auth/oauth2/authorize';
  static const String mangabakaTokenUrl =
      'https://mangabaka.org/auth/oauth2/token';
  static const String mangabakaRevokeUrl =
      'https://mangabaka.org/auth/oauth2/revoke';
  static const String mangabakaApi = 'https://api.mangabaka.org';

  /// `library.write` is an official scope — third-party writes are supported,
  /// not a workaround. `offline_access` is what returns a refresh token.
  /// `openid` is required by `/v1/my/profile`: with the other four granted it
  /// still answered `BAD_REQUEST: Missing required scope`, which is the OIDC
  /// identity scope missing rather than any library permission.
  static const String mangabakaScopes =
      'openid profile library.read library.write offline_access';

  static const String anilistRedirectScheme = trackerRedirectScheme;
}
