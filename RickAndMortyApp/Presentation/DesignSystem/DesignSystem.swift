//
//  DesignSystem.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import SwiftUI

/// Design tokens shared by all the app views.
enum DesignSystem {

    enum Spacing {
        static let xxs: CGFloat = 2
        static let m: CGFloat = 12
    }

    enum Size {
        static let characterThumbnail: CGFloat = 56
    }

    enum CornerRadius {
        static let s: CGFloat = 8
    }

    enum Opacity {
        static let placeholder: Double = 0.2
    }
}
