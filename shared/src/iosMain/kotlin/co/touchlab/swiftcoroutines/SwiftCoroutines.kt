package co.touchlab.swiftcoroutines

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlin.native.concurrent.freeze

class SuspendWrapper<T : Any>(
    private val scope: CoroutineScope,
    private val suspender: suspend () -> T
) {
    init {
        freeze()
    }

    fun subscribe(
        onSuccess: (item: T) -> Unit,
        onThrow: (error: Throwable) -> Unit
    ) = scope.launch {
        try {
            onSuccess(suspender().freeze())
        } catch (error: Throwable) {
            onThrow(error.freeze())
        }
    }.freeze()
}

class NullableSuspendWrapper<T>(
    private val scope: CoroutineScope,
    private val suspender: suspend () -> T
) {
    init {
        freeze()
    }

    fun subscribe(
        onSuccess: (item: T) -> Unit,
        onThrow: (error: Throwable) -> Unit
    ) = scope.launch {
        try {
            onSuccess(suspender().freeze())
        } catch (error: Throwable) {
            onThrow(error.freeze())
        }
    }.freeze()
}

class FlowWrapper<T : Any>(
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
    ) = flow
        .onEach { onEach(it.freeze()) }
        .catch { onThrow(it.freeze()) } // catch{} before onCompletion{} or else completion hits rx first and ends stream
        .onCompletion { onComplete() }
        .launchIn(scope)
        .freeze()
}

class NullableFlowWrapper<T>(
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
    ) = flow
        .onEach { onEach(it.freeze()) }
        .catch { onThrow(it.freeze()) } // catch{} before onCompletion{} or else completion hits rx first and ends stream
        .onCompletion { onComplete() }
        .launchIn(scope)
        .freeze()
}
