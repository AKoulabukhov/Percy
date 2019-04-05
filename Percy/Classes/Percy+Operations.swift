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
    
    public func getEntities<Model: Persistable>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil) -> [Model] {
        let request = fetchRequest(for: Model.self, predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
        return performSync { c in try c.fetch(request).map { try Model(object: $0, in: OperationContext(context: c, in: self)) } } ?? []
    }
    
    public func count<Model: Persistable>(for object: Model.Type, predicate: NSPredicate? = nil) -> Int {
        let request = fetchRequest(for: Model.self, predicate: predicate)
        return performSync { try $0.count(for: request) } ?? 0
    }
    
    public func isPersisted<Model: Persistable>(_ object: Model) -> Bool {
        let request = fetchRequest(for: Model.self, predicate: object.associatedObjectPredicate, fetchLimit: 1)
        let count = performSync { try $0.count(for: request) } ?? 0
        return count > 0
    }
    
    public func first<Model: Persistable>(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> Model? {
        return performSync { return first(predicate: predicate, sortDescriptors: sortDescriptors, in: $0) } ?? nil
    }
    
    public func create<Model: Persistable>(_ entity: Model) throws {
        try performWithSave { try create(entity, in: $0)}
    }
    
    public func create<Models>(_ entities: Models) throws where Models: Sequence, Models.Element: Persistable {
        try performWithSave { try create(entities, in: $0)}
    }
    
    public func update<Model: Persistable>(_ entity: Model) throws {
        try performWithSave { try update(entity, in: $0)}
    }
    
    public func update<Models>(_ entities: Models) throws where Models: Sequence, Models.Element: Persistable {
        try performWithSave { try update(entities, in: $0)}
    }
    
    public func upsert<Model: Persistable>(_ entity: Model) throws {
        try performWithSave { try upsert(entity, in: $0) }
    }
    
    public func upsert<Models>(_ entities: Models) throws where Models: Sequence, Models.Element: Persistable {
        try performWithSave { try upsert(entities, in: $0) }
    }
    
    public func delete<Model: Persistable>(_ entity: Model) throws {
        try performWithSave { try delete(entity, in: $0) }
    }
    
    public func delete<Models>(_ entities: Models) throws where Models: Sequence, Models.Element: Persistable {
        try performWithSave { try delete(entities, in: $0) }
    }
    
    /// Drops all objects of given entity (or only predicate-matching if predicate set)
    public func delete<Model: Persistable>(entitiesOfType type: Model.Type, predicate: NSPredicate?) throws {
        try performWithSave { try delete(entitiesOfType: type, predicate: predicate, in: $0) }
    }
    
    public func getIdentifiers<Model: Persistable>(for type: Model.Type, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, fetchLimit: Int?) -> [Model.IDType] {
        let request = NSFetchRequest<NSDictionary>(entityName: Model.Object.entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        fetchLimit.flatMap { request.fetchLimit = $0 }
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [Model.identifierKey]
        return performSync { try $0.fetch(request).compactMap { $0[Model.identifierKey] as? Model.IDType } } ?? []
    }
    
    // MARK: Async operations
    
    public func create<Model: Persistable>(_ entity: Model, completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.create(entity, in: $0)}, completion: completion)
    }
    
    public func create<Models>(_ entities: Models, completion: PercyResultHandler<Void>?) where Models: Sequence, Models.Element: Persistable {
        performWithSave({ try self.create(entities, in: $0)}, completion: completion)
    }
    
    public func update<Model: Persistable>(_ entity: Model, completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.update(entity, in: $0)}, completion: completion)
    }
    
    public func update<Models>(_ entities: Models, completion: PercyResultHandler<Void>?) where Models: Sequence, Models.Element: Persistable {
        performWithSave({ try self.update(entities, in: $0)}, completion: completion)
    }
    
    public func upsert<Model: Persistable>(_ entity: Model, completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.upsert(entity, in: $0) }, completion: completion)
    }
    
    public func upsert<Models>(_ entities: Models, completion: PercyResultHandler<Void>?) where Models: Sequence, Models.Element: Persistable {
        performWithSave({ try self.upsert(entities, in: $0) }, completion: completion)
    }
    
    public func delete<Model: Persistable>(_ entity: Model, completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.delete(entity, in: $0) }, completion: completion)
    }
    
    public func delete<Models>(_ entities: Models, completion: PercyResultHandler<Void>?) where Models: Sequence, Models.Element: Persistable {
        performWithSave({ try self.delete(entities, in: $0) }, completion: completion)
    }
    
    /// Drops all objects of given entity (or only predicate-matching if predicate set)
    public func delete<Model: Persistable>(entitiesOfType type: Model.Type, predicate: NSPredicate? = nil, completion: PercyResultHandler<Void>?) {
        performWithSave({ try self.delete(entitiesOfType: type, predicate: predicate, in: $0) }, completion: completion)
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
            .flatMap { try? Model(object: $0, in: OperationContext(context: context, in: self)) }
    }
    
    func create<Model: Persistable>(_ entity: Model, in context: NSManagedObjectContext) throws {
        try entity.toObject(in: OperationContext(context: context, in: self))
    }
    
    func create<Models>(_ entities: Models, in context: NSManagedObjectContext) throws where Models: Sequence, Models.Element: Persistable {
        try entities.forEach { try create($0, in: context) }
    }
    
    func update<Model: Persistable>(_ entity: Model, in context: NSManagedObjectContext) throws {
        guard let existedObject = firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) else { return }
        try entity.fill(object: existedObject, in: OperationContext(context: context, in: self))
    }
    
    func update<Models>(_ entities: Models, in context: NSManagedObjectContext) throws where Models: Sequence, Models.Element: Persistable {
        try entities.forEach { try update($0, in: context) }
    }
    
    func upsert<Model: Persistable>(_ entity: Model, in context: NSManagedObjectContext) throws {
        if let existedObject = firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) {
            try entity.fill(object: existedObject, in: OperationContext(context: context, in: self))
        } else {
            try entity.toObject(in: OperationContext(context: context, in: self))
        }
    }
    
    func upsert<Models>(_ entities: Models, in context: NSManagedObjectContext) throws where Models: Sequence, Models.Element: Persistable {
        try entities.forEach { try upsert($0, in: context) }
    }
    
    func delete<Model: Persistable>(_ entity: Model, in context: NSManagedObjectContext) throws {
        guard let existedObject = firstObject(of: Model.self, context: context, predicate: entity.associatedObjectPredicate) else { return }
        try entity.onDelete(object: existedObject, in: OperationContext(context: context, in: self))
        context.delete(existedObject)
    }
    
    func delete<Models>(_ entities: Models, in context: NSManagedObjectContext) throws where Models: Sequence, Models.Element: Persistable {
        try entities.forEach { try delete($0, in: context) }
    }
    
    func delete<Model: Persistable>(entitiesOfType type: Model.Type, predicate: NSPredicate? = nil, in context: NSManagedObjectContext) throws {
        let request = fetchRequest(for: Model.self)
        request.predicate = predicate
        request.includesPropertyValues = false
        try context.fetch(request).forEach {
            context.delete($0)
        }
    }
    
}

