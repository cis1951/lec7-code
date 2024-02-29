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

class GameViewModel: ObservableObject {
    @Published private(set) var state = GameState.loading
    @Published private(set) var score = 0
    fileprivate(set) var restaurants = [MKMapItem]()
    
    func loadGame() {
        state = .loading
        // TODO: Fill this in during step 2
    }
    
    func startGame() {
        // TODO: Fill this in during steps 4 and 5
    }
    
    func handleMotion(_ motion: CMDeviceMotion) {
        switch state {
        case .ready, .correct, .pass:
            // TODO: Fill this in during step 6
            break
        case .restaurant(_):
            // TODO: Fill this in during step 6
            break
        default:
            // Do nothing
            break
        }
    }
}

fileprivate extension GameViewModel {
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
