package co.touchlab.example

import co.touchlab.swiftcoroutines.FlowWrapper
import co.touchlab.swiftcoroutines.NullableFlowWrapper
import co.touchlab.swiftcoroutines.NullableSuspendWrapper
import co.touchlab.swiftcoroutines.SuspendWrapper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlin.native.concurrent.freeze

class ThingRepositoryIos(private val repository: ThingRepository) {
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    init {
        freeze()
    }

    fun getThingWrapper(succeed: Boolean) =
        SuspendWrapper(scope) { repository.getThing(succeed) }

    fun getThingStreamWrapper(count: Int, succeed: Boolean) =
        FlowWrapper(scope, repository.getThingStream(count, succeed))

    fun getNullableThingWrapper(succeed: Boolean) =
        NullableSuspendWrapper(scope) { repository.getNullableThing(succeed) }

    fun getNullableThingStreamWrapper(count: Int, succeed: Boolean) =
        NullableFlowWrapper(scope, repository.getNullableThingStream(count, succeed))
}
