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

func createPublisher<T>(flowWrapper: FlowWrapper<T>) -> AnyPublisher<T, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T, KotlinError>>> {
        let subject = PassthroughSubject<T, KotlinError>()
        let job = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        return subject.handleEvents(receiveCancel: {
            job.cancel(cause: nil)
        })
    }.eraseToAnyPublisher()
}

func createOptionalPublisher<T>(flowWrapper: NullableFlowWrapper<T>) -> AnyPublisher<T?, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T?, KotlinError>>> {
        let subject = PassthroughSubject<T?, KotlinError>()
        let job = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        return subject.handleEvents(receiveCancel: {
            job.cancel(cause: nil)
        })
    }.eraseToAnyPublisher()
}

func createFuture<T>(suspendWrapper: SuspendWrapper<T>) -> AnyPublisher<T, KotlinError> {
    return Deferred<Publishers.HandleEvents<Future<T, KotlinError>>> {
        var job: Kotlinx_coroutines_coreJob? = nil
        return Future { promise in
            job = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
        }.handleEvents(receiveCancel: {
            job?.cancel(cause: nil)
        })
    }
    .eraseToAnyPublisher()
}

func createOptionalFuture<T>(suspendWrapper: NullableSuspendWrapper<T>) -> AnyPublisher<T?, KotlinError> {
    return Deferred<Publishers.HandleEvents<Future<T?, KotlinError>>> {
        var job: Kotlinx_coroutines_coreJob? = nil
        return Future { promise in
            job = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
        }.handleEvents(receiveCancel: {
            job?.cancel(cause: nil)
        })
    }
    .eraseToAnyPublisher()
}
