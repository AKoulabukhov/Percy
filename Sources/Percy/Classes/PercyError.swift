//
//  PercyError.swift
//
//  Created by Alexander Kulabukhov on 26/04/2018.
//

import Foundation

public enum PercyError: Error {
    case modelNotFound
    case modelBadFormat
    case closedStorage
}
