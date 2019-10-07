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
    
    /**
     
     Initialize a new store
     
     - throws:
     Error of type `PercyError`
     
     - parameters:
     - dataModelName: Name of the CoreData model WITHOUT `.momd` extension
     - bundle: Bundle which contains dataModel, `.main` by default
     - useDefaultStore: Defaults `true`, if `false` - you take responsibility to manually open and close custom store (e.g. EncryptedCoreData)
     
     An error can be thrown if there is no dataModel was found in your Bundle
     
    */
    
    public init(dataModelName: String, bundle: Bundle = .main, useDefaultStore: Bool = true) throws {
        guard let modelURL = bundle.url(forResource: dataModelName, withExtension: Const.dataModelExtension) else { throw PercyError.modelNotFound }
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
