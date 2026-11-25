//
//  TimedCache.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation

/// In-memory cache whose entries expire `ttl` seconds after being stored.
final class TimedCache<Key: Hashable, Value> {

    private struct Entry {
        let value: Value
        let storedAt: Date
    }

    // MARK: - Variables

    private let ttl: TimeInterval
    private let now: () -> Date
    private var entries: [Key: Entry] = [:]

    // MARK: - Methods

    init(ttl: TimeInterval, now: @escaping () -> Date = Date.init) {
        self.ttl = ttl
        self.now = now
    }

    /// Returns the cached value, or `nil` if there is none or it has expired.
    func value(for key: Key) -> Value? {
        guard let entry = entries[key] else { return nil }

        guard now().timeIntervalSince(entry.storedAt) < ttl else {
            entries[key] = nil
            return nil
        }
        return entry.value
    }

    func store(_ value: Value, for key: Key) {
        entries[key] = Entry(value: value, storedAt: now())
    }
}
