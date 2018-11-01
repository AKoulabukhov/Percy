//
//  AlertController.swift
//  Percy_Example
//
//  Created by Alexander Kulabukhov on 24/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class AlertController: UIAlertController {
    
    private weak var window: UIWindow?
    
    static func alert(title: String, message: String, cancelButtonTitle: String = "OK") -> AlertController {
        let controller = AlertController.init(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel))
        return controller
    }
    
    func show(animated: Bool = true) {
        let presentingViewController = UIViewController()
        presentingViewController.view.backgroundColor = .clear
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presentingViewController
        window.backgroundColor = .clear
        window.windowLevel = UIWindow.Level.alert + 1
        window.makeKeyAndVisible()
        self.window = window
        
        presentingViewController.present(self, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        window?.isHidden = true
    }
    
}
