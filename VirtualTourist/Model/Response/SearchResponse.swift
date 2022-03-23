//
//  SearchResponse.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/23/22.
//

import Foundation

struct SearchResponse: Codable {
    var photos: PhotoContainer
    var stat: String
}

struct PhotoContainer: Codable {
    var page: Int
    var pages: Int
    var perpage: Int
    var total: Int
    var photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    var id: String
    var owner: String
    var secret: String
    var server: String
    var title: String
}
