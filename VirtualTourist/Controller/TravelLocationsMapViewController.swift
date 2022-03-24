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
            addPinAnnotations()
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
    
    @objc func addPin(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            return
        }
        
        let touchPoint = gesture.location(in: gesture.view)
        let coordinates = (gesture.view as? MKMapView)?.convert(touchPoint, toCoordinateFrom: gesture.view)
        
        if let coordinates = coordinates {
            let pin = Pin(context: DataController.shared.viewContext)
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            
            addPinAnnotation(pin: pin)
            try? DataController.shared.viewContext.save()
        }
    }
    
    fileprivate func addPinAnnotations() {
        for pin in pins {
            addPinAnnotation(pin: pin)
        }
    }
    
    fileprivate func addPinAnnotation(pin: Pin) {
        mapView.addAnnotation(pin)
    }
    
    func goToPhotoAlbum(pin: Pin) {
        let storyboard = UIStoryboard (name: "Main", bundle: nil)
        let photoAlbumVC = storyboard.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        photoAlbumVC.pin = pin
        
        self.navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
    
    // MARK: Map delegates

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistRegion(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation {
            mapView.deselectAnnotation(pin, animated: false)
            goToPhotoAlbum(pin: pin as! Pin)
        }
    }
    
}
