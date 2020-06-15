package co.touchlab.example

import co.touchlab.swiftcoroutines.FlowWrapper
import co.touchlab.swiftcoroutines.NullableFlowWrapper
import co.touchlab.swiftcoroutines.NullableSuspendWrapper
import co.touchlab.swiftcoroutines.SuspendWrapper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlin.coroutines.CoroutineContext

class ThingRepositoryIos(private val repository: ThingRepository) {
    val scope: CoroutineScope = object : CoroutineScope {
        override val coroutineContext: CoroutineContext
            get() = SupervisorJob() + Dispatchers.Default
    }

    fun getThingWrapper(succeed: Boolean) = SuspendWrapper { repository.getThing(succeed) }
    fun getThingStreamWrapper(count: Int, succeed: Boolean) = FlowWrapper { repository.getThingStream(count, succeed) }
    fun getNullableThingWrapper(succeed: Boolean) = NullableSuspendWrapper { repository.getNullableThing(succeed) }
    fun getNullableThingStreamWrapper(count: Int, succeed: Boolean) =
        NullableFlowWrapper { repository.getNullableThingStream(count, succeed) }
}
