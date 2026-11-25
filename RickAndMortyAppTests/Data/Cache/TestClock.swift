//
//  TestClock.swift
//  RickAndMortyAppTests
//

import Foundation

/// Controllable clock for time-dependent tests.
final class TestClock {
    private(set) var now = Date(timeIntervalSince1970: 1_000_000)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
