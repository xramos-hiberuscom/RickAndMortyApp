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

    /// 45 characters (ids 100...144) matched by the query "gherkin", to exercise pagination (3 pages).
    static let gherkins = (0..<45).map {
        Character(id: 100 + $0, name: "Gherkin \($0)", status: .alive, species: "Pickle", gender: .male, image: "")
    }
    static let pageSize = 20
}

private struct UITestSearchCharactersUseCase: SearchCharactersUseCaseContract {
    func execute(name: String, page: Int) async throws -> CharactersPage {
        let matches = (UITestData.characters + UITestData.gherkins)
            .filter { $0.name.localizedCaseInsensitiveContains(name) }
        let size = UITestData.pageSize
        let start = min((page - 1) * size, matches.count)
        let end = min(start + size, matches.count)
        return CharactersPage(characters: Array(matches[start..<end]),
                              page: page,
                              hasNextPage: end < matches.count)
    }
}

private struct UITestGetCharacterUseCase: GetCharacterUseCaseContract {
    func execute(id: Int) async throws -> Character? {
        (UITestData.characters + UITestData.gherkins).first { $0.id == id }
    }
}
#endif
