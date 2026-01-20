class TechnicalSolution {
  final String title;
  final String severity;
  final List<String> steps;
  final String toolTip;

  TechnicalSolution({
    required this.title,
    required this.severity,
    required this.steps,
    required this.toolTip,
  });
}

class KnowledgeBase {
  static TechnicalSolution getSolutionForClass(int classIndex) {
    switch (classIndex) {
      case 0: // Red Saludable
        return TechnicalSolution(
          title: "Parámetros Nominales",
          severity: "OPTIMO",
          steps: ["No se requieren acciones correctivas.", "Documentar estado actual para referencia futura."],
          toolTip: "La red opera dentro de los estándares IEEE 802.11",
        );
      
      case 1: // Saturación / Interferencia (RSSI bueno, Jitter alto)
        return TechnicalSolution(
          title: "Saturación de Espectro / Co-Canal",
          severity: "ALERTA",
          steps: [
            "Realizar análisis de espectro para identificar APs vecinos.",
            "Cambiar canal del AP a uno no solapado (1, 6, 11 en 2.4GHz).",
            "Reducir ancho de canal de 40MHz a 20MHz si hay mucho ruido.",
            "Migrar dispositivos críticos a la banda de 5GHz."
          ],
          toolTip: "Detectada alta varianza (Jitter) pese a buena señal.",
        );

      case 2: // Cobertura Pobre (RSSI bajo)
        return TechnicalSolution(
          title: "Atenuación de Señal Excesiva",
          severity: "CRÍTICO",
          steps: [
            "Verificar obstáculos físicos (Muros de concreto, metal, agua).",
            "Reubicar el Router/AP a una posición central y elevada.",
            "Verificar orientación de antenas (Polarización vertical recomendada).",
            "Considerar instalación de Sistema Mesh o Repetidor cableado."
          ],
          toolTip: "RSSI inferior a -75dBm. Conexión inestable.",
        );

      case 3: // Fallo de Hardware / Cableado (Pérdida de paquetes)
        return TechnicalSolution(
          title: "Fallo de Transporte / Hardware",
          severity: "FALLA",
          steps: [
            "Verificar integridad del cable UTP/Fibra hacia el Router.",
            "Revisar conectores RJ45 (posible sulfatación o mal crimpado).",
            "Ping al Gateway local para descartar fallo de ISP.",
            "Reiniciar hardware de red para vaciar caché ARP/Tablas NAT."
          ],
          toolTip: "Pérdida de paquetes detectada. Problema físico probable.",
        );

      default:
        return TechnicalSolution(title: "Desconocido", severity: "?", steps: [], toolTip: "");
    }
  }
}