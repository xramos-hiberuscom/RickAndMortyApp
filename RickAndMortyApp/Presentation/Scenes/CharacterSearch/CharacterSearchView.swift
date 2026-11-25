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
                .navigationTitle(CharacterSearchLocalizable.title)
                .navigationDestination(for: Int.self) { characterId in
                    CharacterDetailView(characterId: characterId)
                }
                .searchable(text: $viewModel.query, prompt: CharacterSearchLocalizable.prompt)
                .onChange(of: viewModel.query) { _, newValue in
                    viewModel.search(newValue)
                }
                .onChange(of: viewModel.state) { _, newState in
                    announce(newState)
                }
        }
    }

    /// Results appear without moving VoiceOver focus, so the outcome is announced.
    private func announce(_ state: CharacterSearchViewModel.State) {
        switch state {
        case .loaded(let characters):
            AccessibilityNotification.Announcement(CharacterSearchA11y.resultsAnnouncement(count: characters.count)).post()
        case .empty:
            AccessibilityNotification.Announcement(CharacterSearchA11y.noResultsAnnouncement).post()
        default:
            break
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(CharacterSearchLocalizable.unavailbleTitle,
                                   systemImage: "magnifyingglass",
                                   description: Text(CharacterSearchLocalizable.unavailableDescription))
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(CharacterSearchA11y.loading)
        case .loaded(let characters):
            List(characters) { character in
                NavigationLink(value: character.id) {
                    CharacterRow(character: character)
                }
                .accessibilityIdentifier(CharacterSearchA11y.identifier(of: character.id))
                .accessibilityHint(CharacterSearchA11y.rowHint)
            }
            .listStyle(.plain)
        case .empty:
            ContentUnavailableView.search(text: viewModel.query)
        case .error(let message):
            ContentUnavailableView(CharacterSearchLocalizable.error,
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
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(character.name).font(.headline)
                Text(character.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CharacterSearchView()
}
