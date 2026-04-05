/// Supabase configuration — replace with your project values.
const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const String supabaseAnonKey = 'YOUR_ANON_KEY';

/// Google Sign-In web client ID for OAuth redirect flow.
const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';

/// iOS client ID for Google Sign-In (from GoogleService-Info.plist).
const String googleIosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID';

/// Redirect URL for Supabase OAuth on web.
const String webOAuthRedirectUrl = 'https://packfit.app/auth/callback';

/// Invite / room code character set (no I/O/1/0).
const String codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int codeLength = 6;
