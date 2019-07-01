//
//  Percy+ChangeObserver.swift
//  Percy
//
//  Created by a.kulabukhov on 29/01/2019.
//

import CoreData

extension Percy {
    public func makeObserver<T>(filter: Percy.Filter<T>? = nil) -> ChangeObserver<T> {
        return ChangeObserver(context: mainContext, filter: filter, in: self)
    }
}

public final class ChangeObserver<T: Persistable> {
    
    public enum Change {
        case deleted(T)
        case updated(T)
        case inserted(T)
    }
    
    private unowned let percy: Percy
    private let filter: Percy.Filter<T>?
    private var identifiers = Set<T.IDType>()
    
    public var onChanges: (([Change]) -> Void)?
    
    init(context: NSManagedObjectContext, filter: Percy.Filter<T>?, in percy: Percy) {
        self.filter = filter
        self.percy = percy
        reloadIdentifiers()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }
    
    public func reloadIdentifiers() {
        if let filterBlock = filter?.block {
            // Think about different filter joiners
        }
        else {
            self.identifiers = Set(percy.getIdentifiers(for: T.self, predicate: filter?.predicate, sortDescriptors: nil, fetchLimit: nil))
        }
    }
    
    @objc private func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, let userInfo = notification.userInfo else { return }
        let operationContext = OperationContext(context: context, in: percy)
        self.handleNotificationUserInfo(userInfo, operationContext: operationContext)
    }
    
    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any], operationContext: OperationContext) {
        var changes = [Change]()
        
        let handleChange: (Change) -> Void = { changes.append($0) }
        
        PercyChangeType.allCases.forEach { changeType in
            guard let objects = userInfo[changeType] else { return }
            
            objects.forEach {
                guard let entity = makeEntity($0, context: operationContext) else { return }
                
                switch changeType {
                case .deleted: handleDeletion(entity, changeHandler: handleChange)
                case .updated: handleUpdate(entity, object: $0, changeHandler: handleChange)
                case .inserted: handleInsert(entity, object: $0, changeHandler: handleChange)
                }
                
            }
            
        }
        
        if !changes.isEmpty {
            onChanges?(changes)
        }
    }
    
    func makeEntity(_ object: NSManagedObject, context: OperationContext) -> T? {
        guard let concreteObject = object as? T.Object, let entity = try? T(object: concreteObject, in: context) else { return nil }
        return entity
    }
    
    
    private func handleDeletion(_ entity: T, changeHandler: (Change) -> Void) {
        if identifiers.contains(entity.id) {
            identifiers.remove(entity.id)
            changeHandler(.deleted(entity))
        }
    }
    
    private func handleUpdate(_ entity: T, object: NSManagedObject, changeHandler: (Change) -> Void) {
        if let filter = self.filter {
            let currentObjectExists = identifiers.contains(entity.id)
            let newObjectExists = filter.evaluate(with: object)
            switch (currentObjectExists, newObjectExists) {
            case (true, true):
                changeHandler(.updated(entity))
            case (true, false):
                identifiers.remove(entity.id)
                changeHandler(.deleted(entity))
            case (false, true):
                identifiers.insert(entity.id)
                changeHandler(.inserted(entity))
            case (false, false):
                break
            }
        }
        else {
            changeHandler(.updated(entity))
        }
    }
    
    private func handleInsert(_ entity: T, object: NSManagedObject, changeHandler: (Change) -> Void){
        if let filter = self.filter {
            if filter.evaluate(with: object) {
                identifiers.insert(entity.id)
                changeHandler(.inserted(entity))
            }
        }
        else {
            identifiers.insert(entity.id)
            changeHandler(.inserted(entity))
        }
    }
    
}
