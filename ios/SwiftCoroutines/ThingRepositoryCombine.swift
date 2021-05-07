//
//  ThingRepositorySwift.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 4/29/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import shared
import Combine

class ThingRepositoryCombine {
    private let delegate: ThingRepositoryIos
    
    init() {
        delegate = ThingRepositoryIos(repository: ThingRepository())
    }
    
    func getThing(succeed: Bool) -> AnyPublisher<Thing, KotlinError> {
        createFuture(suspendWrapper: delegate.getThingWrapper(succeed: succeed))
    }

    func getThingStream(count: Int32, succeed: Bool) -> AnyPublisher<Thing, KotlinError> {
        createPublisher(flowWrapper: delegate.getThingStreamWrapper(count: count, succeed: succeed))
    }

    func getOptionalThing(succeed: Bool) -> AnyPublisher<Thing?, KotlinError> {
        createOptionalFuture(suspendWrapper: delegate.getNullableThingWrapper(succeed: succeed))
    }

    func getOptionalThingStream(count: Int32, succeed: Bool) -> AnyPublisher<Thing?, KotlinError> {
        createOptionalPublisher(flowWrapper: delegate.getNullableThingStreamWrapper(count: count, succeed: succeed))
    }
    
    func countActiveJobs() -> Int32 {
        delegate.countActiveJobs()
    }
    
    deinit {
        delegate.dispose()
    }
}
