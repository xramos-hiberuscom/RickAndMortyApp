//
//  TimedCacheTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct TimedCacheTests {

    private let clock = TestClock()
    private let sut: TimedCache<String, Int>

    init() {
        let clock = clock
        sut = TimedCache(ttl: 120, now: { clock.now })
    }

    @Test func returnsNilForUnknownKey() {
        #expect(sut.value(for: "a") == nil)
    }

    @Test func returnsStoredValueWhileValid() {
        sut.store(1, for: "a")
        clock.advance(by: 119.9)
        #expect(sut.value(for: "a") == 1)
    }

    @Test func expiresAfterTTL() {
        sut.store(1, for: "a")
        clock.advance(by: 120)
        #expect(sut.value(for: "a") == nil)
    }

    @Test func storingAgainRefreshesValueAndExpiration() {
        sut.store(1, for: "a")
        clock.advance(by: 100)
        sut.store(2, for: "a")
        clock.advance(by: 100)

        #expect(sut.value(for: "a") == 2)
    }

    @Test func keysExpireIndependently() {
        sut.store(1, for: "a")
        clock.advance(by: 100)
        sut.store(2, for: "b")
        clock.advance(by: 30)

        #expect(sut.value(for: "a") == nil)
        #expect(sut.value(for: "b") == 2)
    }
}
