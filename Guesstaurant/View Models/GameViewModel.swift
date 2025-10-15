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
import OSLog

/// The game's view model.
@Observable class GameViewModel: NSObject, CLLocationManagerDelegate {
    /// The current state of the game. See ``GameState`` for a list of possible values.
    private(set) var state = GameState.loading
    
    /// The number of restaurants the player got correct.
    private(set) var score = 0
    
    /// A list of restaurants to rotate between. Populated by the ``fetchPlaces(search:)`` method.
    @ObservationIgnored fileprivate var restaurants = [MKMapItem]()
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Guesstaurant", category: "GameViewModel")
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let feedbackGenerator = UINotificationFeedbackGenerator()
        
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    /// Starts loading the game by requesting location access, or requesting the location itself if access has
    /// already been granted.
    func loadGame() {
        state = .loading
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.log("User granted location access!")
            locationManager.requestLocation()
        case .denied, .restricted:
            logger.fault("User denied location access!")
            state = .error
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
                    
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 2000)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .foodMarket, .bakery, .cafe])
            
        let search = MKLocalSearch(request: request)
        fetchPlaces(search: search)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.fault("Failed to get location: \(error)")
        state = .error
    }
    
    /// Starts the game itself by setting the state to ready and starting motion updates.
    ///
    /// Called when `fetchPlaces` finishes loading restaurants.
    func startGame() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1 / 50
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                if let self {
                    if let motion {
                        handleMotion(motion)
                    } else if let error {
                        logger.fault("Failed to receive motion update: \(error)")
                        state = .error
                        motionManager.stopDeviceMotionUpdates()
                    }
                }
            }
            
            state = .ready
        } else {
            logger.fault("Device motion is not available!")
            state = .error
        }
    }
    
    /// Updates the game's state based on new motion data.
    /// 
    /// Should be called whenever the game receives a motion update.
    /// 
    /// - Parameter motion: The latest device motion data.
    func handleMotion(_ motion: CMDeviceMotion) {
        let correctThreshold = Double.pi * 0.35
        let incorrectThreshold = Double.pi * 0.65
        let absoluteRoll = abs(motion.attitude.roll)
        
        switch state {
        case .ready, .correct, .skip:
            if (correctThreshold...incorrectThreshold).contains(absoluteRoll) {
                if let restaurant = restaurants.randomElement() {
                    state = .restaurant(restaurant)
                } else {
                    logger.error("List of restaurants is empty!")
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
                logger.fault("Failed to get list of places: \(error)")
                state = .error
            }
        }
    }
}
