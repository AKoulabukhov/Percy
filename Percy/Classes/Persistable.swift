//
//  Persistable.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 26/04/2018.
//

import CoreData

/// Protocol hiding entity identifier type
public protocol Identifier: CVarArg { }
extension Int: Identifier { }
extension String: Identifier { }

public protocol Persistable {
    
    /// Type of associated NSManagedObject
    associatedtype Object: NSManagedObject
    
    /// Type of identifier used in entity
    associatedtype IDType: Identifier
    
    /// Entity identifier, used to associate with persisted object
    var id: IDType { get }
    
    /// Getter for property name that contains id in database object. Default is "id"
    static var identifierKey: String { get }
    
    /// Init for your persistable entity from NSManagedObject
    init(object: Object, in context: OperationContext) throws
    
    /// Updates NSManagedObject from persistable entity
    func fill(object: Object, in context: OperationContext) throws
    
    /// Called right after NSManagedObject was deleted, use this to remove associated entities or files
    func onDelete(object: Object, in context: OperationContext) throws
    
}

/// Default public realization
public extension Persistable {
    
    static var identifierKey: String { return "id" }
    
    func onDelete(object: Object, in context: OperationContext) throws { }
}

/// Default internal realization
extension Persistable {
    
    /// Method creates new NSManagedObject from persistable entity. Default realization creates empty Object and performs `fill`.
    @discardableResult
    func toObject(in operationContext: OperationContext) throws -> Object {
        let entity = NSEntityDescription.entity(forEntityName: Object.entityName, in: operationContext.context)!
        let object = NSManagedObject(entity: entity, insertInto: operationContext.context) as! Object
        try self.fill(object: object, in: operationContext)
        return object
    }
    
    /// Returns predicate to find an associated object in database
    var associatedObjectPredicate: NSPredicate {
        return NSPredicate(format: "%K == %@", Self.identifierKey, self.id)
    }
    
}
