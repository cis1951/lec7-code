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

class GameViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var state = GameState.loading
    @Published private(set) var score = 0
    fileprivate(set) var restaurants = [MKMapItem]()
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let feedbackGenerator = UINotificationFeedbackGenerator()
    
    var isRequestingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func loadGame() {
        state = .loading
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .denied, .restricted:
            state = .error
        default:
            break
        }
    }
    
    func requestLocation() {
        if !isRequestingLocation {
            isRequestingLocation = true
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        isRequestingLocation = false
            
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 2000)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .foodMarket, .bakery, .cafe])
            
        let search = MKLocalSearch(request: request)
        fetchPlaces(search: search)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequestingLocation = false
        print("Failed to get location: \(error)")
        state = .error
    }
    
    func startGame() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1 / 50
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                if let self {
                    if let motion {
                        handleMotion(motion)
                    } else if let error {
                        print("Failed to receive motion update: \(error)")
                        state = .error
                        motionManager.stopDeviceMotionUpdates()
                    }
                }
            }
            
            state = .ready
        } else {
            print("Device motion is not available!")
            state = .error
        }
    }
    
    func handleMotion(_ motion: CMDeviceMotion) {
        let correctThreshold = Double.pi * 0.35
        let incorrectThreshold = Double.pi * 0.65
        let absoluteRoll = abs(motion.attitude.roll)
        
        switch state {
        case .ready, .correct, .pass:
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
                state = .pass
                feedbackGenerator.notificationOccurred(.error)
            }
        default:
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
