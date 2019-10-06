//
//  PercyChangeType.swift
//  Percy
//
//  Created by a.kulabukhov on 29/01/2019.
//

import CoreData

enum PercyChangeType: CaseIterable {
    case deleted, updated, inserted
    
    var coreDataKey: String {
        switch self {
        case .inserted: return NSInsertedObjectsKey
        case .updated: return NSUpdatedObjectsKey
        case .deleted: return NSDeletedObjectsKey
        }
    }
}

extension Dictionary where Key == AnyHashable {
    subscript (key: PercyChangeType) -> Set<NSManagedObject>? {
        guard let result = self[key.coreDataKey] as? Set<NSManagedObject>, !result.isEmpty else { return nil }
        return result
    }
}
