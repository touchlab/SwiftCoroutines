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

class RxSwiftWrappersTests: XCTestCase {
    
    let repository = ThingRepositoryRxSwift()
    
    func testSingleCall() throws {
        let single = repository.getThing(succeed: true)
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0)])
        case .failed:
            XCTFail()
        }
    }
    
    func testSingleNullable() throws {
        let single = repository.getOptionalThing(succeed: true)
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [nil])
        case .failed:
            XCTFail()
        }
    }
    
    func testSingleError() throws {
        let single = repository.getThing(succeed: false)
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
        let observable = repository.getThingStream(count: 3, succeed: true)
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0), Thing(count: 1), Thing(count: 2)])
        case .failed:
            XCTFail()
        }
    }
    
    func testObservableNullable() throws {
        let observable = repository.getOptionalThingStream(count: 3, succeed: true)
        let output = observable.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [Thing(count: 0), nil, Thing(count: 2)])
        case .failed:
            XCTFail()
        }
    }
    
    func testObservableError() throws {
        let observable = repository.getThingStream(count: 1, succeed: false)
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
        let single = repository.getThing(succeed: true)
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
        let observable = repository.getThingStream(count: 3, succeed: true)
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
        let single = repository.getThing(succeed: false)
        let disposable = single.subscribe()
        
        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let output = Completable.create { completable in
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertEqual(1, self.repository.countActiveJobs())
            disposable.dispose()
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
        
        XCTAssertEqual(0, self.repository.countActiveJobs())
    }
    
    func testBackgroundObservableDispose() throws {
        let observable = repository.getThingStream(count: 3, succeed: true)
        let disposable = observable.subscribe()

        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let output = Completable.create { completable in
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertEqual(1, self.repository.countActiveJobs())
            disposable.dispose()
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
        
        XCTAssertEqual(0, self.repository.countActiveJobs())
    }
    
    func testBackgroundRepository() throws {
        var backgroundRepository: ThingRepositoryRxSwift? = nil

        let _ = Completable.create { completable in
            XCTAssertFalse(Thread.current.isMainThread)
            backgroundRepository = ThingRepositoryRxSwift()
            completable(.completed)
            return Disposables.create()
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        .toBlocking()
        .materialize()

        XCTAssertNotNil(backgroundRepository)

        let single = backgroundRepository!.getOptionalThing(succeed: true)
        let output = single.toBlocking().materialize()
        switch output {
        case .completed(let elements):
            XCTAssertEqual(elements, [nil])
        case .failed:
            XCTFail()
        }
    }
}
