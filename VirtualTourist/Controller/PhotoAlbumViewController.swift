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
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    // MARK: Variables
    
    var pin: Pin!
    var numOfDownloadedImages = 0
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    // MARK: Lifecycle
    
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
        if pin.photos?.count == 0 {
            loadFlickrPhotos()
        }
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
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func loadFlickrPhotos() {
        spinner.startAnimating()
        disableNewCollectionButton()
        hideNoImagesLabel()
        
        FlickrClient.search(pin: pin) { searchResponse, error in
            self.spinner.stopAnimating()
            if error != nil {
                self.showErrorMessage(title: "Cannot find pictures", message: error?.localizedDescription ?? "")
                return
            }
            if let flickrPhotos = searchResponse?.photos.photo {
                if flickrPhotos.count > 0 {
                    for flickrPhoto in flickrPhotos {
                        let photo = Photo(context: DataController.shared.viewContext)
                        photo.id = flickrPhoto.id
                        photo.secret = flickrPhoto.secret
                        photo.owner = flickrPhoto.owner
                        photo.server = flickrPhoto.server
                        photo.title = flickrPhoto.title
                        photo.pin = self.pin
                        
                        self.pin.addToPhotos(photo)
                        
                        try? DataController.shared.viewContext.save()
                    }
                } else {
                    self.showNoImagesLabel()
                }
            }
            self.enableNewCollectionButton()
        }
    }
    
    fileprivate func removePinPhotos() {
        for photo in fetchedResultsController.fetchedObjects! {
            DataController.shared.viewContext.delete(photo)
            do {
                try DataController.shared.viewContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func enableNewCollectionButton() {
        newCollectionButton.isEnabled = true
    }
    
    fileprivate func disableNewCollectionButton() {
        newCollectionButton.isEnabled = false
    }
    
    fileprivate func showNoImagesLabel() {
        noImagesLabel.isHidden = false
    }
    
    fileprivate func hideNoImagesLabel() {
        noImagesLabel.isHidden = true
    }
    
    fileprivate func showErrorMessage(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func loadNewCollection(_ sender: Any) {
        removePinPhotos()
        loadFlickrPhotos()
    }
    
    // MARK: Delegates
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoCollectionViewCell
        
        let currentPhoto = fetchedResultsController.object(at: indexPath)
        if (currentPhoto.image == nil) {
            cell.photoView.image = UIImage(systemName: "photo.artframe")
            
            FlickrClient.loadPhoto(photo: currentPhoto) { imageData, error in
                guard error == nil else {
                    return
                }
                currentPhoto.image = imageData
                try? DataController.shared.viewContext.save()
            }
        } else {
            cell.photoView.image = UIImage(data: currentPhoto.image!)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(photoToDelete)
        do {
            try DataController.shared.viewContext.save()
        } catch {
            print(error)
        }
    }
}


extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoAlbum.insertItems(at: [newIndexPath!])
            break
        case .delete:
            photoAlbum.deleteItems(at: [indexPath!])
            break
        case .update:
            photoAlbum.reloadItems(at: [indexPath!])
            break
        case .move:
            photoAlbum.moveItem(at: indexPath!, to: newIndexPath!)
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            photoAlbum.insertSections(indexSet)
            break
        case .delete:
            photoAlbum.deleteSections(indexSet)
            break
        default:
            break
        }
    }
}
