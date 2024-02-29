//
//  GameState.swift
//  Guesstaurant
//
//  Created by Anthony Li on 2/25/24.
//

import MapKit
import SwiftUI

/// Overall state of the game. Used by ``GameViewModel`` to communicate updates to ``GameView``.
enum GameState: Equatable {
    /// The game is loading (i.e. requesting location or restaurant data.)
    case loading
    
    /// The game ran into an error while requesting location, fetching restaurants, or retrieving motion data.
    case error
 
    /// The game is ready to start, and is waiting for the player to place the device on their forehead.
    case ready
    
    /// The game is active and displaying the given restaurant.
    case restaurant(MKMapItem)
    
    /// The player got an answer correct.
    case correct
    
    /// The player decided to skip a restaurant.
    case skip
}

extension GameState {
    /// Whether the score should be shown in this state.
    var showsScore: Bool {
        switch self {
        case .loading, .error:
            return false
        default:
            return true
        }
    }
    
    /// The background color to use while the game is in this state.
    var background: Color {
        switch self {
        case .restaurant(_):
            return .blue
        case .correct:
            return .green
        case .error, .skip:
            return .red
        default:
            return .black
        }
    }
}
