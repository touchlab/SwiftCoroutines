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

func createSingle<T>(suspendWrapper: SuspendWrapper<T>) -> Single<T> {
    return Single<T>.create { single in
        let job: Kotlinx_coroutines_coreJob = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createObservable<T>(flowWrapper: FlowWrapper<T>) -> Observable<T> {
    return Observable<T>.create { observer in
        let job: Kotlinx_coroutines_coreJob = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createOptionalSingle<T>(suspendWrapper: NullableSuspendWrapper<T>) -> Single<T?> {
    return Single<T?>.create { single in
        let job: Kotlinx_coroutines_coreJob = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        return Disposables.create { job.cancel(cause: nil) }
    }
}

func createOptionalObservable<T>(flowWrapper: NullableFlowWrapper<T>) -> Observable<T?> {
    return Observable<T?>.create { observer in
        let job: Kotlinx_coroutines_coreJob = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        return Disposables.create { job.cancel(cause: nil) }
    }
}

