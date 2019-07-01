//
//  Percy+Filter.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 27/06/2019.
//

import Foundation
import CoreData

public extension Percy {
    
    struct Filter<T: Persistable> {
        let predicate: NSPredicate?
        let block: ((T) -> Bool)?
        let joiner: ((Bool, Bool) -> Bool)?
        
        public init(predicate: NSPredicate? = nil, block: ((T) -> Bool)? = nil, joiner: ((Bool, Bool) -> Bool)? = nil) {
            assert(predicate != nil || block != nil, "At least one filtering argument should be passed")
            self.predicate = predicate
            self.block = block
            self.joiner = joiner ?? ((predicate != nil && block != nil) ? { $0 && $1 } : nil)
        }
        
    }
    
}

public extension Percy.Filter {
    
    func evaluate(object: NSManagedObject, entity: T) -> Bool {
        switch (predicate, block) {
        case (let predicate?, let block?):
            let joiner = self.joiner ?? { $0 && $1 }
            return joiner(predicate.evaluate(with: object), block(entity))
        case (let predicate?, nil):
            return predicate.evaluate(with: object)
        case (nil, let block?):
            return block(entity)
        case (nil, nil):
            return true
        }
    }
    
}
