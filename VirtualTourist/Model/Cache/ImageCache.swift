//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/23/22.
//

import Foundation
import UIKit

class ImageCache {
    private static var imageCache = ImageCache()
    
    var cache = NSCache<NSString, UIImage>()
    
    static func getImageCache() -> ImageCache {
        return imageCache
    }
    
    func get(forKey: String) -> UIImage? {
        return cache.object(forKey: NSString(string: forKey))
    }
    
    func set(forKey: String, image: UIImage) {
        cache.setObject(image, forKey: NSString(string: forKey))
    }
}
