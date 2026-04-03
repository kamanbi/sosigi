package com.kaman.sosigi

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object BackgroundSyncScheduler {
    private const val UNIQUE_WORK_NAME = "sosigi_background_news_sync"
    // Android periodic background work cannot reliably run below 15 minutes.
    private const val MIN_INTERVAL_MINUTES = 15L

    fun schedule(
        context: Context,
        intervalMinutes: Long,
        wifiOnly: Boolean,
    ) {
        val sanitizedIntervalMinutes =
            intervalMinutes.coerceAtLeast(MIN_INTERVAL_MINUTES)

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(
                if (wifiOnly) {
                    NetworkType.UNMETERED
                } else {
                    NetworkType.CONNECTED
                },
            )
            .build()

        val flexMinutes = (sanitizedIntervalMinutes / 2).coerceAtLeast(MIN_INTERVAL_MINUTES)

        val request = PeriodicWorkRequest.Builder(
            NewsSyncWorker::class.java,
            sanitizedIntervalMinutes,
            TimeUnit.MINUTES,
            flexMinutes,
            TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            UNIQUE_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context.applicationContext).cancelUniqueWork(
            UNIQUE_WORK_NAME,
        )
    }
}
