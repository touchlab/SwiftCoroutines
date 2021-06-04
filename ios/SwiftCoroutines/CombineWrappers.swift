//
//  CombineWrappers.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 2/28/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import Foundation
import Combine
import shared

func createPublisher<T>(flowWrapper: FlowAdapter<T>) -> AnyPublisher<T, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T, KotlinError>>> {
        let subject = PassthroughSubject<T, KotlinError>()
        let cancellable = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        return subject.handleEvents(receiveCancel: {
            cancellable.cancel()
        })
    }.eraseToAnyPublisher()
}

func createOptionalPublisher<T>(flowWrapper: NullableFlowAdapter<T>) -> AnyPublisher<T?, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T?, KotlinError>>> {
        let subject = PassthroughSubject<T?, KotlinError>()
        let cancellable = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        return subject.handleEvents(receiveCancel: {
            cancellable.cancel()
        })
    }.eraseToAnyPublisher()
}

func createFuture<T>(suspendWrapper: SuspendAdapter<T>) -> AnyPublisher<T, KotlinError> {
    return Deferred<Publishers.HandleEvents<Future<T, KotlinError>>> {
        var cancellable: Canceller? = nil
        return Future { promise in
            cancellable = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
        }.handleEvents(receiveCancel: {
            cancellable?.cancel()
        })
    }
    .eraseToAnyPublisher()
}

func createOptionalFuture<T>(suspendWrapper: NullableSuspendAdapter<T>) -> AnyPublisher<T?, KotlinError> {
    return Deferred<Publishers.HandleEvents<Future<T?, KotlinError>>> {
        var cancellable: Canceller? = nil
        return Future { promise in
            cancellable = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
        }.handleEvents(receiveCancel: {
            cancellable?.cancel()
        })
    }
    .eraseToAnyPublisher()
}
