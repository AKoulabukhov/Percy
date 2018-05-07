//
//  Percy+Extensions.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 28/04/2018.
//

import CoreData

extension NSManagedObjectContext {
    
    func performThrowsAndWait(_ task: () throws -> Void) throws {
        var performError: Error?
        performAndWait {
            do { try task() }
            catch { performError = error }
        }
        if let error = performError { throw error }
    }
}

extension NSManagedObject {
    
    class var entityName: String { return String(describing: self) }
}

extension NSPersistentStoreCoordinator {
    
    @discardableResult
    func addPersistentStore(description: StoreDescription) throws -> NSPersistentStore {
        return try addPersistentStore(ofType: description.type,
                                     configurationName: description.configurationName,
                                     at: description.url,
                                     options: description.options)
    }
}

extension Bundle {
    
    var displayName: String {
        return object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? ""
    }
}

extension String {
    
    func preparedToFileName() -> String {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
}

extension URL {
    
    /// Additional file suffixes when SQLite store work in WAL mode
    private static let walModeFileSuffixes = ["-wal", "-shm"]
    
    func urlsWithWalFiles() -> [URL] {
        return [self] + URL.walModeFileSuffixes.map { self.appending($0) }
    }
    
    func appending(_ string: String) -> URL {
        var lastComponent = self.lastPathComponent
        lastComponent.append(string)
        return self.deletingLastPathComponent().appendingPathComponent(lastComponent)
    }
    
}
