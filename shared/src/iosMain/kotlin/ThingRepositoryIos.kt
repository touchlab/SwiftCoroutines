package co.touchlab.example

import co.touchlab.swiftcoroutines.FlowWrapper
import co.touchlab.swiftcoroutines.NullableFlowWrapper
import co.touchlab.swiftcoroutines.NullableSuspendWrapper
import co.touchlab.swiftcoroutines.SuspendWrapper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlin.native.concurrent.freeze

class ThingRepositoryIos(private val repository: ThingRepository) {
    private val supervisorJob = SupervisorJob()
    private val scope: CoroutineScope = CoroutineScope(supervisorJob + Dispatchers.Default)

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

    // Helps verify cancellation in tests
    fun countActiveJobs() = scope.coroutineContext[Job]?.children?.filter { it.isActive }?.count() ?: 0

    fun dispose() {
        supervisorJob.cancelChildren()
    }
}
