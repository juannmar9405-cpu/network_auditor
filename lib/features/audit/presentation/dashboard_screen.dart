import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Importamos nuestras clases de dominio (Asegúrate que las rutas sean correctas)
import '../domain/network_analyzer.dart';
import '../domain/solution_guide.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NetworkAnalyzer _analyzer = NetworkAnalyzer();
  Interpreter? _interpreter;
  
  // Estado
  bool isScanning = false;
  AuditMetrics? metrics;
  TechnicalSolution? solution;

  @override
  void initState() {
    super.initState();
    _loadModel();
    Permission.location.request();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/network_model.tflite');
    } catch (e) {
      print("Error modelo: $e");
    }
  }

  Future<void> startAudit() async {
    setState(() { isScanning = true; solution = null; });

    // 1. Recolectar Datos
    final phyData = await _analyzer.getPhyLayerData();
    final transData = await _analyzer.runActiveProbe();

    final currentMetrics = AuditMetrics(
      rssi: phyData['rssi']!,
      linkSpeed: phyData['linkSpeed']!,
      avgLatency: transData['latency']!,
      jitter: transData['jitter']!,
      packetLoss: transData['loss']!,
    );

    // 2. Inferencia IA
    int predictedClass = 0;
    if (_interpreter != null) {
      var input = [[
        currentMetrics.rssi.toDouble(),
        currentMetrics.jitter.toDouble(),
        currentMetrics.packetLoss.toDouble()
      ]];
      
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);
      _interpreter!.run(input, output);
      
      List<double> probs = output[0];
      predictedClass = probs.indexWhere((e) => e == probs.reduce((a, b) => a > b ? a : b));
    }

    // 3. Obtener Solución
    final finalSolution = KnowledgeBase.getSolutionForClass(predictedClass);

    setState(() {
      metrics = currentMetrics;
      solution = finalSolution;
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fondo con Gradiente Sutil (Modern Tech Feel)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildRadarSection(),
                      const SizedBox(height: 30),
                      if (metrics != null) _buildMetricsGrid(),
                      const SizedBox(height: 30),
                      if (solution != null) _buildSolutionCard(),
                      const SizedBox(height: 80), // Espacio para el botón flotante
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildScanButton(),
    );
  }

  // 1. Header Minimalista
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AUDITOR DE RED", style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 5),
              Text("Neural Scanner", style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.hub, color: Colors.cyanAccent),
          )
        ],
      ),
    );
  }

  // 2. Radar Central con Efecto de "Glow"
  Widget _buildRadarSection() {
    double signalPercent = 0;
    Color statusColor = Colors.grey;

    if (metrics != null) {
      signalPercent = (metrics!.rssi + 100) / 70;
      signalPercent = signalPercent.clamp(0.0, 1.0);
      statusColor = _getColorForSignal(metrics!.rssi);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Efecto de resplandor (Glow)
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isScanning ? Colors.cyan : statusColor).withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ],
          ),
        ),
        CircularPercentIndicator(
          radius: 90.0,
          lineWidth: 15.0,
          percent: isScanning ? 0.3 : signalPercent,
          animation: true,
          animationDuration: 1000,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isScanning ? Icons.sensors : Icons.wifi, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                isScanning ? "..." : "${metrics?.rssi ?? '--'}",
                style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text("dBm Signal", style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 12)),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.white10,
          progressColor: isScanning ? Colors.cyan : statusColor,
        ),
      ],
    );
  }

  // 3. Grid de Métricas con diseño "Glassmorphism"
  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TELEMETRÍA DE TRANSPORTE", style: GoogleFonts.robotoMono(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _metricCard("LATENCIA", "${metrics!.avgLatency}", "ms", Colors.blueAccent)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard("JITTER", "${metrics!.jitter}", "ms", metrics!.jitter > 30 ? Colors.orange : Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard("PÉRDIDA", "${metrics!.packetLoss}", "%", metrics!.packetLoss > 0 ? Colors.redAccent : Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, String unit, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8), // Semi-transparente
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Text(unit, style: GoogleFonts.robotoMono(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Tarjeta de Solución Inteligente
  Widget _buildSolutionCard() {
    Color cardColor;
    IconData statusIcon;
    
    // Psicología de color aplicada a la severidad
    if (solution!.severity == "OPTIMO") {
      cardColor = const Color(0xFF00C853); // Verde
      statusIcon = Icons.check_circle;
    } else if (solution!.severity == "ALERTA") {
      cardColor = const Color(0xFFFFAB00); // Ámbar
      statusIcon = Icons.warning_amber_rounded;
    } else {
      cardColor = const Color(0xFFFF1744); // Rojo
      statusIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: cardColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: cardColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DIAGNÓSTICO IA", style: GoogleFonts.robotoMono(color: cardColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(solution!.title, style: GoogleFonts.roboto(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(solution!.toolTip, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                Text("PROTOCOLOS RECOMENDADOS:", style: GoogleFonts.robotoMono(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...solution!.steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: cardColor, size: 20),
                      Expanded(child: Text(step, style: const TextStyle(color: Colors.white, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 5. Botón de Acción Moderno
  Widget _buildScanButton() {
    return Container(
      width: 200,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: -5)
        ]
      ),
      child: ElevatedButton(
        onPressed: isScanning ? null : startAudit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning) 
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            else 
              const Icon(Icons.radar),
            const SizedBox(width: 10),
            Text(isScanning ? "AUDITANDO..." : "ESCANEAR RED", style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getColorForSignal(int rssi) {
    if (rssi > -60) return const Color(0xFF00C853); // Excellent (Green)
    if (rssi > -75) return const Color(0xFFFFAB00); // Fair (Amber)
    return const Color(0xFFFF1744); // Poor (Red)
  }
}