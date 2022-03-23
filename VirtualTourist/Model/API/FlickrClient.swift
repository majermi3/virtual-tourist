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
    
    class func loadPhoto(photo: Photo, completion: @escaping (Data?, Error?) -> Void) {
        guard photo.server != nil, photo.id != nil, photo.secret != nil else {
            //TODO Error message
            return
        }
        
        let url = Endpoints.photo(photo: photo).url
        
        // Load image from cache
        let fileCachePath = FileManager.default.temporaryDirectory.appendingPathComponent(
            url.lastPathComponent,
            isDirectory: false
        )
        if let data = try? Data(contentsOf: fileCachePath) {
            completion(data, nil)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard error == nil, tempURL != nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            cachePhoto(tempPath: tempURL!, path: fileCachePath)
            
            if let data = try? Data(contentsOf: fileCachePath) {
                DispatchQueue.main.async {
                    completion(data, nil)
                }
            }
        }
        task.resume()
    }
    
    private class func cachePhoto(tempPath: URL, path: URL) {
        if FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.removeItem(at: path)
        }
        
        try? FileManager.default.copyItem(at: tempPath, to: path)
    }
    
    private class func setRandomPage(total: Int) {
        Search.page = Int.random(in: 1..<total)
    }
}
