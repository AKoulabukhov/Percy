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
        return LiveList(context: mainContext, predicate: predicate, filter: filter, sorting: sorting, in: self)
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
    private let predicate: NSPredicate?
    private let filter: EntityFilter?
    private let sorting: Sorting?
    
    public private(set) var items = [T]()
    
    public var onStart: (() -> Void)?
    public var onChange: ((Change) -> Void)?
    public var onFinish: (() -> Void)?
    
    init(context: NSManagedObjectContext, predicate: NSPredicate?, filter: EntityFilter?, sorting: Sorting?, in percy: Percy) {
        self.predicate = predicate
        self.filter = filter
        self.sorting = sorting
        self.percy = percy
        reloadData()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }
    
    public func reloadData() {
        let items: [T] = percy.getEntities(predicate: predicate, sortDescriptors: nil, fetchLimit: nil)
        let filteredItems = filter.flatMap { items.filter($0) } ?? items
        self.items = sorting.flatMap { filteredItems.sorted(by: $0) } ?? filteredItems
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
        let currentObjectIndex = items.firstIndex(where: { $0.id == entity.id })
        
        if let isNewObjectConformsFilter = self.tryEvaluateFilters(entity: entity, object: object) {
            handleUpdateForEntity(entity, at: currentObjectIndex, isNewObjectConformsFilter: isNewObjectConformsFilter, changeHandler: changeHandler)
        } else {
            guard let index = currentObjectIndex else { return }
            handleUpdateAtIndex(entity, index: index, changeHandler: changeHandler)
        }
    }
    
    private func tryEvaluateFilters(entity: T, object: NSManagedObject) -> Bool? {
        switch (self.predicate, self.filter) {
        case (let predicate?, let filter?):
            return predicate.evaluate(with: object) && filter(entity)
        case (let predicate?, nil):
            return predicate.evaluate(with: object)
        case (nil, let filter?):
            return filter(entity)
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
