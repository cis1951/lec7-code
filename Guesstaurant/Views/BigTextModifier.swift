//
//  BigTextModifier.swift
//  Guesstaurant
//
//  Created by Anthony Li on 2/25/24.
//

import SwiftUI

/// A modifier that applies a large, prominent text style.
struct BigTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .fontWeight(.bold)
    }
}

extension View {
    /// Applies a large, prominent text style.
    func bigText() -> some View {
        modifier(BigTextModifier())
    }
}
