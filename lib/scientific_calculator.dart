import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // Para operaciones matemáticas adicionales como sqrt, pow, sin, cos
import 'package:intl/intl.dart'; // Para formateo de números

// ====================================================================
// ========================= MODELOS DE DATOS =========================
// ====================================================================

/// Clase para configurar las propiedades de un botón de la calculadora de expresiones.
class ButtonConfig {
  final String text;
  final Color? color;
  final Color textColor;
  final Function()? onPressed;
  final int flex;

  const ButtonConfig({
    required this.text,
    this.color,
    this.textColor = Colors.white,
    this.onPressed,
    this.flex = 1,
  });
}

/// Clase para representar una operación en el historial.
class HistoryEntry {
  final String calculationName; // Nombre del cálculo (ej. "Ley de Ohm", "Masa Molar", "Cálculo de Expresión")
  final String operation; // La expresión o descripción de la operación
  final String result; // El resultado final
  final Map<String, double>? inputs; // Los valores de entrada para poder recargar

  const HistoryEntry({
    required this.calculationName,
    required this.operation,
    required this.result,
    this.inputs,
  });
}

/// ---- Modelos para Cálculos Científicos Específicos (similar a tu ElectricCalculator) ----
class CampoCientifico {
  final String etiqueta;
  final String key;
  final String unidad;

  const CampoCientifico({
    required this.etiqueta,
    required this.key,
    required this.unidad,
  });
}

class CalculoCientifico {
  final String nombre;
  final String categoria; // Nueva: para agrupar en el Drawer
  final List<CampoCientifico> campos;
  final double Function(Map<String, double>) formula;
  final String descripcionFormula;
  final String unidadResultado;
  final String explicacionConcepto;
  final String Function(Map<String, double>, double)? operacionExplicada;
  final QuizQuestion? Function(Map<String, double> inputs, double result, NumberFormat formatter)? generateQuizQuestion;

  CalculoCientifico({
    required this.nombre,
    required this.categoria,
    required this.campos,
    required this.formula,
    required this.descripcionFormula,
    required this.unidadResultado,
    required this.explicacionConcepto,
    this.operacionExplicada,
    this.generateQuizQuestion,
  });
}

/// --- Clase: QuizQuestion ---
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });
}

// ====================================================================
// ======================== DEFINICIÓN DE CÁLCULOS ====================
// ====================================================================

// --- Helper para generar opciones de quiz (reutilizado de tu ElectricCalculator) ---
List<String> generateQuizOptions(double correctResult, List<double> incorrectOptionsRaw, String unit, NumberFormat formatter) {
  final Random random = Random();
  List<String> finalOptions = [];
  
  final String correctFormatted = '${formatter.format(correctResult)} $unit';
  finalOptions.add(correctFormatted);

  Set<String> uniqueDistractors = {};
  for (var opt in incorrectOptionsRaw) {
    if (opt.isFinite && !opt.isNaN) {
      String formattedOpt = '${formatter.format(opt)} $unit';
      if (formattedOpt != correctFormatted) {
        uniqueDistractors.add(formattedOpt);
      }
    }
  }

  int attempts = 0;
  while (uniqueDistractors.length < 3 && attempts < 20) {
    double variationFactor = 0.5 + random.nextDouble() * 1.5;
    double newDistractorValue = correctResult * variationFactor;

    if (correctResult.abs() < 0.001 && newDistractorValue.abs() < 0.001) {
        newDistractorValue = random.nextDouble() * 100 + 1;
    } else if (correctResult.isInfinite || correctResult.isNaN) {
        newDistractorValue = random.nextDouble() * 1000;
    }

    if (newDistractorValue.isFinite && !newDistractorValue.isNaN) {
      String formattedDistractor = '${formatter.format(newDistractorValue)} $unit';
      if (formattedDistractor != correctFormatted) {
        uniqueDistractors.add(formattedDistractor);
      }
    }
    attempts++;
  }

  finalOptions.addAll(uniqueDistractors.take(3));

  while (finalOptions.length < 4) {
    double fillerValue = correctResult + (random.nextDouble() - 0.5) * correctResult.abs() * 0.3 + 10;
    if (!fillerValue.isFinite || fillerValue.isNaN) {
      fillerValue = random.nextDouble() * 100;
    }
    String formattedFiller = '${formatter.format(fillerValue)} $unit';
    if (!finalOptions.contains(formattedFiller)) {
      finalOptions.add(formattedFiller);
    }
  }

  if (finalOptions.length > 4) {
      finalOptions.shuffle();
      finalOptions = finalOptions.take(4).toList();
      if (!finalOptions.contains(correctFormatted)) {
        finalOptions[0] = correctFormatted;
        finalOptions.shuffle();
      }
  }

  finalOptions.shuffle();
  return finalOptions;
}

// --- Lista de Consejos para "Sabías que...?" ---
final List<String> sabiasQueConsejosCientificos = [
  '¿Sabías que la velocidad de la luz en el vacío es aproximadamente 299,792,458 metros por segundo?',
  '¿Sabías que la Tierra se mueve alrededor del Sol a una velocidad de unos 30 kilómetros por segundo?',
  '¿Sabías que un año luz es la distancia que recorre la luz en un año, ¡aproximadamente 9.46 billones de kilómetros!?',
  '¿Sabías que el agua hierve a 100°C (212°F) a nivel del mar, pero a menor temperatura en altitudes elevadas?',
  '¿Sabías que el cero absoluto (-273.15°C o 0 Kelvin) es la temperatura más baja posible, donde las partículas no tienen energía térmica?',
  '¿Sabías que la masa no es lo mismo que el peso? La masa es la cantidad de materia, y el peso es la fuerza de la gravedad sobre esa masa.',
  '¿Sabías que el pH mide la acidez o alcalinidad de una solución, siendo 7 neutro, menos de 7 ácido y más de 7 alcalino?',
  '¿Sabías que la densidad es una propiedad que relaciona la masa de una sustancia con el volumen que ocupa?',
  '¿Sabías que el número de Avogadro (aproximadamente 6.022 x 10^23) es el número de partículas en un mol de cualquier sustancia?',
  '¿Sabías que la ley de conservación de la energía afirma que la energía no se crea ni se destruye, solo se transforma?',
  '¿Sabías que un Newton es la unidad de fuerza en el Sistema Internacional, definida como la fuerza necesaria para acelerar una masa de un kilogramo a un metro por segundo al cuadrado?',
  '¿Sabías que la gravedad en la Luna es aproximadamente un sexto de la gravedad terrestre?',
  '¿Sabías que la teoría de la relatividad de Einstein cambió nuestra comprensión del espacio, el tiempo, la gravedad y el universo?',
  '¿Sabías que la presión se define como la fuerza aplicada perpendicularmente a una superficie por unidad de área?',
  '¿Sabías que la temperatura es una medida de la energía térmica promedio de las partículas en una sustancia?',
  '¿Sabías que la conductividad eléctrica de un material es su capacidad para permitir el flujo de corriente eléctrica?',
  '¿Sabías que la velocidad del sonido en el aire es de aproximadamente 343 metros por segundo a 20°C?',
  '¿Sabías que el "punto triple" de una sustancia es la única combinación de presión y temperatura en la que los tres estados (sólido, líquido, gas) coexisten en equilibrio?',
  '¿Sabías que la fotosíntesis es el proceso por el cual las plantas convierten la luz solar, el agua y el dióxido de carbono en glucosa y oxígeno?',
  '¿Sabías que la reacción nuclear de fusión es la que alimenta el Sol y otras estrellas?',
];


// --- Definición de Cálculos Científicos Específicos ---
final List<CalculoCientifico> calculosCientificos = [
  // --- Química ---
  CalculoCientifico(
    nombre: 'Masa Molar',
    categoria: 'Química',
    campos: const [
      CampoCientifico(etiqueta: 'Átomos de H', key: 'H', unidad: ''),
      CampoCientifico(etiqueta: 'Átomos de C', key: 'C', unidad: ''),
      CampoCientifico(etiqueta: 'Átomos de O', key: 'O', unidad: ''),
    ],
    formula: (inputs) =>
        (inputs['H']! * 1.008) + // Masa atómica de H
        (inputs['C']! * 12.011) + // Masa atómica de C
        (inputs['O']! * 15.999), // Masa atómica de O
    descripcionFormula: 'Masa Molar = Σ (átomos × masa_atómica)',
    unidadResultado: 'g/mol',
    explicacionConcepto:
        'La masa molar es la masa de una mol de una sustancia. Se calcula sumando las masas atómicas de todos los átomos en la fórmula química. Aquí usamos un ejemplo simple con H, C y O.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.###', 'es_ES');
      return '(${formatter.format(inputs['H']!)} × 1.008) + (${formatter.format(inputs['C']!)} × 12.011) + (${formatter.format(inputs['O']!)} × 15.999)';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final H = inputs['H']!;
      final C = inputs['C']!;
      final O = inputs['O']!;
      final questionText = 'Calcula la masa molar de una molécula con ${formatter.format(H)} átomos de Hidrógeno, ${formatter.format(C)} de Carbono y ${formatter.format(O)} de Oxígeno (H=1.008, C=12.011, O=15.999 g/mol).';
      
      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(result * 0.9);
      incorrectOptionsRaw.add(result * 1.1);
      incorrectOptionsRaw.add((H * 1) + (C * 12) + (O * 16)); // Redondeado
      
      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'g/mol', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} g/mol');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La masa molar es la suma de las masas atómicas de cada elemento en la molécula.',
      );
    },
  ),
  CalculoCientifico(
    nombre: 'Ecuación de Gases Ideales',
    categoria: 'Química',
    campos: const [
      CampoCientifico(etiqueta: 'Moles (n)', key: 'n', unidad: 'mol'),
      CampoCientifico(etiqueta: 'Temperatura (T)', key: 'T', unidad: 'K'),
      CampoCientifico(etiqueta: 'Volumen (V)', key: 'V', unidad: 'L'),
    ],
    formula: (inputs) {
      const R = 0.0821; // Constante de los gases ideales en L·atm/(mol·K)
      if (inputs['V'] == 0) return double.infinity;
      return (inputs['n']! * R * inputs['T']!) / inputs['V']!;
    },
    descripcionFormula: 'P = nRT / V',
    unidadResultado: 'atm',
    explicacionConcepto:
        'La ecuación de gases ideales relaciona la presión, volumen, temperatura y cantidad de moles de un gas ideal. Es fundamental en termodinámica y química de gases.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      return 'P = (${formatter.format(inputs['n']!)} mol × 0.0821 × ${formatter.format(inputs['T']!)} K) / ${formatter.format(inputs['V']!)} L';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final n = inputs['n']!;
      final T = inputs['T']!;
      final V = inputs['V']!;
      const R = 0.0821;
      final questionText = 'Calcula la presión (P) de un gas ideal con ${formatter.format(n)} moles, una temperatura de ${formatter.format(T)} K, y un volumen de ${formatter.format(V)} L. (R=0.0821 L·atm/(mol·K))';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(n * R * T * V); // Multiplicación
      incorrectOptionsRaw.add(n + R + T + V); // Suma
      incorrectOptionsRaw.add((n * R * T) / (V * 2)); // Volumen duplicado
      incorrectOptionsRaw.add(result * 1.2); // Variación

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'atm', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} atm');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La ecuación de gases ideales es P = nRT / V.',
      );
    },
  ),

  // --- Física ---
  CalculoCientifico(
    nombre: 'Fuerza (Ley de Newton)',
    categoria: 'Física',
    campos: const [
      CampoCientifico(etiqueta: 'Masa', key: 'm', unidad: 'kg'),
      CampoCientifico(etiqueta: 'Aceleración', key: 'a', unidad: 'm/s²'),
    ],
    formula: (inputs) => inputs['m']! * inputs['a']!,
    descripcionFormula: 'F = m × a',
    unidadResultado: 'N',
    explicacionConcepto:
        'La segunda Ley de Newton establece que la fuerza neta aplicada sobre un objeto es directamente proporcional a su masa y a su aceleración. Es fundamental en la mecánica clásica.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      return 'F = ${formatter.format(inputs['m']!)} kg × ${formatter.format(inputs['a']!)} m/s²';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final m = inputs['m']!;
      final a = inputs['a']!;
      final questionText = '¿Cuál es la fuerza necesaria para acelerar un objeto de ${formatter.format(m)} kg a ${formatter.format(a)} m/s²?';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(m + a);
      incorrectOptionsRaw.add(m / a);
      incorrectOptionsRaw.add(result * 0.8);

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'N', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} N');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La fuerza (F) se calcula multiplicando la masa (m) por la aceleración (a): F = m × a.',
      );
    },
  ),
  CalculoCientifico(
    nombre: 'Energía Cinética',
    categoria: 'Física',
    campos: const [
      CampoCientifico(etiqueta: 'Masa', key: 'm', unidad: 'kg'),
      CampoCientifico(etiqueta: 'Velocidad', key: 'v', unidad: 'm/s'),
    ],
    formula: (inputs) => 0.5 * inputs['m']! * pow(inputs['v']!, 2),
    descripcionFormula: 'Ec = ½ m × v²',
    unidadResultado: 'J',
    explicacionConcepto:
        'La energía cinética es la energía que posee un objeto debido a su movimiento. Depende de la masa del objeto y de la magnitud de su velocidad al cuadrado.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      return 'Ec = 0.5 × ${formatter.format(inputs['m']!)} kg × (${formatter.format(inputs['v']!)} m/s)²';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final m = inputs['m']!;
      final v = inputs['v']!;
      final questionText = 'Calcula la energía cinética de un objeto de ${formatter.format(m)} kg que se mueve a una velocidad de ${formatter.format(v)} m/s.';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(m * v);
      incorrectOptionsRaw.add(0.5 * m * v);
      incorrectOptionsRaw.add(result * 1.5);

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'J', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} J');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La energía cinética (Ec) se calcula como la mitad de la masa (m) por la velocidad (v) al cuadrado: Ec = ½ m × v².',
      );
    },
  ),

  // --- Geometría ---
  CalculoCientifico(
    nombre: 'Área de Círculo',
    categoria: 'Geometría',
    campos: const [
      CampoCientifico(etiqueta: 'Radio', key: 'r', unidad: 'cm'),
    ],
    formula: (inputs) => pi * pow(inputs['r']!, 2),
    descripcionFormula: 'Área = π × r²',
    unidadResultado: 'cm²',
    explicacionConcepto:
        'Calcula el área de un círculo dado su radio. El área es la medida de la superficie encerrada por la circunferencia.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      return 'Área = π × (${formatter.format(inputs['r']!)} cm)²';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final r = inputs['r']!;
      final questionText = 'Calcula el área de un círculo con un radio de ${formatter.format(r)} cm.';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(2 * pi * r); // Circunferencia
      incorrectOptionsRaw.add(pi * r);
      incorrectOptionsRaw.add(result / 2);

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'cm²', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} cm²');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'El área de un círculo (A) se calcula como pi (π) por el radio (r) al cuadrado: A = π × r².',
      );
    },
  ),
  CalculoCientifico(
    nombre: 'Volumen de Esfera',
    categoria: 'Geometría',
    campos: const [
      CampoCientifico(etiqueta: 'Radio', key: 'r', unidad: 'cm'),
    ],
    formula: (inputs) => (4 / 3) * pi * pow(inputs['r']!, 3),
    descripcionFormula: 'Volumen = (4/3) × π × r³',
    unidadResultado: 'cm³',
    explicacionConcepto:
        'Calcula el volumen de una esfera, que es la cantidad de espacio tridimensional que ocupa. Depende del radio de la esfera al cubo.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      return 'Volumen = (4/3) × π × (${formatter.format(inputs['r']!)} cm)³';
    },
    generateQuizQuestion: (inputs, result, formatter) {
      final r = inputs['r']!;
      final questionText = 'Calcula el volumen de una esfera con un radio de ${formatter.format(r)} cm.';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(4 * pi * pow(r, 2)); // Área de superficie
      incorrectOptionsRaw.add(pi * pow(r, 2)); // Área de círculo
      incorrectOptionsRaw.add(result * 0.75);

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'cm³', formatter);
      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} cm³');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'El volumen de una esfera (V) se calcula como (4/3) por pi (π) por el radio (r) al cubo: V = (4/3) × π × r³.',
      );
    },
  ),
  // Aquí puedes añadir más cálculos para otras ciencias:
  // - Biología (ej. Concentración de solución, tasa de crecimiento)
  // - Astronomía (ej. Ley de Hubble, Ley de Kepler)
  // - Economía (ej. Interés compuesto, Tasa de crecimiento)
];


// ====================================================================
// ==================== WIDGETS DE LA APLICACIÓN ====================
// ====================================================================

/// Clase principal de la aplicación de la calculadora científica.
class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Científica Profesional',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey.shade50, // Fondo suave para los nuevos módulos
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.deepPurple.shade400,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        listTileTheme: ListTileThemeData( // Theme for Drawer ListTiles
          iconColor: Colors.deepPurple,
          textColor: Colors.black87,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: Colors.white,
        ),
      ),
      home: const ScientificCalculatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScientificCalculatorHome extends StatefulWidget {
  const ScientificCalculatorHome({super.key});

  @override
  State<ScientificCalculatorHome> createState() => _ScientificCalculatorHomeState();
}

class _ScientificCalculatorHomeState extends State<ScientificCalculatorHome> {
  final GlobalKey<ScientificCalculationWidgetState> _currentCalcWidgetKey = GlobalKey<ScientificCalculationWidgetState>();
  final GlobalKey<ExpressionCalculatorWidgetState> _expressionCalcWidgetKey = GlobalKey<ExpressionCalculatorWidgetState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // La lista de historial es compartida
  final List<HistoryEntry> _history = [];

  // El cálculo científico específico seleccionado. Null significa que la calculadora de expresiones está activa.
  CalculoCientifico? _selectedScientificCalculation;

  @override
  void initState() {
    super.initState();
    // No seleccionamos un cálculo específico al inicio, la calculadora de expresiones es por defecto.
  }

  /// Cambia el cálculo científico actual o vuelve a la calculadora de expresiones.
  void _selectCalculation(CalculoCientifico? newCalculation) {
    setState(() {
      _selectedScientificCalculation = newCalculation;
    });
    _scaffoldKey.currentState?.closeDrawer(); // Cierra el Drawer después de seleccionar
  }

  /// Agrega una entrada al historial.
  void _addHistoryEntry(HistoryEntry entry) {
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 50) { // Un historial un poco más grande
        _history.removeLast();
      }
    });
  }

  /// Carga un cálculo del historial en la pantalla principal.
  void _loadCalculationFromHistory(HistoryEntry entry) {
    _scaffoldKey.currentState?.closeEndDrawer(); // Cierra el historial
    setState(() {
      // Buscar si el cálculo del historial es uno de los científicos específicos
      final targetCalc = calculosCientificos.firstWhereOrNull(
          (calc) => calc.nombre == entry.calculationName);

      if (targetCalc != null) {
        // Es un cálculo científico específico, lo seleccionamos
        _selectedScientificCalculation = targetCalc;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Cargamos los inputs en el widget correspondiente
          _currentCalcWidgetKey.currentState?.loadInputs(entry.inputs ?? {});
        });
      } else {
        // Es una operación de la calculadora de expresiones, la cargamos allí
        _selectedScientificCalculation = null; // Vuelve a la calculadora de expresiones
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _expressionCalcWidgetKey.currentState?.loadExpression(entry.operation);
        });
      }
    });
  }

  /// Limpia todo el historial.
  void _clearHistory() {
    setState(() {
      _history.clear();
    });
    _scaffoldKey.currentState?.closeEndDrawer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial limpiado correctamente.')),
    );
  }

  // --- Navegación a pantallas de Ejercicios/Cuestionarios ---
  void _navigateToExerciseGenerator() {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ExerciseGeneratorScreen()),
    );
  }

  void _navigateToQuizGenerator() {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar cálculos por categoría para el Drawer
    final Map<String, List<CalculoCientifico>> categorizedCalculos = {};
    for (var calc in calculosCientificos) {
      categorizedCalculos.putIfAbsent(calc.categoria, () => []).add(calc);
    }

    return Scaffold(
      key: _scaffoldKey, // Asigna la clave al Scaffold para controlar ambos Drawers
      appBar: AppBar(
        title: Text(_selectedScientificCalculation?.nombre ?? 'Calculadora Científica'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menú de Cálculos',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Historial',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      // --- DRAWER IZQUIERDO: Selección de Cálculos ---
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Menú de Cálculos',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona una herramienta',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Opción para la calculadora de expresiones básica
                  ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('Calculadora de Expresiones'),
                    selected: _selectedScientificCalculation == null,
                    onTap: () => _selectCalculation(null),
                  ),
                  const Divider(),
                  // Categorías de cálculos científicos
                  ...categorizedCalculos.keys.map((category) {
                    return ExpansionTile(
                      leading: _getCategoryIcon(category), // Icono para la categoría
                      title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: categorizedCalculos[category]!.map((calc) {
                        return ListTile(
                          title: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(calc.nombre),
                          ),
                          selected: _selectedScientificCalculation == calc,
                          onTap: () => _selectCalculation(calc),
                          dense: true,
                        );
                      }).toList(),
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('Generar Ejercicio', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: _navigateToExerciseGenerator,
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz),
                    title: const Text('Generar Cuestionario', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: _navigateToQuizGenerator,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- DRAWER DERECHO: Historial ---
      endDrawer: Drawer(
        backgroundColor: Colors.grey.shade50,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Historial de Cálculos',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toca un elemento para cargarlo',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: HistorialWidget(
                historial: _history,
                onItemTap: _loadCalculationFromHistory, // Usa la nueva función de carga
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Limpiar Historial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
      // --- BODY DINÁMICO: Muestra la calculadora de expresiones o un cálculo específico ---
      body: _selectedScientificCalculation == null
          ? ExpressionCalculatorWidget(
              key: _expressionCalcWidgetKey, // Asigna una clave única
              globalHistory: _history, // Pasa el historial global
              onCalculate: (expression, result, inputs) {
                _addHistoryEntry(HistoryEntry(
                  calculationName: 'Expresión', // Nombre fijo para el historial
                  operation: expression,
                  result: result,
                  inputs: inputs, // Puede ser null para calculadora de expresiones
                ));
              },
            )
          : ScientificCalculationWidget(
              key: _currentCalcWidgetKey, // Asigna una clave única
              calculo: _selectedScientificCalculation!,
              onCalculate: (calcName, operation, result, inputs) {
                _addHistoryEntry(HistoryEntry(
                  calculationName: calcName,
                  operation: operation,
                  result: result,
                  inputs: inputs,
                ));
              },
            ),
    );
  }

  // Helper para obtener un icono para cada categoría del Drawer
  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'Química':
        return const Icon(Icons.science);
      case 'Física':
        return const Icon(Icons.flash_on);
      case 'Geometría':
        return const Icon(Icons.straighten);
      // case 'Biología': return const Icon(Icons.biotech); // Agrega más según tus categorías
      default:
        return const Icon(Icons.category);
    }
  }
}

// ====================================================================
// ============ WIDGET PARA LA CALCULADORA DE EXPRESIONES =============
// ====================================================================

/// Este widget encapsula la lógica de la calculadora científica original (la de botones).
class ExpressionCalculatorWidget extends StatefulWidget {
  final Function(String expression, String result, Map<String, double>? inputs) onCalculate;
  final List<HistoryEntry> globalHistory; // Añade esto para recibir el historial global

  const ExpressionCalculatorWidget({
    super.key,
    required this.onCalculate,
    required this.globalHistory, // Y esto al constructor
  });

  @override
  State<ExpressionCalculatorWidget> createState() => ExpressionCalculatorWidgetState();
}

class ExpressionCalculatorWidgetState extends State<ExpressionCalculatorWidget>
    with SingleTickerProviderStateMixin {
  String _currentInput = '';
  String _result = '0';
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Nuevo método para cargar expresiones desde el historial
  void loadExpression(String expression) {
    setState(() {
      _currentInput = expression;
      _result = '0'; // Reiniciar el resultado, se calculará si se pulsa '='
      _hasError = false;
    });
  }

  /// Gestiona la lógica cuando se presiona un botón de número u operador.
  void _onButtonPressed(String value) {
    setState(() {
      _hasError = false;
      if (_isOperator(value) &&
          _currentInput.isNotEmpty &&
          _isOperator(_currentInput[_currentInput.length - 1])) {
        if (value == '-' && _currentInput[_currentInput.length - 1] != '-') {
          _currentInput += value;
        } else {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1) + value;
        }
      } else {
        _currentInput += value;
      }
    });
  }

  /// Verifica si un string es un operador matemático.
  bool _isOperator(String s) {
    return '+-*/×÷^'.contains(s);
  }

  /// Realiza el cálculo de la expresión en pantalla.
  void _calculateResult() {
    try {
      String expressionString = _currentInput
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt')
          .replaceAll('log', 'log10')
          .replaceAll('ln', 'log')
          .replaceAll('e', 'e');

      expressionString = expressionString
          .replaceAllMapped(RegExp(r'(sin|cos|tan|log|sqrt)(\d+(\.\d+)?)'), (match) {
        return '${match.group(1)}(${match.group(2)})';
      });

      Parser p = Parser();
      Expression exp = p.parse(expressionString);
      ContextModel cm = ContextModel();

      cm.bindVariable(Variable('pi'), Number(3.1415926535));
      cm.bindVariable(Variable('e'), Number(2.7182818284));

      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        String formattedResult = eval
            .toStringAsFixed(10)
            .replaceAll(RegExp(r'\.0+$'), '')
            .replaceAll(RegExp(r'0+$'), '');

        widget.onCalculate(_currentInput, formattedResult, null); // Reportar al padre
        _result = formattedResult;
        _currentInput = _result;
        _hasError = false;
        _animationController.forward(from: 0);
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
        _hasError = true;
      });
    }
  }

  /// Limpia la pantalla de la calculadora.
  void _clearAll() {
    setState(() {
      _currentInput = '';
      _result = '0';
      _hasError = false;
    });
  }

  /// Borra el último carácter de la entrada.
  void _deleteLast() {
    setState(() {
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        if (_currentInput.isEmpty) {
          _result = '0';
        }
      }
    });
  }

  /// Construye un widget de botón para la calculadora.
  Widget _buildCalculatorButton(ButtonConfig config) {
    return Expanded(
      flex: config.flex,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: config.color ?? Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({MaterialState.selected}),
            foregroundColor: config.textColor,
          ),
          onPressed: config.onPressed ?? () => _onButtonPressed(config.text),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              config.text,
              style: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({MaterialState.selected}),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<List<ButtonConfig>> buttonRows = [
      [
        ButtonConfig(text: 'sin(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: 'cos(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: 'tan(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: 'log(', color: Colors.deepPurple.shade700),
      ],
      [
        ButtonConfig(text: 'ln(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: '√(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: '^', color: Colors.deepPurple.shade700),
        ButtonConfig(text: 'π', color: Colors.deepPurple.shade700),
      ],
      [
        ButtonConfig(text: '(', color: Colors.deepPurple.shade700),
        ButtonConfig(text: ')', color: Colors.deepPurple.shade700),
        ButtonConfig(text: 'C', color: Colors.red.shade800, onPressed: _clearAll),
        ButtonConfig(text: 'DEL', color: Colors.orange.shade800, onPressed: _deleteLast),
      ],
      [
        ButtonConfig(text: '7'),
        ButtonConfig(text: '8'),
        ButtonConfig(text: '9'),
        ButtonConfig(text: '÷', color: Colors.indigo.shade700),
      ],
      [
        ButtonConfig(text: '4'),
        ButtonConfig(text: '5'),
        ButtonConfig(text: '6'),
        ButtonConfig(text: '×', color: Colors.indigo.shade700),
      ],
      [
        ButtonConfig(text: '1'),
        ButtonConfig(text: '2'),
        ButtonConfig(text: '3'),
        ButtonConfig(text: '-', color: Colors.indigo.shade700),
      ],
      [
        ButtonConfig(text: '0', flex: 2),
        ButtonConfig(text: '.'),
        ButtonConfig(text: '=', color: Colors.green.shade700, onPressed: _calculateResult),
        ButtonConfig(text: '+', color: Colors.indigo.shade700),
      ],
    ];

    return Column(
      children: [
        // --- PANTALLA DE ENTRADA Y RESULTADO ---
        // Se ha cambiado a SizedBox.expand para una altura más controlada
        // y permitir desplazamiento vertical del teclado.
        SizedBox( // Usamos SizedBox para una altura controlada, eliminando Expanded
          height: MediaQuery.of(context).size.height * 0.22, // Ajusta esta altura según sea necesario
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Historial de operaciones dentro del display
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: widget.globalHistory.length, // Usa el historial global del widget padre
                      itemBuilder: (context, index) {
                        final entry = widget.globalHistory[index];
                        // Solo muestra las entradas de "Expresión" aquí
                        if (entry.calculationName == 'Expresión') {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  entry.operation, // 'operation' contiene la expresión
                                  style: const TextStyle(
                                    fontSize: 14, // Fuente más pequeña para historial
                                    color: Colors.white54,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '= ${entry.result}',
                                  style: const TextStyle(
                                    fontSize: 16, // Fuente más pequeña para resultado de historial
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2), // Espacio entre entradas de historial
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // No muestra otras entradas
                      },
                    ),
                  ),
                ),
                // Input actual y resultado de la calculadora de expresiones
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _currentInput.isEmpty ? '0' : _currentInput,
                    style: TextStyle(
                      fontSize: _currentInput.length > 20 ? 26 : 32, // Reducido ligeramente
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Espacio más pequeño
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 42, // Reducido de 48
                      fontWeight: FontWeight.bold,
                      color: _hasError ? Colors.redAccent : Colors.lightGreenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // --- BOTONES DE LA CALCULADORA ---
        Expanded( // Envuelve los botones en Expanded para que se ajusten al espacio restante
          child: SingleChildScrollView( // Permite el desplazamiento si los botones no caben
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[900],
              child: Column(
                children: buttonRows.map((row) {
                  return Padding( // Agregamos Padding alrededor de cada fila
                    padding: const EdgeInsets.symmetric(vertical: 4.0), // Menos espacio vertical entre filas
                    child: Row(
                      children: row.map((buttonConfig) {
                        return _buildCalculatorButton(buttonConfig);
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================================
// ============ WIDGET PARA CÁLCULOS CIENTÍFICOS ESPECÍFICOS ===========
// ====================================================================

/// Este widget es para los cálculos específicos (Química, Física, Geometría, etc.)
class ScientificCalculationWidget extends StatefulWidget {
  final CalculoCientifico calculo;
  final Function(String calcName, String operation, String result, Map<String, double> inputs) onCalculate;

  const ScientificCalculationWidget({
    super.key,
    required this.calculo,
    required this.onCalculate,
  });

  @override
  State<ScientificCalculationWidget> createState() => ScientificCalculationWidgetState();
}

class ScientificCalculationWidgetState extends State<ScientificCalculationWidget> {
  final Map<String, TextEditingController> controllers = {};
  String operacionCalculada = 'Operación';
  String resultadoFinalDisplay = '0';
  bool isErrorState = false;

  final NumberFormat _numberFormatter = NumberFormat('#,##0.####', 'es_ES');
  final NumberFormat _inputFormatter = NumberFormat('#,##0.##', 'es_ES');
  final Random _random = Random();
  String _currentSabiasQue = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _updateDisplayDefaults();
    _loadNewSabiasQue();
  }

  @override
  void didUpdateWidget(covariant ScientificCalculationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calculo != oldWidget.calculo) {
      _disposeControllers();
      _initializeControllers();
      _clearFields(); // Usamos _clearFields para limpiar campos y resultados
      _updateDisplayDefaults();
      _loadNewSabiasQue();
    }
  }

  void _initializeControllers() {
    for (var campo in widget.calculo.campos) {
      controllers[campo.key] = TextEditingController();
    }
  }

  void _disposeControllers() {
    for (var c in controllers.values) {
      c.dispose();
    }
    controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _updateDisplayDefaults() {
    setState(() {
      resultadoFinalDisplay = '0 ${widget.calculo.unidadResultado}';
      operacionCalculada = 'Operación';
      isErrorState = false;
    });
  }

  void _loadNewSabiasQue() {
    setState(() {
      _currentSabiasQue = sabiasQueConsejosCientificos[_random.nextInt(sabiasQueConsejosCientificos.length)];
    });
  }

  void loadInputs(Map<String, double> inputsToLoad) {
    _clearFields(); // Limpiar antes de cargar nuevos valores
    setState(() {
      for (var entry in inputsToLoad.entries) {
        if (controllers.containsKey(entry.key)) {
          controllers[entry.key]?.text = _inputFormatter.format(entry.value);
        }
      }
      _calculateSpecific(); // Recalcular con los inputs cargados automáticamente
    });
  }

  void _calculateSpecific() {
    Map<String, double> inputs = {};
    bool anyInputEmptyOrInvalid = false;

    for (var campo in widget.calculo.campos) {
      String text = controllers[campo.key]?.text ?? '';
      double? val = double.tryParse(text.replaceAll(',', '.'));
      if (text.isEmpty || val == null) {
        anyInputEmptyOrInvalid = true;
        break;
      } else {
        inputs[campo.key] = val;
      }
    }

    if (anyInputEmptyOrInvalid) {
      setState(() {
        resultadoFinalDisplay = 'Valores incompletos o inválidos.';
        operacionCalculada = '';
        isErrorState = true;
      });
      return;
    }

    try {
      double res = widget.calculo.formula(inputs);
      String currentOperacionText = widget.calculo.operacionExplicada != null
          ? widget.calculo.operacionExplicada!(inputs, res)
          : widget.calculo.descripcionFormula;

      setState(() {
        resultadoFinalDisplay = '${_numberFormatter.format(res)} ${widget.calculo.unidadResultado}';
        operacionCalculada = currentOperacionText;
        isErrorState = false;
      });

      widget.onCalculate(
        widget.calculo.nombre,
        '$currentOperacionText = ${_numberFormatter.format(res)} ${widget.calculo.unidadResultado}',
        resultadoFinalDisplay,
        inputs, // Pasar los inputs para poder recargar desde historial
      );
    } catch (e) {
      setState(() {
        resultadoFinalDisplay = 'Error de cálculo: ${e.toString()}';
        operacionCalculada = '';
        isErrorState = true;
      });
    }
  }

  void _clearFields() {
    for (var c in controllers.values) {
      c.clear();
    }
    _updateDisplayDefaults();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Padding inferior para permitir el desplazamiento con el teclado virtual
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      children: [
        // PANTALLA DE RESULTADO (ARRIBA)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.topRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.calculo.explicacionConcepto,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                  textAlign: TextAlign.start,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.calculo.descripcionFormula,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 8),
              Text(
                operacionCalculada,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              if (isErrorState)
                Text(
                  resultadoFinalDisplay,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.end,
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  resultadoFinalDisplay,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.end,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // FÓRMULAS Y BOTONES (ABAJO)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.calculo.campos.map(
                (campo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: controllers[campo.key],
                    decoration: InputDecoration(
                      labelText: '${campo.etiqueta} (${campo.unidad})',
                      prefixIcon: _getIconForUnit(campo.unidad),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    style: const TextStyle(fontSize: 18),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll('.', ',');
                        return newValue.copyWith(text: text, selection: newValue.selection);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateSpecific,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calcular'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _clearFields,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Sección "¿Sabías que...?" siempre al final del ListView
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 ¿Sabías que...?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSabiasQue,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper para obtener un icono según la unidad
  Icon _getIconForUnit(String unit) {
    switch (unit) {
      case 'mol':
        return const Icon(Icons.bubble_chart);
      case 'K':
        return const Icon(Icons.thermostat);
      case 'L':
        return const Icon(Icons.liquor);
      case 'atm':
        return const Icon(Icons.compress);
      case 'kg':
        return const Icon(Icons.scale);
      case 'm/s²':
        return const Icon(Icons.speed);
      case 'N':
        return const Icon(Icons.sports_baseball);
      case 'm/s':
        return const Icon(Icons.directions_run);
      case 'J':
        return const Icon(Icons.power);
      case 'cm':
        return const Icon(Icons.straighten);
      case 'cm²':
        return const Icon(Icons.square_foot);
      case 'cm³':
        return const Icon(Icons.cable); // Corregido el icono aquí
      default:
        return const Icon(Icons.input);
    }
  }
}

// ====================================================================
// ========================= WIDGET DE HISTORIAL ======================
// ====================================================================

class HistorialWidget extends StatelessWidget {
  final List<HistoryEntry> historial;
  final Function(HistoryEntry) onItemTap;

  const HistorialWidget({
    super.key,
    required this.historial,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade700),
            const SizedBox(height: 10),
            const Text(
              'No hay cálculos recientes',
              style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: historial.length,
      itemBuilder: (context, index) {
        final item = historial[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.grey.shade800, // Fondo oscuro para los elementos del historial
          child: InkWell(
            onTap: () => onItemTap(item),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.calculationName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurpleAccent.shade100),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Operación: ${item.operation}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Resultado: ${item.result}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ====================================================================
// =================== WIDGET GENERADOR DE EJERCICIOS =================
// ====================================================================

class ExerciseGeneratorScreen extends StatefulWidget {
  const ExerciseGeneratorScreen({super.key});

  @override
  State<ExerciseGeneratorScreen> createState() => _ExerciseGeneratorScreenState();
}

class _ExerciseGeneratorScreenState extends State<ExerciseGeneratorScreen> {
  final Random _random = Random();
  String _currentExercise = 'Toca "Generar Ejercicio" para comenzar.';
  String _currentAnswer = '';
  bool _showAnswer = false;

  final NumberFormat _valueFormatter = NumberFormat('###.##', 'es_ES');

  void _generateExercise() {
    _showAnswer = false;
    // Filtra cálculos que son adecuados para ejercicios aleatorios simples.
    // Excluir cálculos que no tienen sentido para generar al azar o son demasiado complejos.
    final availableCalculos = calculosCientificos.where((c) =>
        c.campos.length <= 3 && // Limitar a 3 campos para simplicidad
        c.nombre != 'Impedancia RLC Serie (Z)' && // Complejidad de CA
        c.nombre != 'Ángulo de Fase (φ)' && // Requiere atan2, más complejo
        c.nombre != 'Factor de Potencia (FP)' // Requiere coseno de ángulo
    ).toList();

    if (availableCalculos.isEmpty) {
      setState(() {
        _currentExercise = 'No hay ejercicios disponibles para generar.';
        _currentAnswer = '';
      });
      return;
    }

    final selectedCalculo = availableCalculos[_random.nextInt(availableCalculos.length)];
    final Map<String, double> inputs = {};

    String problemText = 'Problema de ${selectedCalculo.nombre}:\n\n';

    try {
      for (var campo in selectedCalculo.campos) {
        double value;
        // Rango de valores razonable para cada unidad
        switch (campo.unidad) {
          case 'mol': value = _random.nextDouble() * 5 + 0.1; break; // 0.1 a 5.1 mol
          case 'K': value = _random.nextDouble() * 200 + 273.15; break; // 273.15K a 473.15K (0C a 200C)
          case 'L': value = _random.nextDouble() * 50 + 1; break; // 1 a 51 L
          case 'kg': value = _random.nextDouble() * 20 + 0.5; break; // 0.5 a 20.5 kg
          case 'm/s²': value = _random.nextDouble() * 10 + 0.5; break; // 0.5 a 10.5 m/s²
          case 'm/s': value = _random.nextDouble() * 50 + 1; break; // 1 a 51 m/s
          case 'cm': value = _random.nextDouble() * 20 + 1; break; // 1 a 21 cm
          case 'g/mol': value = _random.nextDouble() * 100 + 10; break; // para masa molar si fuera input
          case 'V': value = _random.nextDouble() * 230 + 10; break; // 10V a 240V (si tuvieras electricos aqui)
          default: value = _random.nextDouble() * 100 + 1; break;
        }
        
        // Manejo especial para Masas Atómicas si fueran inputs:
        if (campo.key == 'H') value = _random.nextInt(5) + 1.0; // 1 a 5 átomos
        if (campo.key == 'C') value = _random.nextInt(5) + 1.0;
        if (campo.key == 'O') value = _random.nextInt(5) + 1.0;

        problemText += '- ${campo.etiqueta}: ${_valueFormatter.format(value)} ${campo.unidad}\n';
        inputs[campo.key] = value;
      }

      final result = selectedCalculo.formula(inputs);
      problemText += '\nCalcula ${selectedCalculo.nombre}.';

      String answerText = selectedCalculo.operacionExplicada != null
          ? selectedCalculo.operacionExplicada!(inputs, result)
          : selectedCalculo.descripcionFormula;

      answerText += ' = ${_valueFormatter.format(result)} ${selectedCalculo.unidadResultado}';

      setState(() {
        _currentExercise = problemText;
        _currentAnswer = 'Solución: $answerText';
      });
    } catch (e) {
      setState(() {
        _currentExercise = 'Error al generar ejercicio para ${selectedCalculo.nombre}: $e';
        _currentAnswer = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Ejercicios'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _currentExercise,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateExercise,
              icon: const Icon(Icons.refresh),
              label: const Text('Generar Nuevo Ejercicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            if (_currentExercise != 'Toca "Generar Ejercicio" para comenzar.' && _currentExercise.isNotEmpty && !(_currentExercise.startsWith('Error')))
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                icon: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility),
                label: Text(_showAnswer ? 'Ocultar Solución' : 'Mostrar Solución'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAnswer ? Colors.orange.shade700 : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            if (_showAnswer)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _currentAnswer,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ====================== WIDGET DE CUESTIONARIO ======================
// ====================================================================

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizQuestion? _currentQuizQuestion;
  int? _selectedOptionIndex;
  bool _feedbackShown = false;
  bool _isCorrect = false;

  final Random _random = Random();
  final NumberFormat _valueFormatter = NumberFormat('###.##', 'es_ES');

  @override
  void initState() {
    super.initState();
    _generateQuizQuestion();
  }

  void _generateQuizQuestion() {
    _selectedOptionIndex = null;
    _feedbackShown = false;
    _isCorrect = false;

    final quizAvailableCalculos = calculosCientificos.where((c) => c.generateQuizQuestion != null).toList();

    if (quizAvailableCalculos.isEmpty) {
      setState(() {
        _currentQuizQuestion = QuizQuestion(
          questionText: 'No hay preguntas de cuestionario disponibles.',
          options: ['N/A'],
          correctAnswerIndex: 0,
        );
      });
      return;
    }

    QuizQuestion? generatedQuestion;
    int attempts = 0;
    while (generatedQuestion == null && attempts < 20) { // Aumentar intentos para robustez
      final selectedCalculo = quizAvailableCalculos[_random.nextInt(quizAvailableCalculos.length)];
      final Map<String, double> inputs = {};

      for (var campo in selectedCalculo.campos) {
        double value;
        // Rango de valores razonable para cada unidad
        switch (campo.unidad) {
          case 'mol': value = _random.nextDouble() * 5 + 0.1; break;
          case 'K': value = _random.nextDouble() * 200 + 273.15; break;
          case 'L': value = _random.nextDouble() * 50 + 1; break;
          case 'kg': value = _random.nextDouble() * 20 + 0.5; break;
          case 'm/s²': value = _random.nextDouble() * 10 + 0.5; break;
          case 'm/s': value = _random.nextDouble() * 50 + 1; break;
          case 'cm': value = _random.nextDouble() * 20 + 1; break;
          case '': // Para átomos de H, C, O
             value = (_random.nextInt(5) + 1).toDouble(); // De 1 a 5 átomos
             break;
          default: value = _random.nextDouble() * 100 + 1; break;
        }
        inputs[campo.key] = value;
      }

      try {
        bool inputsAreValidForFormula = true;
        for (var campo in selectedCalculo.campos) {
          if (inputs[campo.key] == 0 && (selectedCalculo.descripcionFormula.contains('/') || selectedCalculo.descripcionFormula.contains('tan'))) {
            // Evita divisiones por cero problemáticas o tan(90)
            inputsAreValidForFormula = false;
            break;
          }
        }

        if (inputsAreValidForFormula) {
          final result = selectedCalculo.formula(inputs);
          if (result.isFinite && !result.isNaN) {
            generatedQuestion = selectedCalculo.generateQuizQuestion!(inputs, result, _valueFormatter);
            if (generatedQuestion != null && (generatedQuestion!.options.isEmpty || generatedQuestion!.correctAnswerIndex == -1 || generatedQuestion!.options.length < 4)) {
              generatedQuestion = null;
            }
          }
        }
      } catch (e) {
        generatedQuestion = null;
      }
      attempts++;
    }

    setState(() {
      if (generatedQuestion != null) {
        _currentQuizQuestion = generatedQuestion;
      } else {
        _currentQuizQuestion = QuizQuestion(
          questionText: 'No se pudo generar una pregunta válida después de varios intentos. Intenta de nuevo o revisa las fórmulas.',
          options: ['N/A'],
          correctAnswerIndex: 0,
          explanation: 'Es posible que algunas combinaciones de valores o fórmulas no permitan generar preguntas válidas.',
        );
      }
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una opción.')),
      );
      return;
    }

    setState(() {
      _feedbackShown = true;
      _isCorrect = (_selectedOptionIndex == _currentQuizQuestion!.correctAnswerIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuestionario Científico'),
        centerTitle: true,
      ),
      body: _currentQuizQuestion == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pregunta:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentQuizQuestion!.questionText,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._currentQuizQuestion!.options.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String option = entry.value;
                    bool isSelected = _selectedOptionIndex == idx;
                    bool showCorrectness = _feedbackShown;
                    bool isCorrectOption = idx == _currentQuizQuestion!.correctAnswerIndex;

                    Color tileColor = Colors.white;
                    if (showCorrectness) {
                      if (isCorrectOption) {
                        tileColor = Colors.green.shade100;
                      } else if (isSelected && !isCorrectOption) {
                        tileColor = Colors.red.shade100;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: tileColor,
                      elevation: 1,
                      child: RadioListTile<int>(
                        value: idx,
                        groupValue: _selectedOptionIndex,
                        onChanged: _feedbackShown ? null : (int? value) {
                          setState(() {
                            _selectedOptionIndex = value;
                          });
                        },
                        title: Text(option),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  if (!_feedbackShown)
                    ElevatedButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check),
                      label: const Text('Verificar Respuesta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (_feedbackShown)
                    Column(
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCorrect ? '¡Correcto!' : 'Incorrecto.',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                                if (_currentQuizQuestion!.explanation != null && _currentQuizQuestion!.explanation!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _currentQuizQuestion!.explanation!,
                                    style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _generateQuizQuestion,
                          icon: const Icon(Icons.next_plan),
                          label: const Text('Siguiente Pregunta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// --- Extensión para List para `firstWhereOrNull` ---
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}