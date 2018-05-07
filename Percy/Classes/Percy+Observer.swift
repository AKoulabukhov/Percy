//
//  Percy+Observer.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 04/05/2018.
//

import Foundation
import CoreData

public enum ObserverChangeType {
    case inserted, updated, deleted
}

extension ObserverChangeType {
    var coreDataKey: String {
        switch self {
        case .inserted: return NSInsertedObjectsKey
        case .updated: return NSUpdatedObjectsKey
        case .deleted: return NSDeletedObjectsKey
        }
    }
}

public typealias EntityFilter<T> = (T) -> Bool
public typealias EntitiesChangeHandler<T> = ([T], ObserverChangeType) -> Void

extension Percy {
    public func observe<T>() -> Observer<T> {
        return Observer(context: mainContext, in: self)
    }
}

public final class Observer<T: Persistable> {
    
    private unowned let percy: Percy
    
    public var filter: EntityFilter<T>?
    public var onStart: (() -> Void)?
    public var onChange: EntitiesChangeHandler<T>?
    public var onFinish: (() -> Void)?
    
    init(context: NSManagedObjectContext, in percy: Percy) {
        self.percy = percy
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextObjectsDidChange),
                                               name: .NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }
    
    @objc private func managedObjectContextObjectsDidChange(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, let userInfo = notification.userInfo else { return }
        let operationContext = OperationContext(context: context, in: percy)
        
        let changeTypes: [ObserverChangeType] = [.inserted, .updated, .deleted]
        let changes: [(entities: [T], changeType: ObserverChangeType)] = changeTypes.compactMap {
            let entities = getEntities(from: userInfo[$0.coreDataKey], context: operationContext)
            guard !entities.isEmpty else { return nil }
            return (entities, $0)
        }
        
        guard !changes.isEmpty else { return }
        
        onStart?()
        changes.forEach { onChange?($0.entities, $0.changeType) }
        onFinish?()
    }
    
    private func getEntities(from object: Any?, context: OperationContext) -> [T] {
        guard let objects = object as? Set<NSManagedObject> else { return [] }
        return objects.compactMap {
            guard let concreteObject = $0 as? T.Object, let entity = try? T(object: concreteObject, in: context) else { return nil }
            guard let filter = self.filter else { return entity }
            return filter(entity) ? entity : nil
        }
    }
    
}
