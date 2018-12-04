//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Daniel Kilders Díaz on 03/12/2018.
//  Copyright © 2018 dankil. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    var updatingLocation = false
    var lastLocationError: Error?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: - Actions
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        // Allow user to stop retrieving location
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        
        updateLabels()
    }
    
    // MARK: - CLLocation Manager Delegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        // If location is from long ago, it's from cache, ignore it
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        // If accuracy is negative, ignore it
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        // New reading more useful than previous one ?
        // Larger accuracy value = less accurate
        if location == nil || location!.horizontalAccuracy < newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            
            // If accuracy is as good or better than the one we wanted, stop retrieving location
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("Done retrieving location!")
                stopLocationManager()
            }
            updateLabels()
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings.",
            preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    private func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    private func updateLabels() {
        if let location = location {
            // Shows 8 digits after decimal point
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            
            let statusMessage: String
            
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    // No permissions
                    statusMessage = "Location Services Disabled"
                } else {
                    // Some other error with Core Location, usually it means there was no way of getting a location fix
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                // Even with no errors, user could have disabled location entirely on their device
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                // Searching
                statusMessage = "Searching..."
            } else {
                // !Searching
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
            configureGetButton()
        }
    }
    
    private func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
}


