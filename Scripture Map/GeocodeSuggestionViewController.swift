//
//  GeocodeSuggestionViewController.swift
//  Scripture Map
//
//  Created by Kyle on 12/7/15.
//  Copyright © 2015 Kyle Pontius. All rights reserved.
//

import UIKit
import MapKit

class GeocodeSuggestionViewController: UIViewController {
    @IBOutlet weak var txtLongitude: UITextField!
    @IBOutlet weak var txtLatitude: UITextField!
    @IBOutlet weak var txtViewLongitude: UITextField!
    @IBOutlet weak var txtViewLatitude: UITextField!
    @IBOutlet weak var txtViewTilt: UITextField!
    @IBOutlet weak var txtViewRoll: UITextField!
    @IBOutlet weak var txtViewAltitude: UITextField!
    @IBOutlet weak var txtViewHeading: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var suggestGeocodeDelegate: GeocodingSuggestionDelegate!
    var mapCamera: MKMapCamera?
    
    override func viewDidLoad() {
        setupTextFields()
        setupDefaultValues()
        setupMapView()
    }
    
    // MARK: - SETUP METHODS
    
    private func setupDefaultValues() {
        if let camera = mapCamera {
            loadMapCamera(camera)
            refreshMapViewWithNewTextFieldValues(false)
        }
    }
    
    private func setupTextFields() {
        txtLongitude.delegate = self
        txtLatitude.delegate = self
        txtViewLongitude.delegate = self
        txtViewLatitude.delegate = self
        txtViewTilt.delegate = self
        txtViewRoll.delegate = self
        txtViewAltitude.delegate = self
        txtViewHeading.delegate = self
    }
    
    private func setupMapView() {
        mapView.delegate = self
    }
    
    // MARK: - IB ACTIONS
    
    @IBAction func loadMapViewValues(sender: AnyObject) {
        loadMapCamera(mapView.camera)
    }

    @IBAction func cancelTapped(sender: AnyObject) {
        performSegueWithIdentifier("segueUnwindToCancel", sender: self)
    }
    
    @IBAction func saveTapped(sender: AnyObject) {
        validateLatLong() {
            self.dismissViewControllerAnimated(true) {
                // NOTE: First cast to Double to ensure the value is a valid number,
                // then back to String for the method call.
                let latitude = String(Double(self.txtLatitude.text ?? "") ?? 0)
                let longitude = String(Double(self.txtLongitude.text ?? "") ?? 0)
                let viewLatitude = String(Double(self.txtViewLatitude.text ?? "") ?? 0)
                let viewLongitude = String(Double(self.txtViewLongitude.text ?? "") ?? 0)
                let viewTilt = String(Double(self.txtViewTilt.text ?? "") ?? 0)
                let viewRoll = String(Double(self.txtViewRoll.text ?? "") ?? 0)
                let viewAltitude = String(Double(self.txtViewAltitude.text ?? "") ?? 0)
                let viewHeading = String(Double(self.txtViewHeading.text ?? "") ?? 0)
                
                self.suggestGeocodeDelegate.didSuggestLocationToGeocode(latitude, longitude: longitude, viewLatitude: viewLatitude, viewLongitude: viewLongitude, viewTilt: viewTilt, viewRoll: viewRoll, viewAltitude: viewAltitude, viewHeading: viewHeading)
            }
        }
    }
    
    // MARK: - HELPER METHODS
    
    private func validateLatLong(onSuccess: (()->Void)?) {
        let latIsValid = Double(txtLatitude.text!) != nil
        let longIsValid = Double(txtLongitude.text!) != nil
        let highlightColor = UIColor(red: 255/255, green: 116/255, blue: 110/255, alpha: 1.0)
        
        if latIsValid {
            txtLatitude.backgroundColor = UIColor.whiteColor()
        } else {
            txtLatitude.backgroundColor = highlightColor
        }
        
        if longIsValid {
            txtLongitude.backgroundColor = UIColor.whiteColor()
        } else {
            txtLongitude.backgroundColor = highlightColor
        }
        
        if latIsValid && longIsValid {
            onSuccess?()
        }
    }
    
    private func loadMapCamera(mapCamera: MKMapCamera) {
        txtLongitude.text = String(mapCamera.centerCoordinate.longitude)
        txtLatitude.text = String(mapCamera.centerCoordinate.latitude)
        txtViewLongitude.text = txtLongitude.text
        txtViewLatitude.text = txtLatitude.text
        txtViewTilt.text = String(mapCamera.pitch)
        txtViewRoll.text = "0"
        txtViewAltitude.text = String(mapCamera.altitude)
        txtViewHeading.text! = String(mapCamera.heading)
    }
    
    /*
        Normally a great deal of validation would go in here,
        however, due to a great lack of available time to work on
        this I'm going to just assume that the value passed in is a
        double or I'll assign it 0.
    */
    private func refreshMapViewWithNewTextFieldValues(animated: Bool) {
        // This prevents the default values of 0 being taken before the latitude & longitude are provided.
        if !txtLatitude.text!.isEmpty && !txtLongitude.text!.isEmpty {
            let centerCoordinate = CLLocationCoordinate2D(latitude: Double(txtLatitude.text ?? "") ?? 0, longitude: Double(txtLongitude.text ?? "") ?? 0)
            let eyeCoordinate = CLLocationCoordinate2D(latitude: Double(txtViewLatitude.text ?? "") ?? 0, longitude: Double(txtViewLongitude.text ?? "") ?? 0)
            let altitude = Double(txtViewAltitude.text ?? "") ?? 0
            
            let camera = MKMapCamera(lookingAtCenterCoordinate: centerCoordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: altitude)
            
            mapView.setCamera(camera, animated: animated)
            
        }
    }
    
    // Just a small bit of validation before evaluating.
    private func validateTextFields(textField: UITextField) {
        // Prevent any of the textfields from being 0.
        if textField.text!.isEmpty && textField != txtLatitude && textField != txtLongitude {
            textField.text = "0"
        }
        
        if textField == txtLatitude || textField == txtLongitude {
            if textField == self.txtLongitude {
                self.txtViewLongitude.text = self.txtLongitude.text
            }
            
            if textField == self.txtLatitude {
                self.txtViewLatitude.text = self.txtLatitude.text
            }
            
            validateLatLong(nil)
        }
    }
}

// MARK: - MKMAPVIEWDELEGATE EXTENSION
extension GeocodeSuggestionViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.view.endEditing(true)
    }
}

// MARK: - UITEXTFIELDDELEGATE EXTENSION
extension GeocodeSuggestionViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        validateTextFields(textField)
        refreshMapViewWithNewTextFieldValues(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        
        return true
    }
}