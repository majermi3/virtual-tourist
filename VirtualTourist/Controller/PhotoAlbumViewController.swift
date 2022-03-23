//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/22/22.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbum: UICollectionView!
    
    // MARK: Variables
    
    var pin: Pin!
    
    //var fetchedResultsController: NSFetchedResultsController<Pin>
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        
        FlickrClient.search(pin: pin) { searchResponse, error in
            if error != nil {
                // TODO Show user-friendly error
                print(error?.localizedDescription)
                return
            }
            print("loaded")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let region = MKCoordinateRegion(
            center: pin.coordinate,
            latitudinalMeters: CLLocationDistance(exactly: 5000)!,
            longitudinalMeters: CLLocationDistance(exactly: 5000)!
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        mapView.addAnnotation(pin)
    }
    
    // MARK: Custom functions
    
    fileprivate func setupFetchedResultsController() {
        
    }
    
    // MARK: Collection delegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath)
        
        return cell
    }
}
