// package com.example.mqtt_demo

// import android.os.Build
// import android.os.SystemClock
// import android.system.Os
// import android.system.OsConstants
// import android.util.Log
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.io.RandomAccessFile

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.mqtt_demo/performance"

//     // A simpler data class to hold only the necessary stats
//     private data class CpuTime(val wallClockTimeMs: Long, val appCpuTimeJiffies: Long)

//     private var lastCpuTime: CpuTime? = null

//     // *** UPDATED PART ***
//     // Lazily initialize the system's clock tick rate (USER_HZ).
//     // This is the number of clock ticks per second.
//     // android.system.Os.sysconf() is available on API 21+
//     // We fall back to the common value of 100 if the call fails.
//     private val clockTicksPerSecond: Long by lazy {
//         try {
//             if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
//                 Os.sysconf(OsConstants._SC_CLK_TCK)
//             } else {
//                 // A common fallback for older devices.
//                 100L
//             }
//         } catch (e: Exception) {
//             Log.e("CPU_MONITOR", "Could not read clock ticks per second, falling back to 100.", e)
//             100L
//         }
//     }

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             when (call.method) {
//                 "getCpuUsage" -> {
//                     val currentCpuTime = getCpuStats()

//                     if (lastCpuTime != null && currentCpuTime != null) {
//                         val wallClockDiffMs = (currentCpuTime.wallClockTimeMs - lastCpuTime!!.wallClockTimeMs).toFloat()
//                         val appCpuDiffJiffies = (currentCpuTime.appCpuTimeJiffies - lastCpuTime!!.appCpuTimeJiffies).toFloat()

//                         // *** UPDATED CALCULATION ***
//                         // Convert jiffies to milliseconds using the actual system clock tick rate.
//                         // Formula: time_in_ms = (jiffies * 1000) / ticks_per_second
//                         val appCpuTimeMs = (appCpuDiffJiffies * 1000) / clockTicksPerSecond

//                         var appUsagePercent = 0.0f
//                         if (wallClockDiffMs > 0) {
//                             // This calculates the app's usage against a single core.
//                             // It can go > 100% if the app is multi-threaded across cores.
//                             appUsagePercent = (appCpuTimeMs / wallClockDiffMs) * 100.0f
//                         }

//                         Log.d("CPU_MONITOR", "App Usage: $appUsagePercent% (Clock Ticks/sec: $clockTicksPerSecond)")

//                         // We can only reliably provide app usage, so that's all we send.
//                         // Cap at 800% for an 8-core phone as a reasonable upper limit.
//                         result.success(mapOf(
//                             "app" to appUsagePercent.coerceIn(0f, 800f).toDouble()
//                         ))

//                     } else {
//                         // Not enough data yet, return 0. The next call will have data.
//                         result.success(mapOf("app" to 0.0))
//                     }
//                     // Store the current reading for the next calculation
//                     lastCpuTime = currentCpuTime
//                 }
//                 "getAppMemoryUsageMB" -> {
//                     try {
//                         val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
//                         val pid = android.os.Process.myPid()
//                         val memInfo = activityManager.getProcessMemoryInfo(intArrayOf(pid))[0]
//                         val memMb = memInfo.totalPss / 1024.0 // Convert from KB to MB
//                         result.success(memMb)
//                     } catch (e: Exception) {
//                         result.error("MEMORY_ERROR", "Failed to get memory usage", e.localizedMessage)
//                     }
//                 }
//                 else -> result.notImplemented()
//             }
//         }
//     }

//     // This function remains correct as it only fetches the raw data.
//     private fun getCpuStats(): CpuTime? {
//         return try {
//             val pid = android.os.Process.myPid()
//             val appReader = RandomAccessFile("/proc/$pid/stat", "r")
//             val appLine = appReader.readLine()
//             appReader.close()
//             val appParts = appLine.split(" ")

//             // utime (index 13) + stime (index 14) = total app cpu time in "jiffies"
//             val appCpuJiffies = appParts[13].toLong() + appParts[14].toLong()

//             // Get the current "wall-clock" time.
//             val wallClockMs = SystemClock.elapsedRealtime()

//             CpuTime(wallClockTimeMs = wallClockMs, appCpuTimeJiffies = appCpuJiffies)
//         } catch (e: Exception) {
//             Log.e("CPU_MONITOR", "Could not read app's CPU stats.", e)
//             null
//         }
//     }
// }

// package com.example.mqtt_demo // Use your actual package name

// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.io.File
// import java.lang.Exception

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.mqtt_demo/filesystem_explorer"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             val path = call.argument<String>("path")
//             if (path == null) {
//                 result.error("INVALID_ARGS", "File path argument is missing", null)
//                 return@setMethodCallHandler
//             }

//             when (call.method) {
//                 "getProcFileContent" -> {
//                     try {
//                         val content = File(path).readText()
//                         result.success(content)
//                     } catch (e: Exception) {
//                         result.error("ACCESS_DENIED", "Could not read file '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 "listDirectoryWithPermissions" -> {
//                     try {
//                         val directory = File(path)
//                         val files = directory.listFiles()

//                         if (files == null) {
//                             result.error("NOT_A_DIRECTORY", "Path '$path' is not a directory or an I/O error occurred.", null)
//                             return@setMethodCallHandler
//                         }

//                         // Create a list of maps with detailed info. This part is correct.
//                         val fileDetailsList = files.map { file ->
//                             mapOf(
//                                 "name" to file.name,
//                                 "path" to file.path,
//                                 "isDirectory" to file.isDirectory,
//                                 "canRead" to file.canRead(),
//                                 "canWrite" to file.canWrite(),
//                                 "canExecute" to file.canExecute()
//                             )
//                         }
//                         result.success(fileDetailsList)

//                     } catch (e: Exception) {
//                         result.error("ACCESS_DENIED", "Could not list directory '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 else -> result.notImplemented()
//             }
//         }
//     }
// }


// package com.example.mqtt_demo // Use your actual package name

// import android.util.Log
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.io.File
// import java.lang.Exception

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.mqtt_demo/filesystem_explorer"
//     private val LOG_TAG = "FileSystemExplorer" // Define a log tag for easy filtering

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             val path = call.argument<String>("path")
//             if (path == null) {
//                 result.error("INVALID_ARGS", "File path argument is missing", null)
//                 return@setMethodCallHandler
//             }

//             when (call.method) {
//                 "getProcFileContent" -> {
//                     Log.d(LOG_TAG, "Attempting to read file: $path")
//                     try {
//                         val content = File(path).readText()
//                         Log.d(LOG_TAG, "Successfully read file: $path")
//                         result.success(content)
//                     } catch (e: Exception) {
//                         Log.e(LOG_TAG, "Failed to read file: $path", e)
//                         result.error("ACCESS_DENIED", "Could not read file '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 "listDirectoryWithPermissions" -> {
//                     Log.d(LOG_TAG, "Attempting to list directory: $path")
//                     try {
//                         val directory = File(path)
//                         val files = directory.listFiles()

//                         if (files == null) {
//                             Log.w(LOG_TAG, "Path is not a directory or I/O error for: $path")
//                             result.error("NOT_A_DIRECTORY", "Path '$path' is not a directory or an I/O error occurred.", null)
//                             return@setMethodCallHandler
//                         }

//                         // *** ADDED LOGGING ***
//                         Log.d(LOG_TAG, "Found ${files.size} items in directory: $path")

//                         val fileDetailsList = files.map { file ->
//                             mapOf(
//                                 "name" to file.name,
//                                 "path" to file.path,
//                                 "isDirectory" to file.isDirectory,
//                                 "canRead" to file.canRead(),
//                                 "canWrite" to file.canWrite(),
//                                 "canExecute" to file.canExecute()
//                             )
//                         }
//                         result.success(fileDetailsList)

//                     } catch (e: Exception) {
//                         Log.e(LOG_TAG, "Failed to list directory: $path", e)
//                         result.error("ACCESS_DENIED", "Could not list directory '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 else -> result.notImplemented()
//             }
//         }
//     }
// }

// package com.example.mqtt_demo // Make sure this matches your package name

// import android.util.Log
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.io.File
// import java.lang.Exception

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.mqtt_demo/filesystem_explorer"
//     private val LOG_TAG = "FileSystemExplorer" // Define a log tag for easy filtering

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             val path = call.argument<String>("path")
//             if (path == null) {
//                 result.error("INVALID_ARGS", "File path argument is missing", null)
//                 return@setMethodCallHandler
//             }

//             when (call.method) {
//                 "getProcFileContent" -> {
//                     Log.d(LOG_TAG, "Attempting to read file: $path")
//                     try {
//                         val content = File(path).readText()
//                         Log.d(LOG_TAG, "Successfully read file: $path")
//                         result.success(content)
//                     } catch (e: Exception) {
//                         Log.e(LOG_TAG, "Failed to read file: $path", e)
//                         result.error("ACCESS_DENIED", "Could not read file '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 "listDirectoryWithPermissions" -> {
//                     Log.d(LOG_TAG, "Attempting to list directory: $path")
//                     try {
//                         val directory = File(path)
//                         val files = directory.listFiles()

//                         if (files == null) {
//                             Log.w(LOG_TAG, "Path is not a directory or I/O error for: $path")
//                             result.error("NOT_A_DIRECTORY", "Path '$path' is not a directory or an I/O error occurred.", null)
//                             return@setMethodCallHandler
//                         }

//                         Log.d(LOG_TAG, "Found ${files.size} items in directory: $path")

//                         val fileDetailsList = files.map { file ->
//                             mapOf(
//                                 "name" to file.name,
//                                 "path" to file.path,
//                                 "isDirectory" to file.isDirectory,
//                                 "canRead" to file.canRead(),
//                                 "canWrite" to file.canWrite(),
//                                 "canExecute" to file.canExecute()
//                             )
//                         }
//                         result.success(fileDetailsList)

//                     } catch (e: Exception) {
//                         Log.e(LOG_TAG, "Failed to list directory: $path", e)
//                         result.error("ACCESS_DENIED", "Could not list directory '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 else -> result.notImplemented()
//             }
//         }
//     }
// }

// package com.example.mqtt_demo // Make sure this matches your package name

// import android.app.ActivityManager
// import android.content.Context
// import android.net.TrafficStats
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.io.File
// import java.lang.Exception

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.mqtt_demo/performance"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             when (call.method) {
//                 // A single, efficient call to get all raw performance counters at once.
//                 "getPerformanceMetrics" -> {
//                     val metrics = mutableMapOf<String, Long>()
//                     val uid = android.os.Process.myUid() // Get our app's unique User ID for TrafficStats

//                     // --- App CPU Time ---
//                     // Reads /proc/self/stat, which is reliable for an app's own process.
//                     try {
//                         val pid = android.os.Process.myPid()
//                         val appLine = File("/proc/$pid/stat").readText()
//                         val appParts = appLine.split(" ")
//                         // Sum of user time (utime, 14th field) and kernel time (stime, 15th field).
//                         val appCpuJiffies = appParts[13].toLong() + appParts[14].toLong()
//                         metrics["cpuJiffies"] = appCpuJiffies
//                     } catch (e: Exception) { /* Fails silently if file is unreadable */ }

//                     // --- App Disk I/O ---
//                     // Reads /proc/self/io, also reliable for an app's own process.
//                     try {
//                         val pid = android.os.Process.myPid()
//                         File("/proc/$pid/io").forEachLine {
//                             when {
//                                 it.startsWith("rchar:") -> metrics["diskReadBytes"] = it.substring(7).trim().toLong()
//                                 it.startsWith("wchar:") -> metrics["diskWriteBytes"] = it.substring(7).trim().toLong()
//                             }
//                         }
//                     } catch (e: Exception) { /* Fails silently */ }

//                     // --- App Network I/O ---
//                     // Uses the official, Google-supported TrafficStats API.
//                     // This is the correct way and works for both local Wi-Fi and internet.
//                     metrics["netRxBytes"] = TrafficStats.getUidRxBytes(uid) // Received bytes
//                     metrics["netTxBytes"] = TrafficStats.getUidTxBytes(uid) // Transmitted bytes

//                     result.success(metrics)
//                 }

//                 // A separate call for memory since it uses Android's official ActivityManager API.
//                 "getAppMemoryUsageMB" -> {
//                     try {
//                         val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
//                         val pid = android.os.Process.myPid()
//                         val memInfo = activityManager.getProcessMemoryInfo(intArrayOf(pid))[0]
//                         // Total PSS is a good measure of an app's proportional memory footprint.
//                         val memMb = memInfo.totalPss / 1024.0
//                         result.success(memMb)
//                     } catch (e: Exception) {
//                         result.error("MEMORY_ERROR", "Failed to get memory usage", e.localizedMessage)
//                     }
//                 }

//                 // --- Methods for the Filesystem Explorer ---
//                 "listDirectoryWithPermissions" -> {
//                     val path = call.argument<String>("path")!!
//                     try {
//                         val files = File(path).listFiles()
//                         if (files == null) {
//                             result.error("NOT_A_DIRECTORY", "Path '$path' is not a directory or an I/O error occurred.", null)
//                             return@setMethodCallHandler
//                         }
//                         val fileDetailsList = files.map { file ->
//                             mapOf(
//                                 "name" to file.name, "path" to file.path, "isDirectory" to file.isDirectory,
//                                 "canRead" to file.canRead(), "canWrite" to file.canWrite(), "canExecute" to file.canExecute()
//                             )
//                         }
//                         result.success(fileDetailsList)
//                     } catch (e: Exception) {
//                         result.error("ACCESS_DENIED", "Could not list directory '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 "getProcFileContent" -> {
//                     val path = call.argument<String>("path")!!
//                     try {
//                         result.success(File(path).readText())
//                     } catch (e: Exception) {
//                         result.error("ACCESS_DENIED", "Could not read file '$path'. Reason: ${e.message}", null)
//                     }
//                 }
//                 else -> result.notImplemented()
//             }
//         }
//     }
// }

package com.example.mqtt_demo // Make sure this matches your package name

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.system.Os
import android.system.OsConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.lang.Exception

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mqtt_demo/performance"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // --- ONE-TIME SETUP METHOD ---
                "getClockTicksPerSecond" -> {
                    // This is called once by the service to get an accurate value for CPU calculations.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        try {
                            // This gets the actual clock ticks per second from the OS.
                            val ticks = Os.sysconf(OsConstants._SC_CLK_TCK)
                            result.success(ticks)
                        } catch (e: Exception) {
                            // Fallback to the common value if the call fails for any reason.
                            result.success(100L)
                        }
                    } else {
                        // Fallback for older devices that don't support the API.
                        result.success(100L)
                    }
                }

                // --- REAL-TIME DATA METHODS ---
                "getBatteryDetails" -> {
                    val iFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                    val batteryStatus: Intent? = context.registerReceiver(null, iFilter)
                    if (batteryStatus != null) {
                        val level: Int = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                        val scale: Int = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                        // Calculate the battery percentage and return it as a simple integer.
                        val batteryPct = (level * 100 / scale.toFloat()).toInt()
                        result.success(batteryPct)
                    } else {
                        result.error("UNAVAILABLE", "Battery details not available.", null)
                    }
                }

                "getPerformanceMetrics" -> {
                    val metrics = mutableMapOf<String, Long>()
                    val uid = android.os.Process.myUid() // Get our app's unique User ID for TrafficStats

                    // --- App CPU Time ---
                    // Reads /proc/self/stat, which is reliable for an app's own process.
                    try {
                        val pid = android.os.Process.myPid()
                        val appLine = File("/proc/$pid/stat").readText()
                        val appParts = appLine.split(" ")
                        // Sum of user time (utime, 14th field) and kernel time (stime, 15th field).
                        val appCpuJiffies = appParts[13].toLong() + appParts[14].toLong()
                        metrics["cpuJiffies"] = appCpuJiffies
                    } catch (e: Exception) { /* Fails silently if file is unreadable */ }

                    // --- App Disk I/O ---
                    // Reads /proc/self/io, also reliable for an app's own process.
                    try {
                        val pid = android.os.Process.myPid()
                        File("/proc/$pid/io").forEachLine {
                            when {
                                it.startsWith("rchar:") -> metrics["diskReadBytes"] = it.substring(7).trim().toLong()
                                it.startsWith("wchar:") -> metrics["diskWriteBytes"] = it.substring(7).trim().toLong()
                            }
                        }
                    } catch (e: Exception) { /* Fails silently */ }

                    // --- App Network I/O ---
                    // Uses the official, Google-supported TrafficStats API.
                    // This is the correct way and works for both local Wi-Fi and internet.
                    metrics["netRxBytes"] = TrafficStats.getUidRxBytes(uid) // Received bytes
                    metrics["netTxBytes"] = TrafficStats.getUidTxBytes(uid) // Transmitted bytes

                    result.success(metrics)
                }

                "getAppMemoryUsageMB" -> {
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val pid = android.os.Process.myPid()
                        val memInfo = activityManager.getProcessMemoryInfo(intArrayOf(pid))[0]
                        // Total PSS is a good measure of an app's proportional memory footprint.
                        val memMb = memInfo.totalPss / 1024.0
                        result.success(memMb)
                    } catch (e: Exception) {
                        result.error("MEMORY_ERROR", "Failed to get memory usage", e.localizedMessage)
                    }
                }

                // --- METHODS FOR THE FILESYSTEM EXPLORER ---
                "listDirectoryWithPermissions" -> {
                    val path = call.argument<String>("path")!!
                    try {
                        val files = File(path).listFiles()
                        if (files == null) {
                            result.error("NOT_A_DIRECTORY", "Path '$path' is not a directory or an I/O error occurred.", null)
                            return@setMethodCallHandler
                        }
                        val fileDetailsList = files.map { file ->
                            mapOf(
                                "name" to file.name, "path" to file.path, "isDirectory" to file.isDirectory,
                                "canRead" to file.canRead(), "canWrite" to file.canWrite(), "canExecute" to file.canExecute()
                            )
                        }
                        result.success(fileDetailsList)
                    } catch (e: Exception) {
                        result.error("ACCESS_DENIED", "Could not list directory '$path'. Reason: ${e.message}", null)
                    }
                }

                "getProcFileContent" -> {
                    val path = call.argument<String>("path")!!
                    try {
                        result.success(File(path).readText())
                    } catch (e: Exception) {
                        result.error("ACCESS_DENIED", "Could not read file '$path'. Reason: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}