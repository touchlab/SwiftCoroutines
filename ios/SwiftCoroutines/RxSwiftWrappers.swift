//
//  RxSwiftWrappers.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 6/10/20.
//  Copyright © 2020 Touchlab. All rights reserved.
//

import Foundation
import RxSwift
import shared

func createSingle<T>(
    suspendWrapper: SuspendWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> Single<T> {
    return Single<T>.create { single in
        let job: Kotlinx_coroutines_coreJob = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        jobCallback(job)
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createObservable<T>(
    flowWrapper: FlowWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> Observable<T> {
    return Observable<T>.create { observer in
        let job: Kotlinx_coroutines_coreJob = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        jobCallback(job)
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createOptionalSingle<T>(
    suspendWrapper: NullableSuspendWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> Single<T?> {
    return Single<T?>.create { single in
        let job: Kotlinx_coroutines_coreJob = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        jobCallback(job)
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createOptionalObservable<T>(
    flowWrapper: NullableFlowWrapper<T>,
    jobCallback: @escaping (Kotlinx_coroutines_coreJob) -> Void = { _ in }
) -> Observable<T?> {
    return Observable<T?>.create { observer in
        let job: Kotlinx_coroutines_coreJob = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        jobCallback(job)
        return Disposables.create { job.cancel(cause: nil) }
    }
}

