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
        static var limit = 20
    }
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        
        case search(latitude: Double, longitude: Double, page: Int = 1)
        case photo(photo: Photo)
        
        var stringValue: String {
            switch self {
            case .search(let latitude, let longitude, let page): return Endpoints.base + "?method=flickr.photos.search&api_key=\(Auth.API_KEY)&lat=\(latitude)&lon=\(longitude)&page=\(page)&per_page=\(Search.limit)&format=json&nojsoncallback=1"
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
        
        print(url.absoluteString)
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
        let url = Endpoints.photo(photo: photo).url
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard error == nil, tempURL != nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            if let data = try? Data(contentsOf: tempURL!) {
                DispatchQueue.main.async {
                    completion(data, nil)
                }
            }
        }
        task.resume()
    }
    
    private class func setRandomPage(total: Int) {
        Search.page = Int.random(in: 1..<total)
    }
}
