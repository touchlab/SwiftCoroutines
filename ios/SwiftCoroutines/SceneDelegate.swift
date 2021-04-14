//
//  SceneDelegate.swift
//  SwiftCoroutines
//
//  Created by Russell Wolf on 6/10/20.
//  Copyright © 2020 Touchlab. All rights reserved.
//

import UIKit
import SwiftUI
import shared
import RxSwift
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let repository = ThingRepositoryIos(repository: ThingRepository())
    var disposable: Disposable? = nil
    var cancellable: AnyCancellable? = nil
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ThingView(repository))
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        disposable = createObservable(flowWrapper: repository.getThingStreamWrapper(count: 10, succeed: true))
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
        
        cancellable = createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 10, succeed: true))
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

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
        disposable?.dispose()
        disposable = nil
        
        cancellable?.cancel()
        cancellable = nil
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

