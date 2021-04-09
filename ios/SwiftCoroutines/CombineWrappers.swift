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

func createPublisher<T>(
    flowWrapper: FlowWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> AnyPublisher<T, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T, KotlinError>>> {
        let subject = PassthroughSubject<T, KotlinError>()
        let job = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        jobCallback(job)
        return subject.handleEvents(receiveCancel: {
            job.cancel(cause: nil)
        })
    }.eraseToAnyPublisher()
}

func createOptionalPublisher<T>(
    flowWrapper: NullableFlowWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> AnyPublisher<T?, KotlinError> {
    return Deferred<Publishers.HandleEvents<PassthroughSubject<T?, KotlinError>>> {
        let subject = PassthroughSubject<T?, KotlinError>()
        let job = flowWrapper.subscribe { (item) in
            let _ = subject.send(item)
        } onComplete: {
            subject.send(completion: .finished)
        } onThrow: { (error) in
            subject.send(completion: .failure(KotlinError(error)))
        }
        jobCallback(job)
        return subject.handleEvents(receiveCancel: {
            job.cancel(cause: nil)
        })
    }.eraseToAnyPublisher()
}

func createDeferred<T>(
    suspendWrapper: SuspendWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> AnyPublisher<T, KotlinError> {
    var job: Kotlinx_coroutines_coreJob? = nil
    return Deferred {
        return Future { promise in
            let innerJob = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
            jobCallback(innerJob)
            job = innerJob
        }.handleEvents(receiveCancel: {
            job?.cancel(cause: nil)
        })
    }
    .eraseToAnyPublisher()
}

func createOptionalDeferred<T>(
    suspendWrapper: NullableSuspendWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> AnyPublisher<T?, KotlinError> {
    var job: Kotlinx_coroutines_coreJob? = nil
    return Deferred {
        return Future { promise in
            let innerJob = suspendWrapper.subscribe(
                onSuccess: { item in promise(.success(item)) },
                onThrow: { error in promise(.failure(KotlinError(error))) }
            )
            jobCallback(innerJob)
            job = innerJob
        }.handleEvents(receiveCancel: {
            job?.cancel(cause: nil)
        })
    }
    .eraseToAnyPublisher()
}
