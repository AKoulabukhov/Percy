//
//  Percy+RemoteStoreMerger.swift
//  Percy
//
//  Created by a.kulabukhov on 17/05/2019.
//

import Foundation
import CoreData

extension Percy {
    
    /**
     
     Make new remote store merger.
     It can help you merge changes in different instances of `Percy`, for example when `Application` and N`SExtension` share the same database.
     Use `onBatchFormed` block to store changes data somewhere, then use `mergeBatch(_:)` on another `Percy` instance to append changes.
     
    */
    
    public func makeRemoteStoreMerger() -> RemoteStoreMerger {
        return RemoteStoreMerger(self)
    }
    
    public final class RemoteStoreMerger {
        
        public struct Batch {
            fileprivate let uriNotificationData: [[AnyHashable: Any]]
        }
        
        unowned let percy: Percy
        private var changeUserInfos = [[AnyHashable: Any]]()
        
        public var onBatchFormed: ((Batch) -> Void)?
        
        init(_ percy: Percy) {
            self.percy = percy
            // Observe private context as changes are actually in database only when it saved
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(managedObjectContextObjectsDidChange),
                                                   name: .NSManagedObjectContextObjectsDidChange,
                                                   object: percy.privateContext)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(managedObjectContextDidSave),
                                                   name: .NSManagedObjectContextObjectsDidChange,
                                                   object: percy.privateContext)
        }
        
        @objc private func managedObjectContextObjectsDidChange(notification: Notification) {
            guard let userInfo = notification.userInfo else { return }
            changeUserInfos.append(userInfo)
        }
        
        @objc private func managedObjectContextDidSave(notification: Notification) {
            let uriNotificationData = self.changeUserInfos.map { $0.makeUriNotificationData(context: self.percy.privateContext) }
            // Escape context's queue
            DispatchQueue.global(qos: .utility).async {
                self.onBatchFormed?(.init(uriNotificationData: uriNotificationData))
            }
        }
        
        public func mergeBatch(_ batch: Batch) {
            batch.uriNotificationData.forEach {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: $0, into: [percy.privateContext, percy.mainContext])
            }
        }
        
    }
    
}

extension Percy.RemoteStoreMerger.Batch: RawRepresentable {
    
    public init?(rawValue: Data) {
        guard let uriNotificationData = NSKeyedUnarchiver.unarchiveObject(with: rawValue) as? [[AnyHashable: Any]] else { return nil }
        self.init(uriNotificationData: uriNotificationData)
    }
    
    public var rawValue: Data {
        return NSKeyedArchiver.archivedData(withRootObject: self.uriNotificationData)
    }
    
}

fileprivate extension Dictionary where Key == AnyHashable, Value == Any {
    
    func makeUriNotificationData(context: NSManagedObjectContext) -> [AnyHashable: Any] {
        var uriNotificationData = [AnyHashable: Any]()
        
        for (changeType, value) in self {
            guard let objects = value as? Set<NSManagedObject> else { continue }
            let temporaryObjects: [NSManagedObject] = objects.filter { $0.objectID.isTemporaryID }
            try? context.obtainPermanentIDs(for: temporaryObjects)
            let uris: [URL] = objects.map {
                assert(!$0.objectID.isTemporaryID, "Attempt to archive temporary ID")
                return $0.objectID.uriRepresentation()
            }
            uriNotificationData[changeType] = uris
        }
        
        return uriNotificationData
    }
    
}
