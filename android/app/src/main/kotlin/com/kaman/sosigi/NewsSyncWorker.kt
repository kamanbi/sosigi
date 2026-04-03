package com.kaman.sosigi

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class NewsSyncWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        Log.i(LOG_TAG, "doWork() called. isStopped=$isStopped runAttemptCount=$runAttemptCount")
        if (isStopped) {
            Log.i(LOG_TAG, "doWork(): Worker already stopped, returning early.")
            return Result.success()
        }

        val completionLatch = CountDownLatch(1)
        val bootstrapLatch = CountDownLatch(1)
        val completionDeliveredRef = AtomicBoolean(false)
        val resultRef = AtomicReference(Result.retry())
        val bootstrapErrorRef = AtomicReference<Throwable?>(null)
        val flutterEngineRef = AtomicReference<FlutterEngine?>(null)
        val mainHandler = Handler(Looper.getMainLooper())

        mainHandler.post {
            Log.i(LOG_TAG, "mainHandler.post started, isStopped=$isStopped")
            if (isStopped) {
                Log.i(LOG_TAG, "Worker stopped before bootstrap, aborting.")
                bootstrapLatch.countDown()
                return@post
            }
            try {
                Log.i(LOG_TAG, "Starting FlutterLoader initialization...")
                val flutterLoader = FlutterInjector.instance().flutterLoader()
                flutterLoader.startInitialization(applicationContext)
                flutterLoader.ensureInitializationComplete(applicationContext, null)
                Log.i(LOG_TAG, "FlutterLoader initialized. Creating FlutterEngine...")

                val flutterEngine = FlutterEngine(applicationContext)
                flutterEngineRef.set(flutterEngine)
                GeneratedPluginRegistrant.registerWith(flutterEngine)

                val channel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    WORKER_CHANNEL,
                )
                channel.setMethodCallHandler { call, methodResult ->
                    when (call.method) {
                        "complete" -> {
                            val success = call.argument<Boolean>("success") ?: false
                            val message = call.argument<String>("message")
                            val error = call.argument<String>("error")
                            Log.i(LOG_TAG, "Dart complete callback: success=$success message=$message error=$error")
                            resultRef.set(if (success) Result.success() else Result.retry())
                            if (completionDeliveredRef.compareAndSet(false, true)) {
                                completionLatch.countDown()
                            }
                            try {
                                methodResult.success(null)
                            } catch (exception: Throwable) {
                                Log.e(
                                    LOG_TAG,
                                    "Failed to acknowledge the Dart completion callback.",
                                    exception,
                                )
                            }
                        }

                        else -> methodResult.notImplemented()
                    }
                }

                Log.i(LOG_TAG, "FlutterEngine created. Executing backgroundSyncMain...")
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        flutterLoader.findAppBundlePath(),
                        "package:sosigi/background/background_sync_entrypoint.dart",
                        "backgroundSyncMain",
                    ),
                )
                Log.i(LOG_TAG, "backgroundSyncMain entrypoint executed, waiting for completion...")
            } catch (exception: Throwable) {
                Log.e(LOG_TAG, "Failed to bootstrap Flutter background worker.", exception)
                bootstrapErrorRef.set(exception)
                resultRef.set(Result.retry())
                completionLatch.countDown()
            } finally {
                bootstrapLatch.countDown()
            }
        }

        return try {
            Log.i(LOG_TAG, "Waiting for Flutter bootstrap (timeout=${BOOTSTRAP_TIMEOUT_MINUTES}min)...")
            val bootstrapped = bootstrapLatch.await(BOOTSTRAP_TIMEOUT_MINUTES, TimeUnit.MINUTES)
            if (!bootstrapped || bootstrapErrorRef.get() != null) {
                if (!bootstrapped) {
                    Log.e(LOG_TAG, "Timed out waiting for Flutter bootstrap on the main thread.")
                } else {
                    Log.e(LOG_TAG, "Bootstrap error: ${bootstrapErrorRef.get()}")
                }
                return Result.retry()
            }

            Log.i(LOG_TAG, "Bootstrap succeeded. Waiting for Dart completion (timeout=${COMPLETION_TIMEOUT_MINUTES}min)...")
            val completed = completionLatch.await(COMPLETION_TIMEOUT_MINUTES, TimeUnit.MINUTES)
            if (completed) {
                Log.i(LOG_TAG, "Dart completed with result=${resultRef.get()}")
                resultRef.get()
            } else {
                Log.e(LOG_TAG, "Timed out waiting for Dart background completion callback.")
                Result.retry()
            }
        } catch (exception: Exception) {
            Log.e(LOG_TAG, "Unexpected worker execution failure.", exception)
            Result.retry()
        } finally {
            val flutterEngine = flutterEngineRef.get()
            if (flutterEngine != null) {
                val destroyLatch = CountDownLatch(1)
                val destroyErrorRef = AtomicReference<Throwable?>(null)
                mainHandler.post {
                    try {
                        flutterEngine.destroy()
                    } catch (exception: Throwable) {
                        destroyErrorRef.set(exception)
                    } finally {
                        destroyLatch.countDown()
                    }
                }
                val destroyed = destroyLatch.await(DESTROY_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                if (!destroyed) {
                    Log.e(LOG_TAG, "Timed out waiting to destroy FlutterEngine on the main thread.")
                }
                destroyErrorRef.get()?.let { exception ->
                    Log.e(LOG_TAG, "Failed while destroying FlutterEngine.", exception)
                }
            }
        }
    }

    companion object {
        const val WORKER_CHANNEL = "sosigi/background_sync_worker"
        private const val LOG_TAG = "NewsSyncWorker"
        private const val BOOTSTRAP_TIMEOUT_MINUTES = 1L
        private const val COMPLETION_TIMEOUT_MINUTES = 2L
        private const val DESTROY_TIMEOUT_SECONDS = 10L
    }
}
