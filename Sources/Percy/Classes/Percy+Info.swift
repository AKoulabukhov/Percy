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
        let fileStoresUrl = coordinator.persistentStores.lazy
            .compactMap { $0.url }
            .filter { $0.isFileURL }
            .flatMap { $0.urlsWithWalFiles() }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        return Array(fileStoresUrl)
    }
    
    /// Counts total storage size for all opened persistent storages
    public var storageSize: Int64 {
        return storageURLs.lazy
            .compactMap { try? FileManager.default.attributesOfItem(atPath: $0.path) }
            .compactMap { $0[.size] as? Int64 }
            .reduce(0, +)
    }
    
}
