package com.tuempresa.network_auditor

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.tuempresa.networkauditor/network"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNetworkData") {
                val data = getNetworkMetrics()
                result.success(data)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getNetworkMetrics(): Map<String, Any> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo = wifiManager.connectionInfo
        
        // Datos básicos (En producción requerirían permisos de Location en Runtime)
        val rssi = wifiInfo.rssi // Intensidad en dBm
        val linkSpeed = wifiInfo.linkSpeed // Velocidad en Mbps
        val frequency = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            wifiInfo.frequency
        } else {
            0
        }

        return mapOf(
            "rssi" to rssi,
            "linkSpeed" to linkSpeed,
            "frequency" to frequency
        )
    }
}