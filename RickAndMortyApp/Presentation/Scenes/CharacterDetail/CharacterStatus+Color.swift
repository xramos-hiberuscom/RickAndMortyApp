//
//  CharacterStatus+Color.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import SwiftUI

extension CharacterStatus {

    /// Color of the indicator shown next to the status.
    var color: Color {
        switch self {
        case .alive: .green
        case .dead: .red
        case .unknown: .gray
        }
    }
}
