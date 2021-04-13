//
//  ViewController.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 6/10/20.
//  Copyright © 2020 Touchlab. All rights reserved.
//

import UIKit
import shared
import RxSwift
import Combine

class ViewController: UIViewController {

    let repository = ThingRepositoryIos(repository: ThingRepository())
    var disposable: Disposable? = nil
    var cancellable: AnyCancellable? = nil

    override func viewDidAppear(_ animated: Bool) {
        disposable = createObservable(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
            .subscribe(
                onNext: { thing in
                    NSLog("RxSwift next: \(thing)")
                },
                onError: { (error: Error) in
                    NSLog("RxSwift error: \(error.localizedDescription)")
                },
                onCompleted: {
                    NSLog("RxSwift complete!")
                },
                onDisposed: {
                    NSLog("RxSwift disposed!")
                }
            )
        
        cancellable = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
            .handleEvents(receiveCancel: { NSLog("Combine canceled!") })
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        NSLog("Combine error: \(error.localizedDescription)")
                    case .finished:
                        NSLog("Combine finished!")
                    }
                },
                receiveValue: { thing in
                    NSLog("Combine next: \(thing)")
                }
            )
    }

    override func viewWillDisappear(_ animated: Bool) {
        disposable?.dispose()
        disposable = nil
        
        cancellable?.cancel()
        cancellable = nil
    }
}

