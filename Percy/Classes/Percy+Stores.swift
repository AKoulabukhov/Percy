//
//  Percy+DefaultStore.swift
//
//  Created by Alexander Kulabukhov on 28/04/2018.
//

import CoreData

public struct StoreDescription {
    public let type: String
    public let configurationName: String?
    public let url: URL?
    public let options: [AnyHashable: Any]?
}

extension Percy {
    
    private var defaultStoreDescription: StoreDescription {
        return StoreDescription(type: NSSQLiteStoreType, configurationName: nil, url: databaseUrl,
                                options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                          NSInferMappingModelAutomaticallyOption: true])
    }
    
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    private var databaseUrl: URL {
        return documentsDirectory.appendingPathComponent(Const.defaultDatabaseName)
    }
    
    public func resetDefaultStore() throws {
        let description = defaultStoreDescription
        try defaultStore.flatMap { try closeStore($0) }
        try description.url.flatMap { try removeStore(at: $0) }
        try openStore(description)
    }
    
    func openDefaultStore() throws {
        defaultStore = try openStore(defaultStoreDescription)
    }
    
    // MARK: Custom stores support, e.g. EncryptedCoreData
    
    public func isStoreOpen(_ persistentStore: NSPersistentStore) -> Bool {
        return coordinator.persistentStores.contains(persistentStore)
    }
    
    @discardableResult
    public func openStore(_ description: StoreDescription) throws -> NSPersistentStore {
        return try coordinator.addPersistentStore(description: description)
    }
    
    public func closeStore(_ persistentStore: NSPersistentStore) throws {
        guard isStoreOpen(persistentStore) else { return }
        try coordinator.remove(persistentStore)
    }
    
    public func removeStore(at url: URL) throws {
        let storeFilesUrls = url.urlsWithWalFiles().filter { FileManager.default.fileExists(atPath: $0.path) }
        try storeFilesUrls.forEach { try FileManager.default.removeItem(at: $0) }
    }
    
}
