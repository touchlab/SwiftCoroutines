//
//  AsyncTests.swift
//  SwiftCoroutinesTests
//
//  Created by Russell Wolf on 10/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import XCTest
@testable import SwiftCoroutines
import shared
import Combine

class AsyncTests: XCTestCase {
    let repository = ThingRepositoryAsync()
    
    func testAsyncCall() async throws {
        let output = try await repository.getThing(succeed: true)
        XCTAssertEqual(output, Thing(count: 0))
    }
    
    func testAsyncNullable() async throws {
        let output = try await repository.getOptionalThing(succeed: true)
        XCTAssertEqual(output, nil)
    }
    
    func testAsyncError() async throws {
        do {
            let _ = try await repository.getThing(succeed: false)
            XCTFail()
        } catch {
            XCTAssertEqual(error.localizedDescription, KotlinError(KotlinThrowable(message: "oh no!")).localizedDescription)
        }
    }
    
    func testAsyncCancel() throws {
        let expectation = expectation(description: "Awaiting task init")
        let task = Task {
            async let thing = try repository.getThing(succeed: true)
            while (repository.countActiveJobs() == 0){} // Hacky ensuring we actually start
            expectation.fulfill()
            let _ = try await thing
            XCTFail()
        }
        
        // Ensure that we don't cancel before we actually start
        waitForExpectations(timeout: 10)
        task.cancel()
        XCTAssertEqual(0, repository.countActiveJobs())
    }
    
    func testAsyncStreamCall() async throws {
        let asyncStream = try repository.getThingStream(count: 3, succeed: true)
        
        let output = await asyncStream.toList()
        XCTAssertEqual(output, .success([Thing(count: 0), Thing(count: 1), Thing(count: 2)]))
    }

    func testAsyncStreamNullable() async throws {
        let asyncStream = try repository.getOptionalThingStream(count: 3, succeed: true)
        
        let output = await asyncStream.toList()
        XCTAssertEqual(output, .success([Thing(count: 0), nil, Thing(count: 2)]))
    }

    func testAsyncStreamError() async throws {
        let asyncStream = try repository.getThingStream(count: 1, succeed: false)
        
        let output = await asyncStream.toList()
        XCTAssertEqual(output, .failure(elements: [Thing(count: 0)], error: KotlinError(KotlinThrowable(message: "oops!"))))
    }
    
    func testAsyncStreamCancel() throws {
        let expectation = expectation(description: "Awaiting task init")
        let task = Task {
            async let things = try repository.getThingStream(count: 3, succeed: true)
            while (repository.countActiveJobs() == 0){} // Hacky ensuring we actually start
            expectation.fulfill()
            let _ = try await things.toList()
            XCTFail()
        }
        
        // Ensure that we don't cancel before we actually start
        waitForExpectations(timeout: 10)
        task.cancel()
        XCTAssertEqual(0, repository.countActiveJobs())
    }
}

private extension AsyncThrowingStream where Element : Equatable {
    func toList() async -> AsyncStreamResult<Element> {
        var elements = [Element]()
        do {
            for try await element in self {
                elements.append(element)
            }
            return .success(elements)
        } catch {
            return .failure(elements: elements, error: error)
        }
    }
}

enum AsyncStreamResult<T: Equatable> : Equatable {
    static func == (lhs: AsyncStreamResult<T>, rhs: AsyncStreamResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsElements), .success(let rhsElements)):
            return lhsElements == rhsElements
        case (.failure(elements: let lhsElements, error: let lhsError), .failure(elements: let rhsElements, error: let rhsError)):
            return lhsElements == rhsElements && lhsError.localizedDescription == rhsError.localizedDescription
        case (_, _):
            return false
        }
    }
    
    case success(_ elements: [T])
    case failure(elements: [T], error: Error)
    case empty
}

