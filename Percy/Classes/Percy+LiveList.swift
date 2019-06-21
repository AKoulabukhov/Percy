//
//  Percy+Observer.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 04/05/2018.
//

import Foundation
import CoreData

extension Percy {
    public func makeLiveList<T>(predicate: NSPredicate? = nil, sorting: LiveList<T>.Sorting? = nil, filter: LiveList<T>.EntityFilter? = nil) -> LiveList<T> {
        return LiveList(context: mainContext, objectFilter: predicate, entityFilter: filter, sorting: sorting, in: self)
    }
}

public final class LiveList<T: Persistable> {
    
    public typealias Sorting = (T, T) -> Bool
    public typealias EntityFilter = (T) -> Bool
    
    public enum Change {
        case deleted(T, index: Int)
        case updated(T, oldValue: T, index: Int)
        case inserted(T, index: Int)
    }
    
    private unowned let percy: Percy
    private let objectFilter: NSPredicate?
    private let entityFilter: EntityFilter?
    private let sorting: Sorting?
    
    public private(set) var items = [T]()
    
    public var onStart: (() -> Void)?
    public var onChange: ((Change) -> Void)?
    public var onFinish: (() -> Void)?
    
    init(context: NSManagedObjectContext, objectFilter: NSPredicate?, entityFilter: EntityFilter?, sorting: Sorting?, in percy: Percy) {
        self.objectFilter = objectFilter
        self.entityFilter = entityFilter
        self.sorting = sorting
        self.percy = percy
        reloadData()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }
    
    public func reloadData() {
        let items: [T] = percy.getEntities(predicate: objectFilter, sortDescriptors: nil, fetchLimit: nil)
        let filtredItems = entityFilter.flatMap { items.filter($0) } ?? items
        self.items = sorting.flatMap { filtredItems.sorted(by: $0) } ?? filtredItems
    }
    
    @objc private func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, let userInfo = notification.userInfo else { return }
        let operationContext = OperationContext(context: context, in: percy)
        self.handleNotificationUserInfo(userInfo, operationContext: operationContext)
    }
    
    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any], operationContext: OperationContext) {
        var hasChanges: Bool = false
        
        func handleChange(_ change: Change) {
            if !hasChanges {
                hasChanges = true
                onStart?()
            }
            onChange?(change)
        }
        
        PercyChangeType.allCases.forEach { changeType in
            guard let objects = userInfo[changeType] else { return }
            
            objects.forEach {
                guard let entity = makeEntity($0, context: operationContext) else { return }
                
                if let entityFilter = self.entityFilter, !entityFilter(entity) {
                   return
                }
                
                switch changeType {
                case .deleted: handleDeletion(entity, changeHandler: handleChange)
                case .updated: handleUpdate(entity, object: $0, changeHandler: handleChange)
                case .inserted: handleInsert(entity, object: $0, changeHandler: handleChange)
                }
                
            }
            
        }
        
        if hasChanges {
            onFinish?()
        }
    }
    
    func makeEntity(_ object: NSManagedObject, context: OperationContext) -> T? {
        guard let concreteObject = object as? T.Object, let entity = try? T(object: concreteObject, in: context) else { return nil }
        return entity
    }
    

    private func handleDeletion(_ entity: T, changeHandler: (Change) -> Void) {
        if let index = items.firstIndex(where: { $0.id == entity.id }) {
            let deletedEntity = items[index]
            items.remove(at: index)
            changeHandler(.deleted(deletedEntity, index: index))
        }
    }

    private func handleUpdate(_ entity: T, object: NSManagedObject, changeHandler: (Change) -> Void) {
        guard let currentObjectIndex = items.firstIndex(where: { $0.id == entity.id }) else { return }
        
        if let isNewObjectConformsFilter = self.tryEvaluateFilters(entity: entity, object: object) {
            handleUpdateForEntity(entity, at: currentObjectIndex, isNewObjectConformsFilter: isNewObjectConformsFilter, changeHandler: changeHandler)
        } else {
            handleUpdateAtIndex(entity, index: currentObjectIndex, changeHandler: changeHandler)
        }
    }
    
    private func tryEvaluateFilters(entity: T, object: NSManagedObject) -> Bool? {
        switch (self.objectFilter, self.entityFilter) {
        case (let objectFilter?, let entityFilter?):
            return objectFilter.evaluate(with: object) && entityFilter(entity)
        case (let objectFilter?, nil):
            return objectFilter.evaluate(with: object)
        case (nil, let entityFilter?):
            return entityFilter(entity)
        case (nil, nil):
            return nil
        }
    }
    
    private func handleUpdateForEntity(_ entity: T, at currentObjectIndex: Int?, isNewObjectConformsFilter: Bool, changeHandler: (Change) -> Void) {
        switch (currentObjectIndex, isNewObjectConformsFilter) {
        case (let index?, true):
            handleUpdateAtIndex(entity, index: index, changeHandler: changeHandler)
        case (let index?, false):
            let deletedEntity = items[index]
            items.remove(at: index)
            changeHandler(.deleted(deletedEntity, index: index))
        case (nil, true):
            insertEntity(entity, changeHandler: changeHandler)
        case (nil, false):
            return
        }
    }
    
    private func handleUpdateAtIndex(_ entity: T, index: Int, changeHandler: (Change) -> Void) {
        let oldValue = items[index]
        if let sorting = self.sorting {
            items.remove(at: index)
            changeHandler(.deleted(oldValue, index: index))
            let index = indexToInsertEntity(entity, sorting: sorting)
            items.insert(entity, at: index)
            changeHandler(.inserted(entity, index: index))
        }
        else {
            items[index] = entity
            changeHandler(.updated(entity, oldValue: oldValue, index: index))
        }
    }

    private func handleInsert(_ entity: T, object: NSManagedObject, changeHandler: (Change) -> Void){
        if let isNewObjectConformsFilters = tryEvaluateFilters(entity: entity, object: object) {
            if isNewObjectConformsFilters {
                insertEntity(entity, changeHandler: changeHandler)
            }
        } else {
            insertEntity(entity, changeHandler: changeHandler)
        }
    }
    
    func insertEntity(_ entity: T, changeHandler: (Change) -> Void) {
        if let sorting = self.sorting {
            let index = indexToInsertEntity(entity, sorting: sorting)
            items.insert(entity, at: index)
            changeHandler(.inserted(entity, index: index))
        }
        else {
            items.append(entity)
            changeHandler(.inserted(entity, index: items.count))
        }
    }
    
    func indexToInsertEntity(_ entity: T, sorting: Sorting) -> Int {
        return items.firstIndex { !sorting($0, entity) } ?? items.count
    }
    
}
