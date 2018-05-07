//
//  Percy+Storages.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 27/04/2018.
//

import CoreData

extension Percy {
    
    /// Current persistent stores files
    var storageURLs: [URL] {
        let stores = coordinator.persistentStores.lazy
        let fileStoresUrl = stores.flatMap { $0.url }
            .filter { $0.isFileURL }
            .flatMap { $0.urlsWithWalFiles() }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        return Array(fileStoresUrl)
    }
    
    /// Counts total storage size for all opened persistent storages
    public var storageSize: Int64 {
        let attributes = storageURLs.lazy.flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path) }
        let sizes = attributes.flatMap { $0[.size] as? Int64 }
        return sizes.reduce(0, +)
    }
    
}
