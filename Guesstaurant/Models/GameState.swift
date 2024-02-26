//
//  GameState.swift
//  Guesstaurant
//
//  Created by Anthony Li on 2/25/24.
//

import MapKit
import SwiftUI

enum GameState: Equatable {
    case loading
    case error
    
    case ready
    case restaurant(MKMapItem)
    case correct
    case pass
}

extension GameState {
    var showsScore: Bool {
        switch self {
        case .loading, .error:
            return false
        default:
            return true
        }
    }
    
    var background: Color {
        switch self {
        case .restaurant(_):
            return .blue
        case .correct:
            return .green
        case .error, .pass:
            return .red
        default:
            return .black
        }
    }
}
