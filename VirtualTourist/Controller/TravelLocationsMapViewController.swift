//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/22/22.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Variables
    
    let regionCenterLongitude = "region.center.longitude"
    let regionCenterLatitude = "region.center.latitude"
    let regionSpanLongitudeDelta = "region.span.longitudeDelta"
    let regionSpanLatitudeDelta = "region.span.latitudeDelta"
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreRegion()
    }
    
    // MARK: Custom functions
    
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
    
    // MARK: Map delegates

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistRegion(mapView.region)
    }
}
