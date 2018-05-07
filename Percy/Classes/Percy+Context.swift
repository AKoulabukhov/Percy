//
//  Percy+Context.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 28/04/2018.
//

import CoreData

extension Percy {
    
    // MARK: - Context
    
    func makeTemporaryContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.mainContext
        context.mergePolicy = NSOverwriteMergePolicy
        return context
    }
    
    func performSync<T>(execute block: (NSManagedObjectContext) throws -> T) -> T? {
        if Thread.isMainThread {
            return try? block(self.mainContext)
        } else {
            var result: T?
            let context = self.makeTemporaryContext()
            context.performAndWait { result = try? block(context) }
            return result
        }
    }
    
    func performWithSave(_ changesBlock: (NSManagedObjectContext) throws -> Void) throws {
        guard !coordinator.persistentStores.isEmpty else { throw PercyError.closedStorage }
        if Thread.isMainThread {
            try changesBlock(self.mainContext)
            try saveMainContext()
        } else {
            let context = self.makeTemporaryContext()
            try context.performThrowsAndWait {
                try changesBlock(context)
                try saveTemporaryContext(context)
            }
        }
    }
    
    // MARK: - Private
    
    private func saveTemporaryContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
        try saveMainContextSync()
    }
    
    private func saveMainContext() throws {
        guard mainContext.hasChanges else { return }
        do { try mainContext.save() }
        catch { mainContext.rollback(); throw error }
        savePrivateContext()
    }
    
    private func saveMainContextSync() throws {
        guard mainContext.hasChanges else { return }
        try mainContext.performThrowsAndWait {
            try saveMainContext()
        }
    }
    
    private func savePrivateContext() {
        guard privateContext.hasChanges else { return }
        privateContext.perform { [context = privateContext] in
            try? context.save()
        }
    }
    
}
