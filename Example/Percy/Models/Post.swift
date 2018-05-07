//
//  Post.swift
//  Percy_Example
//
//  Created by Alexander Kulabukhov on 29/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Percy

struct Post {
    let id: Int
    var text: String
}

extension Post: Persistable {
    
    init(object: PostObject, in context: OperationContext) throws {
        id = Int(object.id)
        text = object.text!
    }
    
    func fill(object: PostObject, in context: OperationContext) throws {
        object.id = Int32(id)
        object.text = text
    }
    
}
