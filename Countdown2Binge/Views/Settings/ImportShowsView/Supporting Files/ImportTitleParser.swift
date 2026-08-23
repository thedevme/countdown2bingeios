//
//  ImportTitleParser.swift
//  Countdown2Binge
//
//  Turns a pasted blob into a clean, de-duplicated list of show titles.
//  Ported from c2b-import.jsx (`importParse` / `importNorm`).
//
//  A list can arrive in almost any shape — one per line, comma separated,
//  numbered, bulleted, with a trailing season or a year in brackets. Everything
//  is normalised before it ever reaches TMDB, because a search for
//  "1. Severance season 2 (2022)" finds nothing.
//
//  Pure text handling: no network, no state, no engine involvement.
//

import Foundation

enum ImportTitleParser {

    /// Split a pasted blob into candidate titles, cleaned and de-duplicated.
    /// Order is preserved — the user sees their list back in the order they
    /// wrote it.
    static func parse(_ raw: String) -> [String] {
        var seen = Set<String>()
        var titles: [String] = []

        for chunk in raw.components(separatedBy: CharacterSet(charactersIn: "\n,;·|")) {
            let cleaned = clean(chunk)
            guard !cleaned.isEmpty else { continue }

            let key = normalized(cleaned)
            guard !key.isEmpty, !seen.contains(key) else { continue }

            seen.insert(key)
            titles.append(cleaned)
        }
        return titles
    }

    /// Strip the decoration people paste along with a title.
    static func clean(_ line: String) -> String {
        var s = line

        // Leading list markers: "1." "2)" "3]" "-" "–" "*" "•" ">"
        s = s.replacingOccurrences(
            of: #"^\s*(?:\d+[.)\]]|[-–—*•>])\s*"#,
            with: "",
            options: .regularExpression
        )
        // A year in brackets: "(2024)"
        s = s.replacingOccurrences(
            of: #"\(\s*\d{4}\s*\)"#,
            with: "",
            options: .regularExpression
        )
        // A trailing season: "season 3", "S3"
        s = s.replacingOccurrences(
            of: #"\b(?:season|s)\s*\d+\b"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // Collapse whitespace
        s = s.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Comparison key — case, punctuation, accents and a leading article
    /// shouldn't make two entries different. Used for de-duping the paste and
    /// for judging whether a TMDB result is really the show that was asked for.
    ///
    /// Diacritics are folded, so a typed "Shogun" matches TMDB's "Shōgun".
    /// Without that fold the exact match fails and a loose one wins instead —
    /// which is how "Shogun" ended up resolving to "Abarenbo Shogun".
    static func normalized(_ title: String) -> String {
        var s = title.folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        s = s.replacingOccurrences(
            of: #"^(the|a|an)\s+"#,
            with: "",
            options: .regularExpression
        )
        return s.filter { $0.isLetter || $0.isNumber }
    }

    /// Is this candidate the show that was typed?
    ///
    /// Exact only, on the normalised key. No prefix or substring fallback:
    /// if TMDB's search — which is already forgiving — comes back without the
    /// title the user wrote, they wrote it wrong, and guessing at a near-miss
    /// is how "Shogun" ends up as "Abarenbo Shogun". A miss is reported so
    /// they can correct it.
    ///
    /// "Exact" is on the normalised key, so these all still match: casing,
    /// punctuation, accents (Shogun / Shōgun) and a leading article
    /// (Bear / The Bear). Those are the same title written differently, not a
    /// different show.
    static func matches(candidate: String, query: String) -> Bool {
        let c = normalized(candidate)
        let q = normalized(query)
        guard !c.isEmpty, !q.isEmpty else { return false }
        return c == q
    }

    /// The first TMDB result that IS the typed show, or nil if none is.
    /// Results arrive popularity-first, so when a remake shares its original's
    /// name the better-known one wins.
    static func bestMatchIndex(candidates: [String], query: String) -> Int? {
        candidates.firstIndex { matches(candidate: $0, query: query) }
    }
}
