//
//  ServerCharacterTests.swift
//  RickAndMortyAppTests
//

import Foundation
import Testing
@testable import RickAndMortyApp

@MainActor
struct ServerCharacterTests {

    private func makeSUT(status: String = "Alive", gender: String = "Male") -> ServerCharacter {
        ServerCharacter(id: 1,
                        name: "Rick Sanchez",
                        status: status,
                        species: "Human",
                        gender: gender,
                        image: "https://example.com/1.jpeg")
    }

    @Test func convertsAllFields() {
        let entity = makeSUT().convertToModel()

        #expect(entity == Character(id: 1,
                                    name: "Rick Sanchez",
                                    status: .alive,
                                    species: "Human",
                                    gender: .male,
                                    image: "https://example.com/1.jpeg"))
    }

    @Test(arguments: [("Alive", CharacterStatus.alive),
                      ("Dead", .dead),
                      ("Unknown", .unknown)])
    func mapsKnownStatus(raw: String, expected: CharacterStatus) {
        #expect(makeSUT(status: raw).convertToModel().status == expected)
    }

    @Test(arguments: [("Female", Gender.female),
                      ("Male", .male),
                      ("Genderless", .genderless),
                      ("Unknown", .unknown)])
    func mapsKnownGender(raw: String, expected: Gender) {
        #expect(makeSUT(gender: raw).convertToModel().gender == expected)
    }

    @Test(arguments: ["unknown", "", "alive", "???"])
    func unrecognizedStatusFallsBackToUnknown(raw: String) {
        #expect(makeSUT(status: raw).convertToModel().status == .unknown)
    }

    @Test(arguments: ["unknown", "", "male", "???"])
    func unrecognizedGenderFallsBackToUnknown(raw: String) {
        #expect(makeSUT(gender: raw).convertToModel().gender == .unknown)
    }
}
