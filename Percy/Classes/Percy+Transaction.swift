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
    
    public func create<Model: Persistable>(entities: [Model]) {
        self.operations.append { [unowned percy] context in
            try percy.create(entities, in: context)
        }
    }
    
    public func update<Model: Persistable>(entities: [Model]) {
        self.operations.append { [unowned percy] context in
            try percy.update(entities, in: context)
        }
    }
    
    public func upsert<Model: Persistable>(entities: [Model]) {
        self.operations.append { [unowned percy] context in
            try percy.upsert(entities, in: context)
        }
    }
    
    public func delete<Model: Persistable>(entities: [Model]) {
        self.operations.append { [unowned percy] context in
            try percy.delete(entities, in: context)
        }
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
