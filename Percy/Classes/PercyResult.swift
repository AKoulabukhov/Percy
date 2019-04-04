//
//  PercyResult.swift
//
//  Created by Alexander Kulabukhov on 05/07/2018.
//

import Foundation

/// Typealias for standard result
public typealias PercyResult<T> = Result<T, Error>

/// Typealias for completion blocks
public typealias PercyResultHandler<T> = (PercyResult<T>) -> Void

extension PercyResult where Success == Void {
    static var success: PercyResult<Void> {
        return .success(())
    }
}
