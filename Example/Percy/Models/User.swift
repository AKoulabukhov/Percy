//
//  User.swift
//  Percy_Example
//
//  Created by Alexander Kulabukhov on 28/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Percy

struct User {
    let id: String
    var email: String
    private let avatarSubentity: Subentity<UserAvatar>
}

extension User {
    
    init(id: String, email: String) {
        self.init(id: id, email: email, avatarSubentity: Subentity<UserAvatar>(id: id))
    }
    
    /// Proxy property to underlying subentity, can be slow to fetch
    var avatar: Data? {
        get { return avatarSubentity.value?.data }
        set { avatarSubentity.value = newValue.flatMap { UserAvatar(data: $0, user_id: id) } }
    }
    
}

extension User: Persistable {
    
    init(object: UserObject, in context: OperationContext) throws {
        id = object.id!
        email = object.email!
        avatarSubentity = Subentity<UserAvatar>(id: object.id!, context: context)
    }
    
    func fill(object: UserObject, in context: OperationContext) throws {
        object.id = id
        object.email = email
        try avatarSubentity.save(in: context)
    }
    
    func onDelete(object: UserObject, in context: OperationContext) throws {
        try avatarSubentity.delete(in: context)
    }
    
}
