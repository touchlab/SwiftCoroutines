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

class ViewController: UIViewController {

    let repository = ThingRepositoryIos(repository: ThingRepository())
    var disposable: Disposable? = nil

    override func viewDidAppear(_ animated: Bool) {
        disposable = createObservable(scope: repository.scope, flowWrapper: repository.getThingStreamWrapper(count: 3, succeed: true))
            .subscribe(
                onNext: { thing in
                    NSLog("next: \(thing)")
                },
                onError: { (error: Error) in
                    NSLog("error: \(error.localizedDescription)")
                },
                onCompleted: {
                    NSLog("complete!")
                },
                onDisposed: {
                    NSLog("disposed!")
                }
            )
    }

    override func viewWillDisappear(_ animated: Bool) {
        disposable?.dispose()
        disposable = nil
    }
}

