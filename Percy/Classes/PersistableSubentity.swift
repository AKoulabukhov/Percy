//
//  PersistableSubentity.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 12/06/2018.
//

import CoreData

/// Subentity is entity connected (0/1)-to-1 to parent by id
public final class Subentity<SubentityType: Persistable> {
    
    private static func makeSubentityPredicate(id: SubentityType.IDType) -> NSPredicate {
        return NSPredicate(format: "%K == %@", SubentityType.identifierKey, id)
    }
    
    private var subentity: SubentityType?
    private var subentityFetcher: (() -> SubentityType?)?
    
    private let id: SubentityType.IDType
    private var isInitializedWithValue: Bool
    private var isValueModified: Bool = false
    
    public var value: SubentityType? {
        get {
            if self.subentity == nil, let fetcher = self.subentityFetcher {
                self.subentityFetcher = nil
                self.subentity = fetcher()
            }
            return self.subentity
        }
        set {
            subentity = newValue
            subentityFetcher = nil
            isValueModified = true
        }
    }
    
    /// Init a new empty child when initializing a parent
    public init(id: SubentityType.IDType) {
        self.id = id
        self.isInitializedWithValue = true
    }
    
    /// Init a new non-empty child when initializing a parent
    public init(_ subentity: SubentityType) {
        self.subentity = subentity
        self.id = subentity.id
        self.isInitializedWithValue = true
    }
    
    /// Init with predicate to lazily fetch child on first access
    public init(id: SubentityType.IDType, context: OperationContext) {
        self.id = id
        let predicate = Subentity<SubentityType>.makeSubentityPredicate(id: id)
        self.subentityFetcher = { return context.percy.first(predicate: predicate, sortDescriptors: nil) }
        self.isInitializedWithValue = false
    }
    
    public func save(in operation: OperationContext) throws {
        guard needsSave else { return }
        
        let predicate = Subentity<SubentityType>.makeSubentityPredicate(id: id)
        let oldValue: SubentityType? = operation.percy.first(predicate: predicate, in: operation.context)
        let newValue = value

        switch (oldValue, newValue) {
        case (_?, let new?): try operation.percy.update([new], in: operation.context)
        case (let current?, nil): try operation.percy.delete([current], in: operation.context)
        case (nil, let new?): try operation.percy.create([new], in: operation.context)
        case (nil, nil): break
        }
        
    }
    
    /// Flag that helps optimize saving process
    private var needsSave: Bool {
        // We can't know if that value already saved so just save
        if isInitializedWithValue { return true }
        
        // If child fetcher is alive - child wasn't accessed and there is no reason to update it
        if subentityFetcher != nil { return false }
        else {
            // If child is a class - any property can be updated without setting new value
            let isUpdated = (SubentityType.self is AnyClass) || isValueModified
            if !isUpdated { return false }
        }
        return true
    }
    
    public func delete(in operation: OperationContext) throws {
        let predicate = Subentity<SubentityType>.makeSubentityPredicate(id: id)
        guard let value: SubentityType = operation.percy.first(predicate: predicate, in: operation.context) else { return }
        try operation.percy.delete([value], in: operation.context)
    }
    
}
