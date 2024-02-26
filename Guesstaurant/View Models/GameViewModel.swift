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
    @Published private(set) var state = GameState.loading {
        didSet {
            pauseProcessingUntilDate = Date(timeIntervalSinceNow: 1)
        }
    }
    
    @Published private(set) var score = 0
    fileprivate(set) var restaurants = [MKMapItem]()
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let feedbackGenerator = UINotificationFeedbackGenerator()
    
    var isRequestingLocation = false
    var pauseProcessingUntilDate = Date.distantPast
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        if !isRequestingLocation {
            isRequestingLocation = true
            locationManager.requestLocation()
        }
    }
    
    func triggerLoad() {
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            isRequestingLocation = false
            let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 2000)
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .foodMarket, .bakery, .cafe, .winery])
            fetchPlaces(for: request)
        }
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
                        guard Date() >= pauseProcessingUntilDate else {
                            return
                        }
                        
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
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

fileprivate extension GameViewModel {
    func fetchPlaces(for request: MKLocalPointsOfInterestRequest) {
        Task {
            do {
                let search = MKLocalSearch(request: request)
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
