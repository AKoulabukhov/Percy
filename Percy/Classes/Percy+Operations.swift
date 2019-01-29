//
//  PercyInput.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 27/04/2018.
//

import CoreData

public final class OperationContext {
    
    let percy: Percy
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext, in percy: Percy) {
        self.percy = percy
        self.context = context
    }
}

extension Percy {
    
    // MARK: Sync operations
    
    public func getEntities<Model: Persistable>(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, fetchLimit: Int?) -> [Model] {
        let request = fetchRequest(for: Model.self, predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
        return self.performSync { c in try c.fetch(request).map { try Model(object: $0, in: OperationContext(context: c, in: self)) } } ?? []
    }
    
    public func count<Model: Persistable>(for object: Model.Type, predicate: NSPredicate?) -> Int {
        let request = fetchRequest(for: Model.self, predicate: predicate)
        return self.performSync { try $0.count(for: request) } ?? 0
    }
    
    public func isPersisted<Model: Persistable>(_ object: Model) -> Bool {
        let request = fetchRequest(for: Model.self, predicate: object.associatedObjectPredicate, fetchLimit: 1)
        let count = performSync { try $0.count(for: request) } ?? 0
        return count > 0
    }
    
    public func first<Model: Persistable>(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> Model? {
        return performSync { return first(predicate: predicate, sortDescriptors: sortDescriptors, in: $0) } ?? nil
    }
    
    public func create<Model: Persistable>(_ entities: [Model]) throws {
        try performWithSave { try create(entities, in: $0)}
    }
    
    public func update<Model: Persistable>(_ entities: [Model]) throws {
        try performWithSave { try update(entities, in: $0)}
    }
    
    public func upsert<Model: Persistable>(_ entities: [Model]) throws {
        try performWithSave { try upsert(entities, in: $0) }
    }
    
    public func delete<Model: Persistable>(_ entities: [Model]) throws {
        try performWithSave { try delete(entities, in: $0) }
    }
    
    public func getIdentifiers<Model: Persistable>(for type: Model.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, fetchLimit: Int?) -> [Model.IDType] {
        let request = NSFetchRequest<NSDictionary>(entityName: Model.Object.entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        fetchLimit.flatMap { request.fetchLimit = $0 }
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [Model.identifierKey]
        return self.performSync { try $0.fetch(request).compactMap { $0[Model.identifierKey] as? Model.IDType } } ?? []
    }
    
    /// Drops all objects of given entity
    public func dropEntities<Model: Persistable>(ofType type: Model.Type) throws {
        let request = fetchRequest(for: Model.self)
        request.includesPropertyValues = false
        try performWithSave { context in
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
        }
    }
    
    // MARK: Async operations
    
    public func create<Model: Persistable>(_ entities: [Model], completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.create(entities, in: $0)}, completion: completion)
    }
    
    public func update<Model: Persistable>(_ entities: [Model], completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.update(entities, in: $0)}, completion: completion)
    }
    
    public func upsert<Model: Persistable>(_ entities: [Model], completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.upsert(entities, in: $0) }, completion: completion)
    }
    
    public func delete<Model: Persistable>(_ entities: [Model], completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.delete(entities, in: $0) }, completion: completion)
    }
    
    /// Drops all objects of given entity
    public func dropEntities<Model: Persistable>(ofType type: Model.Type, completion: PercyResultHandler<Void>?) {
        let request = fetchRequest(for: Model.self)
        request.includesPropertyValues = false
        performWithSave({ context in
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
        }, completion: completion)
    }
    
    // MARK: Private methods
    
    private func fetchRequest<Model: Persistable>(for entity: Model.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil) -> NSFetchRequest<Model.Object> {
        return fetchRequest(for: Model.Object.self, predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }
    
    private func fetchRequest<Object: NSManagedObject>(for object: Object.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil) -> NSFetchRequest<Object> {
        let fetchRequest = NSFetchRequest<Object>(entityName: Object.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = fetchLimit { fetchRequest.fetchLimit = fetchLimit }
        return fetchRequest
    }
    
    func firstObject<Model: Persistable>(of objectType: Model.Type, context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> Model.Object? {
        let request = fetchRequest(for: Model.self, predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: 1)
        return (try? context.fetch(request))?.first
    }
    
}

// MARK: Internal realization with context

extension Percy {
    
    func first<Model: Persistable>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, in context: NSManagedObjectContext) -> Model? {
        return firstObject(of: Model.self, context: context, predicate: predicate, sortDescriptors: sortDescriptors)
            .flatMap {  try? Model(object: $0, in: OperationContext(context: context, in: self)) }
    }
    
    func create<Model: Persistable>(_ entities: [Model], in context: NSManagedObjectContext) throws {
        try entities.forEach { try $0.toObject(in: OperationContext(context: context, in: self)) }
    }
    
    func update<Model: Persistable>(_ entities: [Model], in context: NSManagedObjectContext) throws {
        try entities.forEach { entity in
            guard let existedObject = firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) else { return }
            try entity.fill(object: existedObject, in: OperationContext(context: context, in: self))
        }
    }
    
    func upsert<Model: Persistable>(_ entities: [Model], in context: NSManagedObjectContext) throws {
        try entities.forEach { entity in
            if let existedObject = self.firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) {
                try entity.fill(object: existedObject, in: OperationContext(context: context, in: self))
            } else {
                try entity.toObject(in: OperationContext(context: context, in: self))
            }
        }
    }
    
    func delete<Model: Persistable>(_ entities: [Model], in context: NSManagedObjectContext) throws {
        try entities.forEach { entity in
            guard let existedObject = firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) else { return }
            try entity.onDelete(object: existedObject, in: OperationContext(context: context, in: self))
            context.delete(existedObject)
        }
    }
    
}

