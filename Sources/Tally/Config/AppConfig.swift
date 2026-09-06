import Foundation

/// Reads the Supabase project URL/key baked into Info.plist at build time from
/// Config/Secrets.xcconfig (via `$(SUPABASE_URL)` / `$(SUPABASE_ANON_KEY)` variable
/// substitution — see that file and scripts/sync-secrets.sh for where the values come from).
///
/// The anon/publishable key is meant to be embedded in a shipped app (Row Level Security is
/// what actually protects the data, not secrecy of this key) — but Secrets.xcconfig itself
/// still isn't committed, so the project works the same way for anyone who clones it and
/// supplies their own Supabase project.
enum AppConfig {
    static var supabaseURL: URL {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !string.isEmpty, !string.hasPrefix("$("),
              let url = URL(string: string) else {
            fatalError("""
                SUPABASE_URL is missing or unresolved in Info.plist.
                Run scripts/sync-secrets.sh after filling in .env, then re-run `xcodegen generate`.
                """)
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty, !key.hasPrefix("$(") else {
            fatalError("""
                SUPABASE_ANON_KEY is missing or unresolved in Info.plist.
                Run scripts/sync-secrets.sh after filling in .env, then re-run `xcodegen generate`.
                """)
        }
        return key
    }
}
