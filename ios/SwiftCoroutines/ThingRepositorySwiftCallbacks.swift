import shared

class ThingRepositorySwiftCallbacks {
    private let delegate: ThingRepositoryIos
    
    init() {
        self.delegate = ThingRepositoryIos(repository: ThingRepository())
    }
    
    func getThing(
        succeed: Bool,
        onSuccess: @escaping (Thing) -> Void,
        onThrow: @escaping (KotlinError) -> Void
    ) -> Kotlinx_coroutines_coreJob {
        delegate.getThingWrapper(succeed: succeed)
            .subscribe(onSuccess: onSuccess, onThrow: { error in onThrow(KotlinError(error)) })
    }
    
    func getThingStream(
        count: Int32,
        succeed: Bool,
        onEach: @escaping (Thing) -> Void,
        onComplete: @escaping () -> Void,
        onThrow: @escaping (KotlinError) -> Void
    ) -> Kotlinx_coroutines_coreJob {
        delegate.getThingStreamWrapper(count: count, succeed: succeed)
            .subscribe(onEach: onEach, onComplete: onComplete, onThrow: { error in onThrow(KotlinError(error)) })
    }

    func getOptionalThing(
        succeed: Bool,
        onSuccess: @escaping (Thing?) -> Void,
        onThrow: @escaping (KotlinError) -> Void
    ) -> Kotlinx_coroutines_coreJob {
        delegate.getNullableThingWrapper(succeed: succeed)
            .subscribe(onSuccess: onSuccess, onThrow: { error in onThrow(KotlinError(error)) })
    }
    
    func getOptionalThingStream(
        count: Int32,
        succeed: Bool,
        onEach: @escaping (Thing?) -> Void,
        onComplete: @escaping () -> Void,
        onThrow: @escaping (KotlinError) -> Void
    ) -> Kotlinx_coroutines_coreJob {
        delegate.getNullableThingStreamWrapper(count: count, succeed: succeed)
            .subscribe(onEach: onEach, onComplete: onComplete, onThrow: { error in onThrow(KotlinError(error)) })
    }
    
    deinit {
        self.delegate.dispose()
    }
}
