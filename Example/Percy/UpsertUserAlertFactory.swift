//
//  UpsertUserAlertFactory.swift
//  Percy_Example
//
//  Created by Alexander Kulabukhov on 29/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

enum UpsertUserAlertFactory {
    
    typealias UserAction = (User) -> Void
    
    static func makeAlert(user: User?,
                          onCreate: @escaping UserAction,
                          onUpdate: @escaping UserAction,
                          onDelete: @escaping UserAction,
                          onAddAvatar: @escaping UserAction,
                          onRemoveAvatar: @escaping UserAction) -> UIAlertController {
        
        let alert = UIAlertController(title: user == nil ? "Create new user" : "Update user",
                                      message: "Input new user info",
                                      preferredStyle: .alert)
        
        alert.addTextField {
            $0.placeholder = "ID"
            $0.text = user?.id ?? .randomId()
            $0.isEnabled = user == nil
        }
        alert.addTextField {
            $0.text = user?.email ?? .randomEmail()
            $0.placeholder = "Email: example@mail.com"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [unowned alert] _ in
            let email = alert.textFields![1].text!
            if var user = user {
                user.email = email
                onUpdate(user)
            }
            else {
                let id = alert.textFields![0].text!
                onCreate(User(id: id, email: email))
            }
        })
        
        if let user = user {
            if user.avatar == nil {
                alert.addAction(UIAlertAction(title: "Set avatar", style: .default) { _ in onAddAvatar(user) })
            }
            else {
                alert.addAction(UIAlertAction(title: "Remove avatar", style: .destructive) { _ in onRemoveAvatar(user) })
            }
            alert.addAction(UIAlertAction(title: "Delete user", style: .destructive) { _ in onDelete(user) })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        return alert
    }
    
}
