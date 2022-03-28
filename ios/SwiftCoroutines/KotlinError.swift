//
//  KotlinError.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 2/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import Foundation
import shared

class KotlinError: LocalizedError {
    let throwable: KotlinThrowable
    init(_ throwable: KotlinThrowable) {
        self.throwable = throwable
    }
    var errorDescription: String? {
        get { throwable.message }
    }
}

class SwiftThrowable: KotlinThrowable {
    let error: Error
    init (_ error: Error) {
        self.error = error
        super.init(message: error.localizedDescription)
    }
}
