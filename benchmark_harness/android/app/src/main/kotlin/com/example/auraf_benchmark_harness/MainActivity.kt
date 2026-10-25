package com.example.auraf_benchmark_harness

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Debug
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.auraf.runtime/telemetry"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "sampleDeviceState") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    val contextSize = call.argument<Int>("context_size_tokens")
                        ?: throw IllegalArgumentException("context_size_tokens is required")
                    val remainingBudget = call.argument<Double>("remaining_budget_usd")
                        ?: throw IllegalArgumentException("remaining_budget_usd is required")
                    if (contextSize < 0 || remainingBudget < 0) {
                        throw IllegalArgumentException("telemetry inputs must be non-negative")
                    }
                    result.success(sampleDeviceState(contextSize, remainingBudget))
                } catch (error: IllegalArgumentException) {
                    result.error("INVALID_ARGUMENT", error.message, null)
                } catch (error: Exception) {
                    result.error("TELEMETRY_ERROR", error.message, null)
                }
            }
    }

    private fun sampleDeviceState(
        contextSizeTokens: Int,
        remainingBudgetUsd: Double,
    ): Map<String, Any> {
        val battery = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        val batteryLevel = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val batteryScale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
        val batteryTemperature = battery?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
        val currentMicroAmps = batteryManager.getIntProperty(
            BatteryManager.BATTERY_PROPERTY_CURRENT_NOW,
        )
        val memory = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        memory.getMemoryInfo(memoryInfo)
        val network = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = network.activeNetwork
        val capabilities = activeNetwork?.let(network::getNetworkCapabilities)
        val networkCondition = when {
            capabilities == null -> "offline"
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> "stable"
            else -> "high_latency"
        }

        return mapOf(
            "timestamp" to System.currentTimeMillis(),
            "battery_level_percent" to (batteryLevel * 100 / batteryScale.coerceAtLeast(1)),
            "battery_current_ma" to currentMicroAmps / 1000.0,
            "temperature_celsius" to batteryTemperature / 10.0,
            "available_ram_mb" to memoryInfo.availMem / (1024.0 * 1024.0),
            "peak_memory_mb" to Debug.getPss() / 1024.0,
            "network_condition" to networkCondition,
            "context_size_tokens" to contextSizeTokens,
            "remaining_budget_usd" to remainingBudgetUsd,
        )
    }
}
