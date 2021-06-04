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

func createSingle<T>(suspendWrapper: SuspendAdapter<T>) -> Single<T> {
    return Single<T>.create { single in
        let cancellable = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        return Disposables.create { cancellable.cancel() }
    }
}

func createObservable<T>(flowWrapper: FlowAdapter<T>) -> Observable<T> {
    return Observable<T>.create { observer in
        let cancellable = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        return Disposables.create { cancellable.cancel() }
    }
}

func createOptionalSingle<T>(suspendWrapper: NullableSuspendAdapter<T>) -> Single<T?> {
    return Single<T?>.create { single in
        let cancellable = suspendWrapper.subscribe(
            onSuccess: { item in single(.success(item)) },
            onThrow: { error in single(.error(KotlinError(error))) }
        )
        return Disposables.create { cancellable.cancel() }
    }
}

func createOptionalObservable<T>(flowWrapper: NullableFlowAdapter<T>) -> Observable<T?> {
    return Observable<T?>.create { observer in
        let cancellable = flowWrapper.subscribe(
            onEach: { item in observer.on(.next(item)) },
            onComplete: { observer.on(.completed) },
            onThrow: { error in observer.on(.error(KotlinError(error))) }
        )
        return Disposables.create { cancellable.cancel() }
    }
}

