//
//  BigTextModifier.swift
//  Guesstaurant
//
//  Created by Anthony Li on 2/25/24.
//

import SwiftUI

struct BigTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .fontWeight(.bold)
    }
}

extension View {
    func bigText() -> some View {
        modifier(BigTextModifier())
    }
}
