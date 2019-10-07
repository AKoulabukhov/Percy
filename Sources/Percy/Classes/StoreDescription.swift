//
//  StoreDescription.swift
//  Percy
//
//  Created by Alexander Kulabukhov on 17/06/2018.
//

import Foundation

public struct StoreDescription {
    
    public let type: String
    public let configurationName: String?
    public let url: URL?
    public let options: [AnyHashable: Any]?
    
    public init(type: String, configurationName: String?, url: URL?, options: [AnyHashable: Any]?) {
        self.type = type
        self.configurationName = configurationName
        self.url = url
        self.options = options
    }
    
}
