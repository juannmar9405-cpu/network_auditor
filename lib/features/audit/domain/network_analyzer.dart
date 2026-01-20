import 'dart:math';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/services.dart';

// Modelo de datos para el resultado del escaneo
class AuditMetrics {
  final int rssi;
  final int avgLatency;
  final int jitter;
  final int packetLoss;
  final int linkSpeed;

  AuditMetrics({
    required this.rssi,
    required this.avgLatency,
    required this.jitter,
    required this.packetLoss,
    required this.linkSpeed,
  });
}

class NetworkAnalyzer {
  static const platform = MethodChannel('com.tuempresa.networkauditor/network');

  // 1. Obtener datos de Hardware (Capa Física)
  Future<Map<String, int>> getPhyLayerData() async {
    try {
      final Map result = await platform.invokeMethod('getNetworkData');
      return {
        'rssi': result['rssi'] ?? -100,
        'linkSpeed': result['linkSpeed'] ?? 0,
      };
    } catch (e) {
      return {'rssi': -100, 'linkSpeed': 0};
    }
  }

  // 2. Obtener datos de Transporte (Active Probing)
  // Hacemos pings a Google DNS (8.8.8.8) para testear salida a internet
  Future<Map<String, int>> runActiveProbe() async {
    // Config: 5 pings
    final ping = Ping('8.8.8.8', count: 5);
    List<int> latencies = [];
    int lostPackets = 0;
    int totalSent = 0;

    await for (final event in ping.stream) {
      if (event.response != null) {
        if (event.response!.time != null) {
          latencies.add(event.response!.time!.inMilliseconds);
        }
      }
      if (event.error != null) lostPackets++; // Error técnico cuenta como pérdida
    }
    
    // Si no hubo respuesta, asumimos pérdida total
    if (latencies.isEmpty) return {'latency': 999, 'jitter': 999, 'loss': 100};

    // Calcular Jitter (Desviación estándar de la latencia)
    double mean = latencies.reduce((a, b) => a + b) / latencies.length;
    double variance = latencies.map((val) => pow(val - mean, 2)).reduce((a, b) => a + b) / latencies.length;
    int jitter = sqrt(variance).toInt();
    
    // Packet Loss %
    // Nota: dart_ping a veces no reporta el totalSent en el stream directo, simplificamos:
    int lossPercent = (lostPackets > 0) ? 100 : 0; 
    // (Para una app real, compararíamos enviados vs recibidos)

    return {
      'latency': mean.toInt(),
      'jitter': jitter,
      'loss': lossPercent
    };
  }
}