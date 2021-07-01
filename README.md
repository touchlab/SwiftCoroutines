### Swift/Coroutines interop

This is the code associated
with [this updated blog post](https://dev.to/touchlab/kotlin-coroutines-and-swift-revisited-j5h) on Coroutines and
Swift interop. If you can here from
the [first version](https://dev.to/touchlab/working-with-kotlin-coroutines-and-rxswift-24fa), you can find the original
sample code on the [v1 branch](https://github.com/touchlab/SwiftCoroutines/tree/v1)

The `shared` directory contains Kotlin code, including a `ThingRepository` in common and a wrapper `ThingRespositoryIos`
in the ios sources, which makes use of interop utilities in `SwiftCoroutines.kt`.

The Kotlin code is consumed by an Xcode project in the `ios` directory. In there, `RxSwiftWrappers.swift` defines the
RxSwift linkages to the coroutine wrappers in `SwiftCoroutines.kt`, and makes a demo call in `SceneDelegate.swift`.
Additionally, `CombineWrappers.swift` defines equivalent Combine functions, with a demo call in `SceneDelegate.swift`
as well as SwiftUI consumtion in `SwiftUIDemo.swift`. There are also unit tests in `RxSwiftWrappersTests.swift` and
`CombineWrappersTests` which, while not exhaustive, verify most of the workings of the interop code, including checking
multithreaded usage and cancellation.
