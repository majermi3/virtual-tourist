//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/22/22.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Variables
    
    let regionCenterLongitude = "region.center.longitude"
    let regionCenterLatitude = "region.center.latitude"
    let regionSpanLongitudeDelta = "region.span.longitudeDelta"
    let regionSpanLatitudeDelta = "region.span.latitudeDelta"
    
    var pins: [Pin] = []
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addLongPressGestureToMap()
        restoreRegion()
        loadPins()
    }
    
    // MARK: Custom functions
    
    fileprivate func loadPins() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest) {
            pins = result
            addPins()
        }
    }
    
    func persistRegion(_ region: MKCoordinateRegion) {
        UserDefaults.standard.set(region.center.longitude, forKey: regionCenterLongitude)
        UserDefaults.standard.set(region.center.latitude, forKey: regionCenterLatitude)
        UserDefaults.standard.set(region.span.longitudeDelta, forKey: regionSpanLongitudeDelta)
        UserDefaults.standard.set(region.span.latitudeDelta, forKey: regionSpanLatitudeDelta)
    }
    
    func restoreRegion() {
        let regionCenterLongitude = UserDefaults.standard.double(forKey: regionCenterLongitude)
        let regionCenterLatitude = UserDefaults.standard.double(forKey: regionCenterLatitude)
        let regionSpanLongitude = UserDefaults.standard.double(forKey: regionSpanLongitudeDelta)
        let regionSpanLatitude = UserDefaults.standard.double(forKey: regionSpanLatitudeDelta)
        
        guard regionCenterLongitude != 0, regionCenterLatitude != 0, regionSpanLongitude != 0, regionSpanLatitude != 0 else {
            return
        }
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: regionCenterLatitude, longitude: regionCenterLongitude),
            span: MKCoordinateSpan(latitudeDelta: regionSpanLatitude, longitudeDelta: regionSpanLongitude)
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    fileprivate func addLongPressGestureToMap() {
        let longPressed = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gesture:)))
        mapView.addGestureRecognizer(longPressed)
    }
    
    fileprivate func persistPin(coordinates: CLLocationCoordinate2D) {
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = coordinates.latitude
        pin.longitude = coordinates.longitude
        
        try? DataController.shared.viewContext.save()
    }
    
    fileprivate func addPinAnnotation(_ coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func addPins() {
        for pin in pins {
            addPinAnnotation(CLLocationCoordinate2DMake(pin.latitude, pin.longitude))
        }
    }
    
    @objc func addPin(gesture: UILongPressGestureRecognizer) {
        let touchPoint = gesture.location(in: gesture.view)
        let coordinates = (gesture.view as? MKMapView)?.convert(touchPoint, toCoordinateFrom: gesture.view)
        
        if let coordinates = coordinates {
            addPinAnnotation(coordinates)
            persistPin(coordinates: coordinates)
        }
    }
    
    // MARK: Map delegates

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistRegion(mapView.region)
    }
}
