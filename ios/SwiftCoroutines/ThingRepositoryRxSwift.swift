//
//  ThingRepositorySwift.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 4/29/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import shared
import RxSwift

class ThingRepositoryRxSwift {
    private let delegate: ThingRepositoryIos
    
    init() {
        self.delegate = ThingRepositoryIos(repository: ThingRepository())
    }
    
    func getThing(succeed: Bool) -> Single<Thing> {
        createSingle(suspendWrapper: delegate.getThingWrapper(succeed: succeed))
    }

    func getThingStream(count: Int32, succeed: Bool) -> Observable<Thing> {
        createObservable(flowWrapper: delegate.getThingStreamWrapper(count: count, succeed: succeed))
    }

    func getOptionalThing(succeed: Bool) -> Single<Thing?> {
        createOptionalSingle(suspendWrapper: delegate.getNullableThingWrapper(succeed: succeed))
    }

    func getOptionalThingStream(count: Int32, succeed: Bool) -> Observable<Thing?> {
        createOptionalObservable(flowWrapper: delegate.getNullableThingStreamWrapper(count: count, succeed: succeed))
    }
    
    func countActiveJobs() -> Int32 {
        delegate.countActiveJobs()
    }
    
    deinit {
        self.delegate.dispose()
    }
}
