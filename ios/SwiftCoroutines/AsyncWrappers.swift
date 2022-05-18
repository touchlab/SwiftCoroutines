//
//  AsyncTests.swift
//  SwiftCoroutinesTests
//
//  Created by Russell Wolf on 10/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import shared
import Foundation

func asyncItem<T>(suspendAdapter: SuspendAdapter<T>) async throws -> T {
    var canceller: Canceller? = nil
    let doCancel = { canceller?.cancel() } // We can't capture var canceller in async code, but we can capture this
    return try await withTaskCancellationHandler(
        operation: {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                canceller = suspendAdapter.subscribe(
                    onSuccess: { item in continuation.resume(returning: item) },
                    onThrow: { error in continuation.resume(throwing: KotlinError(error)) }
                )
            }
        },
        onCancel: { doCancel() }
    )
}

func asyncItem<T>(suspendAdapter: NullableSuspendAdapter<T>) async throws -> T? {
    var canceller: Canceller? = nil
    let doCancel = { canceller?.cancel() } // We can't capture var canceller in async code, but we can capture this
    return try await withTaskCancellationHandler(
        operation: {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                canceller = suspendAdapter.subscribe(
                    onSuccess: { item in continuation.resume(returning: item) },
                    onThrow: { error in continuation.resume(throwing: KotlinError(error)) }
                )
            }
        },
        onCancel: { doCancel() }
    )
}

func asyncStream<T>(flowAdapter: FlowAdapter<T>) throws -> AsyncThrowingStream<T, Error> {
    AsyncThrowingStream<T, Error> { continuation in
        let cancellable = flowAdapter.subscribe(
            onEach: { item in
                continuation.yield(item)
            },
            onComplete: {
                continuation.finish()
            },
            onThrow: { error in
                continuation.finish(throwing: KotlinError(error))
            }
        )
        continuation.onTermination = { _ in cancellable.cancel() }
    }
}

func asyncStream<T>(flowAdapter: NullableFlowAdapter<T>) throws -> AsyncThrowingStream<T?, Error> {
    AsyncThrowingStream<T?, Error> { continuation in
        let cancellable = flowAdapter.subscribe(
            onEach: { item in
                continuation.yield(item)
            },
            onComplete: {
                continuation.finish()
            },
            onThrow: { error in
                continuation.finish(throwing: KotlinError(error))
            }
        )
        continuation.onTermination = { _ in cancellable.cancel() }
    }
}
