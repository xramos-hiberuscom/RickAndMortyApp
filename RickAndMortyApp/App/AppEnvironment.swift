//
//  AppEnvironment.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import Foundation

/// Composition point for the use cases used by the scenes.
/// When launched with `-UITesting` (Debug only) it provides deterministic stubs instead of the network.
enum AppEnvironment {

    /// Single repository instance, so its search cache lives as long as the app.
    private static let characterRepository = CharacterRepository()

    static var searchCharactersUseCase: SearchCharactersUseCaseContract {
        #if DEBUG
        if isUITesting { return UITestSearchCharactersUseCase() }
        #endif
        return SearchCharactersUseCase(repository: characterRepository)
    }

    static var getCharacterUseCase: GetCharacterUseCaseContract {
        #if DEBUG
        if isUITesting { return UITestGetCharacterUseCase() }
        #endif
        return GetCharacterUseCase(repository: characterRepository)
    }

    #if DEBUG
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }
    #endif
}

#if DEBUG
private enum UITestData {
    static let characters = [
        Character(id: 1, name: "Rick Sanchez", status: .alive, species: "Human", gender: .male, image: ""),
        Character(id: 2, name: "Morty Smith", status: .alive, species: "Human", gender: .male, image: ""),
        Character(id: 3, name: "Birdperson", status: .dead, species: "Bird-Person", gender: .male, image: "")
    ]
}

private struct UITestSearchCharactersUseCase: SearchCharactersUseCaseContract {
    func execute(name: String) async throws -> [Character] {
        UITestData.characters.filter { $0.name.localizedCaseInsensitiveContains(name) }
    }
}

private struct UITestGetCharacterUseCase: GetCharacterUseCaseContract {
    func execute(id: Int) async throws -> Character? {
        UITestData.characters.first { $0.id == id }
    }
}
#endif
