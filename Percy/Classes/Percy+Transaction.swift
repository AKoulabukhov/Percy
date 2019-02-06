//
//  Percy+Transaction.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 12/05/2018.
//

import CoreData

extension Percy {
    public func beginTransaction() -> Transaction {
        return Transaction(percy: self)
    }
}

public final class Transaction {
    
    typealias Operation = ((NSManagedObjectContext) throws -> Void)
    
    private unowned let percy: Percy
    private var operations = [Operation]()
    
    init(percy: Percy) {
        self.percy = percy
    }
    
    public func create<Model: Persistable>(entity: Model) {
        self.operations.append { [unowned percy] in try percy.create(entity, in: $0) }
    }
    
    public func create<Models>(entities: Models) where Models: Sequence, Models.Element: Persistable {
        self.operations.append { [unowned percy] in try percy.create(entities, in: $0) }
    }
    
    public func update<Model: Persistable>(entity: Model...) {
        self.operations.append { [unowned percy] in try percy.update(entity, in: $0) }
    }
    
    public func update<Models>(entities: Models) where Models: Sequence, Models.Element: Persistable {
        self.operations.append { [unowned percy] in try percy.update(entities, in: $0) }
    }
    
    public func upsert<Model: Persistable>(entity: Model) {
        self.operations.append { [unowned percy] in try percy.upsert(entity, in: $0) }
    }
    
    public func upsert<Models>(entities: Models) where Models: Sequence, Models.Element: Persistable {
        self.operations.append { [unowned percy] in try percy.upsert(entities, in: $0) }
    }
    
    public func delete<Model: Persistable>(entity: Model) {
        self.operations.append { [unowned percy] in try percy.delete(entity, in: $0) }
    }
    
    public func delete<Models>(entities: Models) where Models: Sequence, Models.Element: Persistable {
        self.operations.append { [unowned percy] in try percy.delete(entities, in: $0) }
    }
    
    public func commit() throws {
        try percy.performWithSave { context in
            try operations.forEach { try $0(context) }
        }
    }
    
    public func commit(completion: PercyResultHandler<Void>?) {
        percy.performWithSave({ [operations] context in
            try operations.forEach { try $0(context) }
        }, completion: completion)
    }
    
}
