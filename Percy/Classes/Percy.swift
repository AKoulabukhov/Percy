//
//  Percy.swift
//
//  Created by Alexander Kulabukhov on 26/04/2018.
//

import CoreData

public final class Percy {
    
    enum Const {
        static let dataModelExtension = "momd"
        static let defaultDatabaseName = "\(Bundle.main.displayName.preparedToFileName()).sqlite"
    }
    
    public init(dataModelName: String, useDefaultStore: Bool = true) throws {
        guard let modelURL = Bundle.main.url(forResource: dataModelName, withExtension: Const.dataModelExtension) else { throw PercyError.modelNotFound }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else { throw PercyError.modelBadFormat }
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        if useDefaultStore { try openDefaultStore() }
    }
    
    // MARK: - Core Data Stack
    
    weak var defaultStore: NSPersistentStore?
    
    let coordinator: NSPersistentStoreCoordinator
    
    lazy var privateContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        context.mergePolicy = NSOverwriteMergePolicy
        return context
    }()
    
    lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = self.privateContext
        context.mergePolicy = NSOverwriteMergePolicy
        return context
    }()
    
}
