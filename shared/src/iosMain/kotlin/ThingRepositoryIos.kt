package co.touchlab.example

import co.touchlab.swiftcoroutines.Canceller
import co.touchlab.swiftcoroutines.FlowAdapter
import co.touchlab.swiftcoroutines.NullableFlowAdapter
import co.touchlab.swiftcoroutines.NullableSuspendAdapter
import co.touchlab.swiftcoroutines.SuspendAdapter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlin.native.concurrent.freeze

class ThingRepositoryIos(private val repository: ThingRepository) : Canceller {
    private val supervisorJob = SupervisorJob()
    private val scope: CoroutineScope = CoroutineScope(supervisorJob + Dispatchers.Default)

    init {
        freeze()
    }

    fun getThingWrapper(succeed: Boolean) =
        SuspendAdapter(scope) { repository.getThing(succeed) }

    fun getThingStreamWrapper(count: Int, succeed: Boolean) =
        FlowAdapter(scope, repository.getThingStream(count, succeed))

    fun getNullableThingWrapper(succeed: Boolean) =
        NullableSuspendAdapter(scope) { repository.getNullableThing(succeed) }

    fun getNullableThingStreamWrapper(count: Int, succeed: Boolean) =
        NullableFlowAdapter(scope, repository.getNullableThingStream(count, succeed))

    // Helps verify cancellation in tests
    fun countActiveJobs() = scope.coroutineContext[Job]?.children?.filter { it.isActive }?.count() ?: 0

    override fun cancel() {
        supervisorJob.cancelChildren()
    }
}

class ThingRepositoryAdapter(repository: ThingRepository) : CoroutineAdapter<ThingRepository>(repository) {
    fun getThingWrapper(succeed: Boolean) =
        SuspendAdapter(coroutineScope) { delegate.getThing(succeed) }

    fun getThingStreamWrapper(count: Int, succeed: Boolean) =
        FlowAdapter(coroutineScope, delegate.getThingStream(count, succeed))

    fun getNullableThingWrapper(succeed: Boolean) =
        NullableSuspendAdapter(coroutineScope) { delegate.getNullableThing(succeed) }

    fun getNullableThingStreamWrapper(count: Int, succeed: Boolean) =
        NullableFlowAdapter(coroutineScope, delegate.getNullableThingStream(count, succeed))

    // Helps verify cancellation in tests
    fun countActiveJobs() = coroutineScope.coroutineContext[Job]?.children?.filter { it.isActive }?.count() ?: 0
}

abstract class CoroutineAdapter<T : Any>(protected val delegate: T) : Canceller {
    private val supervisorJob = SupervisorJob()
    protected val coroutineScope: CoroutineScope = CoroutineScope(supervisorJob + Dispatchers.Default)

    init {
        freeze()
    }

    override fun cancel() {
        supervisorJob.cancelChildren()
    }
}
