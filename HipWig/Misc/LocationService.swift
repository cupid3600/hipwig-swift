//
//  LocationManager.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/14/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationService: class {
    var allowFetchingLocation: Bool { get }
    
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func fetchLocation(_ completion: @escaping (String?) -> Void)
    func statusChanged(_ completion: @escaping (CLAuthorizationStatus) -> Void)
}

class LocationServiceImplementation: NSObject, LocationService {
    
    private var locationManager = CLLocationManager()
    private var latestLocation: CLLocation?
    private var fetchLocationCompletion: ((String?) -> Void)?
    private var statusChangedCompletion: ((CLAuthorizationStatus) -> (Void))?

    var allowFetchingLocation: Bool {
        get {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            default:
                return false
            }
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 5.0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startUpdatingLocation() {
        if !allowFetchingLocation {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func fetchLocation(_ completion: @escaping (String?) -> Void) {
        if let latestLocation = self.latestLocation {
            self.cityName(from: latestLocation, completion: completion)
        } else {
            if let location = locationManager.location {
                self.cityName(from: location, completion: completion)
            } else {
                self.startUpdatingLocation()
                self.fetchLocationCompletion = completion
            }
        }
    }

    func statusChanged(_ completion: @escaping (CLAuthorizationStatus) -> Void) {
        self.statusChangedCompletion = completion
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationServiceImplementation : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.latestLocation = locations.sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }.first
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }
        else {
            self.locationManager.stopUpdatingLocation()
        }
        
        self.statusChangedCompletion?(status)

        if let completion = self.fetchLocationCompletion, let location = manager.location {
            self.cityName(from: location, completion: completion)
        }
    }
    
    private func cityName(from location: CLLocation, completion: @escaping (String?) -> Void) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { placemarks, _ in
            completion(placemarks?.first?.subAdministrativeArea)
        }
    }
}


