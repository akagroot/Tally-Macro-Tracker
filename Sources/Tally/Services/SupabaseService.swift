import Foundation
import Supabase

/// Single shared Supabase client for the app. No auth session yet (see schema.sql notes) —
/// every request goes out under the anon key, scoped by RLS policies that currently allow
/// full access. Revisit this the moment real accounts exist.
enum SupabaseService {
    // Postgres/PostgREST returns timestamptz as ISO8601 WITH fractional seconds (e.g.
    // "2026-09-05T12:34:56.789+00:00"), which Foundation's default `.iso8601` strategy
    // (no fractional seconds) fails to parse. Try both, fractional first.
    //
    // `nonisolated(unsafe)`: ISO8601DateFormatter isn't marked Sendable by Foundation even
    // though concurrent read-only use (.date(from:)/.string(from:) after setup) is fine in
    // practice — a well-known Swift 6 strict-concurrency gap, not a real data race here.
    nonisolated(unsafe) private static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    nonisolated(unsafe) private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let client: SupabaseClient = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoWithFractional.date(from: string) { return date }
            if let date = isoPlain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unrecognized date format: \(string)"
            )
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoWithFractional.string(from: date))
        }

        return SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(encoder: encoder, decoder: decoder)
            )
        )
    }()

    /// The single hardcoded user id every per-user table currently defaults to (see schema.sql).
    /// Swap this out for a real signed-in user id once auth exists.
    static let currentUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}
