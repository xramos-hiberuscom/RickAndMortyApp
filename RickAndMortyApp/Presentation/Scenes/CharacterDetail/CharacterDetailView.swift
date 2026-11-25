//
//  CharacterDetailView.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import SwiftUI

/**
 View that shows detail information of selected Character
 */
struct CharacterDetailView: View {

    @State private var viewModel: CharacterDetailViewModel

    init(characterId: Int) {
        _viewModel = State(initialValue: CharacterDetailViewModel(characterId: characterId,
                                                                  useCase: AppEnvironment.getCharacterUseCase))
    }

    init(viewModel: CharacterDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(title)
            .task { await viewModel.load() }
    }

    private var title: String {
        if case .loaded(let character) = viewModel.state { return character.name }
        return ""
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let character):
            CharacterDetailContent(character: character)
        case .notFound:
            ContentUnavailableView("Character not found",
                                   systemImage: "person.crop.circle.badge.questionmark")
        case .error(let message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await viewModel.load() } }
            }
        }
    }
}

private struct CharacterDetailContent: View {
    let character: Character

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                CachedAsyncImage(url: URL(string: character.image)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(DesignSystem.Opacity.placeholder)
                }
                .frame(width: DesignSystem.Size.xl,
                       height: DesignSystem.Size.xl)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.m))
                .roundedBorder(cornerRadius: DesignSystem.CornerRadius.m)

                VStack(spacing: DesignSystem.Spacing.m) {
                    LabeledContent("Status") {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(character.status.color)
                                .frame(width: DesignSystem.Size.s,
                                       height: DesignSystem.Size.s)
                            Text(character.status.rawValue)
                        }
                    }
                    LabeledContent("Species", value: character.species)
                    LabeledContent("Gender", value: character.gender.rawValue)
                }
                .padding(.horizontal, DesignSystem.Spacing.l)
            }
            .padding(.vertical, DesignSystem.Spacing.l)
        }
        .accessibilityIdentifier("character-detail")
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView(characterId: 1)
    }
}
