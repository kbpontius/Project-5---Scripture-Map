//
//  MapViewController.swift
//  Scripture Map
//
//  Created by Kyle on 11/26/15.
//  Copyright © 2015 Kyle Pontius. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    // MARK: - PROPERTIES
    
    var manager = CLLocationManager()
    var displayDefaultLocation = true
    var geoLocations:[GeoPlace]!
    
    private var defaultLocation:CLLocation!
    private let ldsConferenceCenter = CLLocation(latitude: 40.7725, longitude: -111.8925)
    
    // MARK: - OUTLETS
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setupMapView()
    }
    
    // MARK: - API METHODS
    
    func updateLocations(newLocations: [GeoPlace], animate: Bool = true) {
        geoLocations = newLocations
        goToLocationOnMap(location: nil, animate: animate)
    }
    
    // MARK: - SETUP METHODS
    
    private func setupMapView() {
        mapView.delegate = self
        manager.delegate = self
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        if geoLocations?.count > 0 {
            setAnnotations(getAnnotations(geoLocations))
        } else {
            evaluateLocationAuthorizationStatus()
        }
    }
    
    private func goToLocationOnMap(altitude: Double = 1000, location: CLLocation?, animate: Bool = true) {
        if location == nil {
            if geoLocations?.count > 0 {
                setAnnotations(getAnnotations(geoLocations), animate: animate)
            }
        } else {
            // Default location is SLC if user's location is unknown.
            mapView.removeAnnotations(mapView.annotations)
            setMapTitle("Default Location")
            
            let pin = GeoPin(coordinate: location!.coordinate, title: "")
            setCamera(pin)
        }
    }
    
    // MARK: - HELPER METHODS
    
    private func setMapTitle(title: String) {
        self.navigationItem.title = title
    }
    
    private func setCamera(geoPin: GeoPin, animated: Bool = true) {
        let camera = MKMapCamera(lookingAtCenterCoordinate: geoPin.coordinate, fromEyeCoordinate: geoPin.viewCoordinate!, eyeAltitude: geoPin.altitude)
        camera.heading = geoPin.heading
        mapView.setCamera(camera, animated: animated)
    }
    
    private func setAnnotations(annotations: [GeoPin], animate: Bool = true) {
        if annotations.count == 1 {
            setCamera(annotations.first!)
        } else if annotations.count > 1 {
            mapView.showAnnotations(annotations, animated: animate)
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            if annotations.count > 1 {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(annotations)
            } else {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotation(annotations.first!)
                self.mapView.selectAnnotation(annotations.first!, animated: true)
                self.setMapTitle(annotations.first!.title ?? "")
            }
        }
    }
    
    private func getAnnotations(geoLocations: [GeoPlace]) -> [GeoPin] {
        var annotations = [GeoPin]()
        
        for location in geoLocations {
            let pin = GeoPin(place: location)
            var alreadyIncluded = false
            
            // This loop prevents duplicate annotations from being added
            if annotations.count > 0 {
                for annotation in annotations {
                    if pin.coordinate.latitude == annotation.coordinate.latitude
                        && pin.coordinate.longitude == annotation.coordinate.longitude {
                            alreadyIncluded = true
                            break
                    }
                }
                
                if !alreadyIncluded {
                    annotations.append(pin)
                }
            } else {
                annotations.append(pin)
            }
        }
        
        // This ensures a location is always available to go to
        if annotations.count < 1 {
            resetDefaultLocation()
        }
        
        return Array(annotations)
    }
    
    private func resetDefaultLocation() {
        defaultLocation = ldsConferenceCenter
    }
}

// MARK: - MAPVIEW DELEGATE
extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("Pin")
        
        if view == nil {
            let pinView = MKPinAnnotationView()
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.pinTintColor = UIColor.blueColor()
            
            view = pinView
        } else {
            view?.annotation = annotation
        }
        
        return view
    }
}

// MARK: - LOCATION MANAGER DELEGATE
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        evaluateLocationAuthorizationStatus()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        manager.stopUpdatingLocation()
        
        if displayDefaultLocation {
            displayDefaultLocation = false
            goToLocationOnMap(location: newLocation)
        }
    }
    
    private func evaluateLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.requestWhenInUseAuthorization()
        } else if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            resetDefaultLocation()
            goToLocationOnMap(location: defaultLocation)
        } else {
            manager.startUpdatingLocation()
        }
    }
}