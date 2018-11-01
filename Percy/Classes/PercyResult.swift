//
//  PercyResult.swift
//
//  Created by Alexander Kulabukhov on 05/07/2018.
//

import Foundation

/// Typealias for completion blocks
public typealias PercyResultHandler<T> = (PercyResult<T>) -> Void

/// If your project has own `Result` type, yout can make an extension to convert it
public enum PercyResult<T> {
    case success(T)
    case failure(Error)
}

extension PercyResult where T == Void {
    static var success: PercyResult<Void> {
        return .success(())
    }
}
