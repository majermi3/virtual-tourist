//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/22/22.
//

import Foundation
import CoreLocation
import UIKit

class FlickrClient {
    
    struct Search {
        static var page = 1
    }
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        
        case search(latitude: Double, longitude: Double, page: Int = 1)
        case photo(photo: Photo)
        
        var stringValue: String {
            switch self {
            case .search(let latitude, let longitude, let page): return Endpoints.base + "?method=flickr.photos.search&api_key=\(Auth.API_KEY)&lat=\(latitude)&lon=\(longitude)&page=\(page)&per_page=10&format=json&nojsoncallback=1"
            case .photo(let photo): return "https://live.staticflickr.com/\(photo.server!)/\(photo.id!)_\(photo.secret!).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func search(pin: Pin, completion: @escaping (SearchResponse?, Error?) -> Void) {
        let url = Endpoints.search(latitude: pin.latitude, longitude: pin.longitude, page: Search.page).url
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let searchResponse = try decoder.decode(SearchResponse.self, from: data!)
                setRandomPage(total: searchResponse.photos.pages)
                DispatchQueue.main.async {
                    completion(searchResponse, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func loadPhoto(photo: Photo, completion: @escaping (UIImage?, Error?) -> Void) {
        guard photo.server != nil, photo.id != nil, photo.secret != nil else {
            //TODO Error message
            return
        }
        
        let url = Endpoints.photo(photo: photo).url
        
        // Load image from cache
        let imageCache = ImageCache.getImageCache()
        if let cacheImage = imageCache.get(forKey: url.absoluteString) {
            print("Loading image from cache: \(url.absoluteString)")
            completion(cacheImage, nil)
            return
        }
        
        
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("Loading image from Flickr: \(url.absoluteString)")
            if error != nil || data == nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            DispatchQueue.main.async {
                guard let loadedPhoto = UIImage(data: data!) else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                imageCache.set(forKey: url.absoluteString, image: loadedPhoto)
                completion(loadedPhoto, nil)
            }
        }
        task.resume()
        
    }
    
    private class func setRandomPage(total: Int) {
        Search.page = Int.random(in: 1..<total)
    }
}
