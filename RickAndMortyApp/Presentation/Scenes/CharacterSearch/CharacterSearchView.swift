//
//  CharacterSearchView.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import SwiftUI

/**
 View that allows user to see seached characters
 */
struct CharacterSearchView: View {

    @State private var viewModel = CharacterSearchViewModel(useCase: AppEnvironment.searchCharactersUseCase)

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Characters")
                .navigationDestination(for: Int.self) { characterId in
                    CharacterDetailView(characterId: characterId)
                }
                .searchable(text: $viewModel.query, prompt: "Search characters")
                .onChange(of: viewModel.query) { _, newValue in
                    viewModel.search(newValue)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search characters",
                                   systemImage: "magnifyingglass",
                                   description: Text("Type a name to find Rick and Morty characters."))
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let characters):
            List(characters) { character in
                NavigationLink(value: character.id) {
                    CharacterRow(character: character)
                }
                .accessibilityIdentifier("character-row-\(character.id)")
            }
            .listStyle(.plain)
        case .empty:
            ContentUnavailableView.search(text: viewModel.query)
        case .error(let message):
            ContentUnavailableView("Something went wrong",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(message))
        }
    }
}

private struct CharacterRow: View {
    let character: Character

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            CachedAsyncImage(url: URL(string: character.image)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(DesignSystem.Opacity.placeholder)
            }
            .frame(width: DesignSystem.Size.m,
                   height: DesignSystem.Size.m)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.s))
            .roundedBorder(cornerRadius: DesignSystem.CornerRadius.s)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(character.name).font(.headline)
                Text(character.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CharacterSearchView()
}
