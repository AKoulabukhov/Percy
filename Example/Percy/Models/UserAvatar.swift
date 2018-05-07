//
//  UserAvatar.swift
//  Percy_Example
//
//  Created by Alexander Kulabukhov on 09/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Percy

struct UserAvatar {
    let data: Data
    let user_id: String
}

extension UserAvatar: Persistable {
    static var identifierKey: String { return "user_id" }
    
    var id: String { return user_id }
    
    init(object: UserAvatarObject, in context: OperationContext) throws {
        data = object.data!
        user_id = object.user_id!
    }
    
    func fill(object: UserAvatarObject, in context: OperationContext) throws {
        object.data = data
        object.user_id = user_id
    }
}
