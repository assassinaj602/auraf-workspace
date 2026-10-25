package com.auraf.telemetry

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.app.ActivityManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android Native Telemetry Plugin for AURAF.
 *
 * Dispatches low-level OS sensor queries to acquire:
 * - Real-time discharge current (mA)
 * - Battery / SoC temperature (°C)
 * - Available system RAM (MB)
 * - Process memory footprint (MB)
 * - Hardware device model string
 * - Active network condition
 */
class AurafTelemetryPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.auraf/telemetry")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "readDeviceSensors" -> {
                try {
                    val sensors = collectDeviceSensors()
                    result.success(sensors)
                } catch (e: Exception) {
                    result.error("TELEMETRY_ERROR", "Failed to sample device sensors: ${e.message}", null)
                }
            }
            "getDeviceModel" -> {
                result.success(getDeviceModelString())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    private fun collectDeviceSensors(): Map<String, Any> {
        val ctx = context ?: return emptyMap()

        // 1. Battery Telemetry via BatteryManager & Sticky Intent
        val batteryManager = ctx.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val batteryIntent = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

        // Battery Level Percentage (0 - 100)
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPercent: Int = if (level >= 0 && scale > 0) {
            ((level.toFloat() / scale.toFloat()) * 100).toInt()
        } else {
            batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: 50
        }

        // Instantaneous Current Draw in mA (Android returns microamperes: uA)
        val currentMicroAmps = batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW) ?: 0
        var currentMa = currentMicroAmps / 1000.0
        // Standardize: if discharging, current should be negative; if OEM returns positive during discharge, normalize
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        if (!isCharging && currentMa > 0) {
            currentMa = -currentMa
        }

        // Temperature in degrees Celsius (Android returns tenths of a °C: e.g. 335 = 33.5°C)
        val tempTenths = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val tempCelsius = tempTenths / 10.0

        // 2. Memory Telemetry via ActivityManager
        val activityManager = ctx.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager?.getMemoryInfo(memoryInfo)

        val availRamMb = memoryInfo.availMem / (1024.0 * 1024.0)
        val totalRamMb = memoryInfo.totalMem / (1024.0 * 1024.0)

        // Process allocated memory (PSS in MB)
        val pssKb = Debug.getPss()
        val peakMemMb = if (pssKb > 0) {
            pssKb / 1024.0
        } else {
            val runtime = Runtime.getRuntime()
            (runtime.totalMemory() - runtime.freeMemory()) / (1024.0 * 1024.0)
        }

        // 3. Network Condition
        val networkCondition = determineNetworkCondition(ctx)

        // 4. Device Model
        val deviceModel = getDeviceModelString()

        return mapOf(
            "timestamp" to System.currentTimeMillis(),
            "battery_level_percent" to batteryPercent,
            "battery_current_ma" to currentMa,
            "temperature_celsius" to tempCelsius,
            "available_ram_mb" to availRamMb,
            "total_ram_mb" to totalRamMb,
            "peak_memory_mb" to peakMemMb,
            "network_condition" to networkCondition,
            "device_model" to deviceModel
        )
    }

    private fun determineNetworkCondition(ctx: Context): String {
        val connectivityManager = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return "offline"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return "offline"
            val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return "offline"

            if (!capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                return "offline"
            }

            return when {
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "stable"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    // Check bandwidth as a proxy for high-latency / cellular
                    val downstream = capabilities.linkDownstreamBandwidthKbps
                    if (downstream in 1..2000) "high_latency" else "stable"
                }
                else -> "intermittent"
            }
        } else {
            @Suppress("DEPRECATION")
            val activeNetworkInfo = connectivityManager.activeNetworkInfo
            if (activeNetworkInfo == null || !activeNetworkInfo.isConnected) {
                return "offline"
            }
            return when (activeNetworkInfo.type) {
                ConnectivityManager.TYPE_WIFI -> "stable"
                ConnectivityManager.TYPE_MOBILE -> "high_latency"
                else -> "intermittent"
            }
        }
    }

    private fun getDeviceModelString(): String {
        val manufacturer = Build.MANUFACTURER.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        val model = Build.MODEL
        val androidVer = Build.VERSION.RELEASE
        return "${manufacturer}_${model}_Android_${androidVer}".replace(" ", "_")
    }
}

