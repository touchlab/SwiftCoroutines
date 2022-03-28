package co.touchlab.example

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlin.native.concurrent.freeze

class ThingRepository {
    suspend fun getThing(succeed: Boolean): Thing {
        delay(100)
        if (succeed) {
            return Thing(0)
        } else {
            error("oh no!")
        }
    }

    fun getThingStream(count: Int, succeed: Boolean): Flow<Thing> = flow {
        repeat(count) {
            delay(100)
            emit(Thing(it))
        }
        if (!succeed) error("oops!")
    }

    suspend fun getNullableThing(succeed: Boolean): Thing? {
        delay(100)
        if (succeed) {
            return null
        } else {
            error("oh no!")
        }
    }

    fun getNullableThingStream(count: Int, succeed: Boolean): Flow<Thing?> = flow {
        repeat(count) {
            delay(100)
            emit(if (it % 2 == 0) Thing(it) else null)
        }
        if (!succeed) error("oops!")
    }
}

data class Thing(val count: Int) {
    init {
        freeze()
    }
}
