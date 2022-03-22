//
//  DataController.swift
//  VirtualTourist
//
//  Created by Michal Majernik on 3/22/22.
//

import Foundation
import CoreData

class DataController {
    
    static let shared: DataController = {
        let instance = DataController()
        instance.load()
        return instance
    }()
    
    let modelName = "VirtualTourist"
    
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
