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
    let repository = ThingRepositoryCombine()
    
    func testFutureCall() throws {
        let future = repository.getThing(succeed: true)
        
        let output = try await(future)
        XCTAssertEqual(output, .success([Thing(count: 0)]))
    }

    func testFutureNullable() throws {
        let future = repository.getOptionalThing(succeed: true)
        
        let output = try await(future)
        XCTAssertEqual(output, .success([nil]))
    }
    
    func testFutureError() throws {
        let future = repository.getThing(succeed: false)

        let output = try await(future)
        XCTAssertEqual(output, .failure(items: [], error: KotlinError(KotlinThrowable(message: "oh no!"))))
    }
    
    func testPublisherCall() throws {
        let publisher = repository.getThingStream(count: 3, succeed: true)
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }

    func testPublisherNullable() throws {
        let publisher = repository.getOptionalThingStream(count: 3, succeed: true)
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), nil, Thing(count: 2)]))
    }
    
    func testPublisherError() throws {
        let publisher = repository.getThingStream(count: 1, succeed: false)
        
        let output = try await(publisher)
        XCTAssertEqual(output, .failure(items: [Thing(count: 0)], error: KotlinError(KotlinThrowable(message: "oops!"))))
    }
    
    func testBackgroundFutureCall() throws {
        let publisher = repository.getThing(succeed: true)
            .subscribe(on: DispatchQueue.global())
            .map { (thing) -> Thing in
                XCTAssertFalse(Thread.isMainThread)
                return thing
            }
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0)]))
    }

    func testBackgroundFutureDispose() throws {
        let cancellable = repository.getThing(succeed: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertEqual(1, self.repository.countActiveJobs())
            cancellable.cancel()
            latch.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        XCTAssertEqual(0, self.repository.countActiveJobs())
    }
    
    func testBackgroundPublisherCall() throws {
        let publisher = repository.getThingStream(count: 3, succeed: true)
            .subscribe(on: DispatchQueue.global())
            .map { (thing) -> Thing in
                XCTAssertFalse(Thread.isMainThread)
                return thing
            }
        
        let output = try await(publisher)
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }

    func testBackgroundPublisherDispose() throws {
        let cancellable = repository.getThingStream(count: 3, succeed: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            XCTAssertEqual(1, self.repository.countActiveJobs())
            cancellable.cancel()
            latch.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        XCTAssertEqual(0, self.repository.countActiveJobs())
    }
    
    func testBackgroundRepository() throws {
        var backgroundRepository: ThingRepositoryCombine? = nil

        let latch = expectation(description: "background test")
        DispatchQueue.global().async {
            XCTAssertFalse(Thread.current.isMainThread)
            backgroundRepository = ThingRepositoryCombine()
            latch.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNotNil(backgroundRepository)
        
        let publisher = backgroundRepository!.getThingStream(count: 3, succeed: true)
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
