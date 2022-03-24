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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbum: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: Variables
    
    var pin: Pin!
    var numOfDownloadedImages = 0
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let region = MKCoordinateRegion(
            center: pin.coordinate,
            latitudinalMeters: CLLocationDistance(exactly: 10000)!,
            longitudinalMeters: CLLocationDistance(exactly: 10000)!
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        mapView.addAnnotation(pin)
        
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: Custom functions
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: DataController.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "\(pin.uuid!)-photos"
        )
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            let count = fetchedResultsController.sections?[0].numberOfObjects
            if count == nil || count == 0 {
                loadFlickrPhotos()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func loadFlickrPhotos() {
        spinner.startAnimating()
        disableNewCollectionButton()
        
        FlickrClient.search(pin: pin) { searchResponse, error in
            self.spinner.stopAnimating()
            if error != nil {
                // TODO Show user-friendly error
                self.enableNewCollectionButton()
                return
            }
            if let flickrPhotos = searchResponse?.photos.photo {
                for flickrPhoto in flickrPhotos {
                    let photo = Photo(context: DataController.shared.viewContext)
                    photo.id = flickrPhoto.id
                    photo.secret = flickrPhoto.secret
                    photo.owner = flickrPhoto.owner
                    photo.server = flickrPhoto.server
                    photo.title = flickrPhoto.title
                    photo.pin = self.pin
                }
                try? DataController.shared.viewContext.save()
            }
        }
    }
    
    fileprivate func enableNewCollectionButton() {
        newCollectionButton.isEnabled = true
    }
    
    fileprivate func disableNewCollectionButton() {
        newCollectionButton.isEnabled = false
    }
    
    // MARK: Actions
    
    @IBAction func loadNewCollection(_ sender: Any) {
        let photos = fetchedResultsController.sections?.first?.objects as! [Photo]
        
        for photo in photos {
            DataController.shared.viewContext.delete(photo)
        }
        try? DataController.shared.viewContext.save()
        loadFlickrPhotos()
    }
    
    // MARK: Delegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoCollectionViewCell
        
        cell.photoView.image = UIImage(systemName: "photo.artframe")
        
        let currentPhoto = fetchedResultsController.object(at: indexPath)
        
        FlickrClient.loadPhoto(photo: currentPhoto) { data, error in
            if error != nil || data == nil {
                // TODO Show error message
            } else {
                cell.photoView.image = UIImage(data: data!)
            }
            self.numOfDownloadedImages += 1
            if self.numOfDownloadedImages == FlickrClient.Search.limit {
                self.enableNewCollectionButton()
                self.numOfDownloadedImages = 0
            }
        }
        
        return cell
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoAlbum.reloadData()
    }
}
