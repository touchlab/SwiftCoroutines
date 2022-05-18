//
//  ThingRepositoryAsync.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 10/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import shared
import Foundation

class ThingRepositoryAsync {
    private let delegate: ThingRepositoryIos
    
    init() {
        delegate = ThingRepositoryIos(repository: ThingRepository())
    }
    
    func getThing(succeed: Bool) async throws -> Thing {
        try await asyncItem(suspendAdapter: delegate.getThingWrapper(succeed: succeed))
    }

    func getThingStream(count: Int32, succeed: Bool) throws -> AsyncThrowingStream<Thing, Error> {
        try asyncStream(flowAdapter: delegate.getThingStreamWrapper(count: count, succeed: succeed))
    }

    func getOptionalThing(succeed: Bool) async throws -> Thing? {
        try await asyncItem(suspendAdapter: delegate.getNullableThingWrapper(succeed: succeed))
    }

    func getOptionalThingStream(count: Int32, succeed: Bool) throws -> AsyncThrowingStream<Thing?, Error> {
        try asyncStream(flowAdapter: delegate.getNullableThingStreamWrapper(count: count, succeed: succeed))
    }
    
    func countActiveJobs() -> Int32 {
        delegate.countActiveJobs()
    }
    
    deinit {
        delegate.cancel()
    }
}
