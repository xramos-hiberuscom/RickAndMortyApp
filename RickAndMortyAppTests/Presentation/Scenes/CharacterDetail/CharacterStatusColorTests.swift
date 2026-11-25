//
//  CharacterStatusColorTests.swift
//  RickAndMortyAppTests
//

import SwiftUI
import Testing
@testable import RickAndMortyApp

@MainActor
struct CharacterStatusColorTests {

    @Test(arguments: [(CharacterStatus.alive, Color.green),
                      (.dead, Color.red),
                      (.unknown, Color.gray)])
    func statusHasExpectedColor(status: CharacterStatus, expected: Color) {
        #expect(status.color == expected)
    }
}
