//
//  GameViewModel.swift
//  Guesstaurant
//
//  Created by the CIS 1951 team on 2/25/24.
//

import CoreLocation
import CoreMotion
import MapKit
import SwiftUI

/// The game's view model.
class GameViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// The current state of the game. See ``GameState`` for a list of possible values.
    @Published private(set) var state = GameState.loading
    
        /// The number of restaurants the player got correct.
    @Published private(set) var score = 0
    
    /// A list of restaurants to rotate between. Populated by the ``fetchPlaces(search:)`` method.
    fileprivate var restaurants = [MKMapItem]()
    
    // TODO: Add properties and methods as needed
    
    /// Starts loading the game by requesting location access, or requesting the location itself if access has
    /// already been granted.
    func loadGame() {
        state = .loading
        // TODO: Fill this in during step 2
    }
    
    /// Starts the game itself by setting the state to ready and starting motion updates.
    ///
    /// Called when `fetchPlaces` finishes loading restaurants.
    func startGame() {
        // TODO: Fill this in during steps 4 and 5
    }
    
    /// Updates the game's state based on new motion data.
    /// 
    /// Should be called whenever the game receives a motion update.
    /// 
    /// - Parameter motion: The latest device motion data.
    func handleMotion(_ motion: CMDeviceMotion) {
        switch state {
        case .ready, .correct, .skip:
            if (correctThreshold...incorrectThreshold).contains(absoluteRoll) {
                if let restaurant = restaurants.randomElement() {
                    state = .restaurant(restaurant)
                } else {
                    print("List of restaurants is empty!")
                    state = .error
                }
            }
        case .restaurant(_):
            if absoluteRoll < correctThreshold {
                state = .correct
                score += 1
                feedbackGenerator.notificationOccurred(.success)
            } else if absoluteRoll > incorrectThreshold {
                state = .skip
                feedbackGenerator.notificationOccurred(.error)
            }
        default:
            // Do nothing
            break
        }
    }
}

fileprivate extension GameViewModel {
    /// Starts looking for places that match the given search, adding them to the `restaurants` array.
    ///
    /// This method returns immediately, but calls ``startGame()`` when the search completes.
    ///
    /// - Parameter search: An MKLocalSearch object describing the places to search for.
    func fetchPlaces(search: MKLocalSearch) {
        Task {
            do {
                let response = try await search.start()
                await MainActor.run {
                    restaurants = response.mapItems
                    startGame()
                }
            } catch {
                print("Failed to get list of places: \(error)")
                state = .error
            }
        }
    }
}
