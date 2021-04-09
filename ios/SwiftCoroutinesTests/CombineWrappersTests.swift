//
//  CombineWrappersTests.swift
//  SwiftCoroutinesTests
//
//  Created by Russell Wolf on 2/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import XCTest
@testable import SwiftCoroutines
import shared
import Combine

class CombineWrappersTests: XCTestCase {
    let repository = ThingRepositoryIos(repository: ThingRepository())
    
    func testDeferredCall() throws {
        let deferred = createDeferred(suspendWrapper: repository.getThingWrapper(succeed: true))
        
        let output = try await(deferred)
        XCTAssertEqual(output, .success([Thing(count: 0)]))
    }

    func testDeferredNullable() throws {
        let deferred = createOptionalDeferred(suspendWrapper: repository.getNullableThingWrapper(succeed: true))
        
        let output = try await(deferred)
        XCTAssertEqual(output, .success([nil]))
    }
    
    func testDeferredError() throws {
        let deferred = createDeferred(suspendWrapper: repository.getThingWrapper(succeed: false))

        let output = try await(deferred)
        XCTAssertEqual(output, .failure(items: [], error: KotlinError(KotlinThrowable(message: "oh no!"))))
    }
    
    func testPublisherCall() throws {
        let publisher = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }

    func testPublisherNullable() throws {
        let publisher = createOptionalPublisher(flowWrapper: repository.getNullableThingStreamWrapper(count: 3, succeed: true))
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), nil, Thing(count: 2)]))
    }
    
    func testPublisherError() throws {
        let publisher = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 1, succeed: false))
        
        let output = try await(publisher)
        XCTAssertEqual(output, .failure(items: [Thing(count: 0)], error: KotlinError(KotlinThrowable(message: "oops!"))))
    }
    
    func testBackgroundDeferredCall() throws {
        let publisher = createDeferred(suspendWrapper: repository.getThingWrapper(succeed: true))
            .subscribe(on: DispatchQueue.global())
            .map { (thing) -> Thing in
                XCTAssertFalse(Thread.isMainThread)
                return thing
            }
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0)]))
    }

    func testBackgroundDeferredDispose() throws {
        var cancellable: AnyCancellable? = nil
        var job: Kotlinx_coroutines_coreJob? = nil

        
        cancellable = createDeferred(suspendWrapper: repository.getThingWrapper(succeed: true), jobCallback: { j in job = j })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertNotNil(job)
            cancellable?.cancel()
            latch.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        XCTAssertTrue(job?.isCancelled == true)
    }
    
    func testBackgroundPublisherCall() throws {
        let publisher = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
            .subscribe(on: DispatchQueue.global())
            .map { (thing) -> Thing in
                XCTAssertFalse(Thread.isMainThread)
                return thing
            }
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }

    func testBackgroundPublisherDispose() throws {
        var cancellable: AnyCancellable? = nil
        var job: Kotlinx_coroutines_coreJob? = nil

        
        cancellable = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true), jobCallback: { j in job = j })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertNotNil(job)
            cancellable?.cancel()
            latch.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        XCTAssertTrue(job?.isCancelled == true)
    }
    
    func testBackgroundRepository() throws {
        var backgroundRepository: ThingRepositoryIos? = nil

        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            backgroundRepository = ThingRepositoryIos(repository: ThingRepository())
            latch.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNotNil(backgroundRepository)
        
        let publisher = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }
}

// adapted from https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
extension XCTestCase {
    func await<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10
    ) throws -> CombineResult<T.Output> {
        var result: CombineResult<T.Output> = .empty
        let expectation = self.expectation(description: "Awaiting publisher")

        var items = [T.Output]()
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(items: items, error: error)
                case .finished:
                    result = .success(items)
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                items.append(value)
            }
        )

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        return result
    }
}

enum CombineResult<T: Equatable> : Equatable {
    static func == (lhs: CombineResult<T>, rhs: CombineResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsItems), .success(let rhsItems)):
            return lhsItems == rhsItems
        case (.failure(items: let lhsItems, error: let lhsError), .failure(items: let rhsItems, error: let rhsError)):
            return lhsItems == rhsItems && lhsError.localizedDescription == rhsError.localizedDescription
        case (_, _):
            return false
        }
    }
    
    case success(_ items: [T])
    case failure(items: [T], error: Error)
    case empty
}
