//
//  View+RoundedBorder.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 25/11/2026.
//

import SwiftUI

extension View {

    /// Draws a rounded border (inside the view bounds) on top of the view.
    func roundedBorder(cornerRadius: CGFloat,
                       width: CGFloat = DesignSystem.BorderWidth.s,
                       color: Color = .secondary) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: width)
        }
    }
}
