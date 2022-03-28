package co.touchlab.swiftcoroutines

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onCompletion
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlin.native.concurrent.freeze

interface Canceller {
    fun cancel()
}

class JobCanceller(private val job: Job) : Canceller {
    init {
        freeze()
    }

    override fun cancel() {
        job.cancel()
    }
}

class SuspendAdapter<T : Any>(
    private val scope: CoroutineScope,
    private val suspender: suspend () -> T
) {
    init {
        freeze()
    }

    fun subscribe(
        onSuccess: (item: T) -> Unit,
        onThrow: (error: Throwable) -> Unit
    ): Canceller = JobCanceller(
        scope.launch {
            try {
                onSuccess(suspender().freeze())
            } catch (error: Throwable) {
                onThrow(error.freeze())
            }
        }.freeze()
    )
}

class NullableSuspendAdapter<T>(
    private val scope: CoroutineScope,
    private val suspender: suspend () -> T
) {
    init {
        freeze()
    }

    fun subscribe(
        onSuccess: (item: T) -> Unit,
        onThrow: (error: Throwable) -> Unit
    ): Canceller = JobCanceller(
        scope.launch {
            try {
                onSuccess(suspender().freeze())
            } catch (error: Throwable) {
                onThrow(error.freeze())
            }
        }.freeze()
    )
}

class FlowAdapter<T : Any>(
    private val scope: CoroutineScope,
    private val flow: Flow<T>
) {
    init {
        freeze()
    }

    fun subscribe(
        onEach: (item: T) -> Unit,
        onComplete: () -> Unit,
        onThrow: (error: Throwable) -> Unit
    ): Canceller = JobCanceller(
        flow
            .onEach { onEach(it.freeze()) }
            .catch { onThrow(it.freeze()) } // catch{} before onCompletion{} or else completion hits rx first and ends stream
            .onCompletion { onComplete() }
            .launchIn(scope)
            .freeze()
    )
}

class NullableFlowAdapter<T>(
    private val scope: CoroutineScope,
    private val flow: Flow<T>
) {
    init {
        freeze()
    }

    fun subscribe(
        onEach: (item: T) -> Unit,
        onComplete: () -> Unit,
        onThrow: (error: Throwable) -> Unit
    ): Canceller = JobCanceller(
        flow.onEach { onEach(it.freeze()) }
            .catch { onThrow(it.freeze()) } // catch{} before onCompletion{} or else completion hits rx first and ends stream
            .onCompletion { onComplete() }
            .launchIn(scope)
            .freeze()
    )
}

class InverseFlowAdapter<T : Any>(
    private val subscribe: (
        onEach: (T) -> Unit,
        onComplete: () -> Unit,
        onError: (Throwable) -> Unit
    ) -> (() -> Unit),
) {
    fun createFlow(): Flow<T> = callbackFlow {
        val onEach: (T) -> Unit = { trySend(it) }
        val onComplete: () -> Unit = { close() }
        val onError: (Throwable) -> Unit =
            { cancel(CancellationException("Error passed to InverseFlowAdapter: ${it.message}", it)) }

        val unsubscribe = subscribe(
            onEach.freeze(),
            onComplete.freeze(),
            onError.freeze()
        )
        awaitClose {
            unsubscribe.freeze().invoke()
        }
    }
}

class CombineConsumingThing<T : Any>(inverseFlowAdapter: InverseFlowAdapter<T>) {
    init {
        inverseFlowAdapter.createFlow()
            .onEach {
                println("Inverse next: $it")
            }
            .onCompletion { throwable ->
                if (throwable != null) {
                    println("Inverse error: ${throwable.message}")
                } else {
                    println("Inverse done!")
                }
            }
            .launchIn(GlobalScope)
    }
}
