//
//  SwiftCoroutinesTests.swift
//  SwiftCoroutinesTests
//
//  Created by Russell Wolf on 6/10/20.
//  Copyright © 2020 Touchlab. All rights reserved.
//

import XCTest
@testable import SwiftCoroutines
import shared
import RxSwift
import RxTest
import RxBlocking

class SwiftCoroutinesTests: XCTestCase {
    
    let repository = ThingRepositoryIos(repository: ThingRepository())
    
    func testSingleCall() throws {
        let single = createSingle(scope: repository.scope, suspendWrapper: repository.getThingWrapper(succeed: true))
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0)])
        case .failed:
            XCTFail()
        }
    }
    
    func testSingleNullable() throws {
        let single = createNullableSingle(scope: repository.scope, suspendWrapper: repository.getNullableThingWrapper(succeed: true))
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [nil])
        case .failed:
            XCTFail()
        }
    }
    
    func testSingleError() throws {
        let single = createSingle(scope: repository.scope, suspendWrapper: repository.getThingWrapper(succeed: false))
        let output = single.toBlocking().materialize()
        switch output {
        case .completed:
            XCTFail()
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [])
            let kotlinError: KotlinError = error as! KotlinError
            XCTAssertEqual(kotlinError.throwable.message, "oh no!")
        }
    }
    
    func testObservableCall() throws {
        let observable = createObservable(scope: repository.scope, flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0), Thing(count: 1), Thing(count: 2)])
        case .failed:
            XCTFail()
        }
    }
    
    func testObservableNullable() throws {
        let observable = createNullableObservable(scope: repository.scope, flowWrapper: repository.getNullableThingStreamWrapper(count: 3, succeed: true))
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0), nil, Thing(count: 2)])
        case .failed:
            XCTFail()
        }
    }
    
    func testObservableError() throws {
        let observable = createObservable(scope: repository.scope, flowWrapper: repository.getThingStreamWrapper(count: 1, succeed: false))
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed:
            XCTFail()
        case .failed(let elements, let error):
            XCTAssertEqual(elements, [Thing(count: 0)])
            let kotlinError: KotlinError = error as! KotlinError
            XCTAssertEqual(kotlinError.throwable.message, "oops!")
        }
    }
    
    func testBackgroundSingle() throws {
        let single = createSingle(scope: repository.scope, suspendWrapper: repository.getThingWrapper(succeed: true))
            .do(onSuccess: { _ in XCTAssertFalse(Thread.current.isMainThread) })
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0)])
        case .failed:
            XCTFail()
        }
    }
       
    func testBackgroundObservable() throws {
        let observable = createObservable(scope: repository.scope, flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
            .do(onNext: { _ in XCTAssertFalse(Thread.current.isMainThread) })
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0), Thing(count: 1), Thing(count: 2)])
        case .failed:
            XCTFail()
        }
    }
    
    func testBackgroundSingleDispose() throws {
        var disposable: Disposable? = nil
        var job: Kotlinx_coroutines_coreJob? = nil
        let single = createSingle(scope: repository.scope, suspendWrapper: repository.getThingWrapper(succeed: false), jobCallback: { j in job = j })
        disposable = single.subscribe()
        
        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let output = Completable.create { completable in
            XCTAssertFalse(Thread.current.isMainThread)
            disposable?.dispose()
            completable(.completed)
            return Disposables.create()
        }
        .subscribeOn(backgroundScheduler)
        .delay(RxTimeInterval.milliseconds(50), scheduler: backgroundScheduler)
        .toBlocking()
        .materialize()
        
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [])
        case .failed:
            XCTFail()
        }
        
        XCTAssertTrue(job?.isCancelled == true)
    }
    
    func testBackgroundObservableDispose() throws {
        var disposable: Disposable? = nil
        var job: Kotlinx_coroutines_coreJob? = nil
        let observable = createObservable(scope: repository.scope, flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true), jobCallback: { j in job = j })
        disposable = observable.subscribe()

        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let output = Completable.create { completable in
            XCTAssertFalse(Thread.current.isMainThread)
            disposable?.dispose()
            completable(.completed)
            return Disposables.create()
        }
        .subscribeOn(backgroundScheduler)
        .delay(RxTimeInterval.milliseconds(150), scheduler: backgroundScheduler)
        .toBlocking()
        .materialize()
        
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [])
        case .failed:
            XCTFail()
        }
        
        XCTAssertTrue(job?.isCancelled == true)
    }
}
