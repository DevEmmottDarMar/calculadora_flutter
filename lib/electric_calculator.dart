import 'package:flutter/material.dart';
import 'dart:math'; // Para pow, sin, cos
import 'package:intl/intl.dart'; // Importar el paquete intl para formateo de números
import 'package:flutter/services.dart'; // Importar para TextInputFormatter

void main() => runApp(const ElectricCalculatorApp());

class ElectricCalculatorApp extends StatelessWidget {
  const ElectricCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Eléctrica Profesional',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.blueGrey.shade50, // Fondo suave
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none, // Borde más sutil
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.blueGrey.shade400,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
      ),
      home: const ElectricCalculatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ElectricCalculatorHome extends StatefulWidget {
  const ElectricCalculatorHome({super.key});

  @override
  State<ElectricCalculatorHome> createState() => _ElectricCalculatorHomeState();
}

class _ElectricCalculatorHomeState extends State<ElectricCalculatorHome> {
  final GlobalKey<CalculoWidgetState> _calculoWidgetGlobalKey = GlobalKey<CalculoWidgetState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Para controlar ambos Drawers

  final List<Map<String, String>> _historial = [];
  late Calculo _selectedCalculo; // Para almacenar el cálculo seleccionado

  @override
  void initState() {
    super.initState();
    _selectedCalculo = calculos.first; // Inicializa con el primer cálculo por defecto
  }

  void _selectNewCalculation(Calculo newCalculo) {
    setState(() {
      _selectedCalculo = newCalculo;
    });
    _scaffoldKey.currentState?.closeDrawer(); // Cierra el Drawer después de seleccionar
  }

  void agregarHistorial(String titulo, String operacion, String resultado, Map<String, double> inputs) {
    setState(() {
      _historial.insert(0, {
        'titulo': titulo,
        'operacion': operacion,
        'resultado': resultado,
        'inputs': inputs.entries.map((e) => '${e.key}:${e.value.toString()}').join(';'),
      });
      if (_historial.length > 20) {
        _historial.removeLast();
      }
    });
  }

  void cargarCalculoDesdeHistorial(Map<String, String> historialItem) {
    _scaffoldKey.currentState?.closeEndDrawer(); // Cerrar el panel lateral del historial

    String titulo = historialItem['titulo'] ?? '';
    int calculoIndex = calculos.indexWhere((c) => c.nombre == titulo);

    if (calculoIndex != -1) {
      // 1. Cambiar el cálculo seleccionado en la pantalla principal
      setState(() {
        _selectedCalculo = calculos[calculoIndex];
      });

      // 2. Parsear los inputs serializados
      Map<String, double> inputsToLoad = {};
      String? inputsString = historialItem['inputs'];
      if (inputsString != null && inputsString.isNotEmpty) {
        inputsString.split(';').forEach((pair) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            inputsToLoad[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
          }
        });
      }

      // 3. Pasar los inputs al CalculoWidget actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculoWidgetGlobalKey.currentState?.loadInputs(inputsToLoad);
      });
    }
  }

  void refrescarHistorial() {
    setState(() {
      _historial.clear(); // Vacía completamente el historial
    });
    _scaffoldKey.currentState?.closeEndDrawer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial limpiado correctamente.')),
    );
  }

  // --- Nueva función para navegar al generador de ejercicios ---
  void _navigateToExerciseGenerator() {
    _scaffoldKey.currentState?.closeDrawer(); // Cierra el drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ExerciseGeneratorScreen()),
    );
  }

  // --- Nueva función para navegar al generador de cuestionarios ---
  void _navigateToQuizGenerator() {
    _scaffoldKey.currentState?.closeDrawer(); // Cierra el drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Asigna la clave al Scaffold para controlar ambos Drawers
      appBar: AppBar(
        title: Text(_selectedCalculo.nombre), // Muestra el nombre del cálculo actual
        centerTitle: true,
        leading: IconButton( // Botón para abrir el Drawer izquierdo
          icon: const Icon(Icons.menu),
          tooltip: 'Seleccionar Cálculo',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton( // Botón para abrir el EndDrawer derecho (historial)
            icon: const Icon(Icons.history),
            tooltip: 'Ver Historial',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      // Panel IZQUIERDO para SELECCIÓN de Cálculos
      drawer: Drawer(
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
                      'Menú Principal',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona una opción',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero, // Elimina el padding por defecto del ListView
                children: [
                  // --- Categoría: Cálculos Básicos ---
                  ExpansionTile(
                    leading: const Icon(Icons.electrical_services, color: Colors.blueGrey),
                    title: const Text('Cálculos Básicos', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      _buildDrawerItem(calculos[0]), // Ley de Ohm (I)
                      _buildDrawerItem(calculos[1]), // Potencia Eléctrica (P=VI)
                      _buildDrawerItem(calculos[2]), // Potencia Eléctrica (P=I²R)
                      _buildDrawerItem(calculos[3]), // Potencia Eléctrica (P=V²/R)
                    ],
                  ),
                  // --- Categoría: Circuitos ---
                  ExpansionTile(
                    leading: const Icon(Icons.share, color: Colors.blueGrey),
                    title: const Text('Circuitos', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      _buildDrawerItem(calculos[4]), // R_eq en Serie
                      _buildDrawerItem(calculos[5]), // R_eq en Paralelo
                      _buildDrawerItem(calculos[6]), // Divisor de Voltaje
                      _buildDrawerItem(calculos[7]), // Divisor de Corriente
                    ],
                  ),
                  // --- Categoría: Corriente Alterna (CA) ---
                  ExpansionTile(
                    leading: const Icon(Icons.waves, color: Colors.blueGrey),
                    title: const Text('Corriente Alterna (CA)', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      _buildDrawerItem(calculos[8]), // Reactancia Inductiva (XL)
                      _buildDrawerItem(calculos[9]), // Reactancia Capacitiva (XC)
                      _buildDrawerItem(calculos[10]), // Impedancia RLC Serie (Z)
                      _buildDrawerItem(calculos[11]), // Ángulo de Fase (φ)
                      _buildDrawerItem(calculos[12]), // Factor de Potencia (FP)
                      _buildDrawerItem(calculos[13]), // Potencia Aparente (S)
                      _buildDrawerItem(calculos[14]), // Potencia Activa (P=V·I·cosφ)
                      _buildDrawerItem(calculos[15]), // Potencia Reactiva (Q=V·I·sinφ)
                    ],
                  ),
                  // --- Categoría: Mediciones y Diagnóstico ---
                  ExpansionTile(
                    leading: const Icon(Icons.precision_manufacturing, color: Colors.blueGrey),
                    title: const Text('Mediciones y Diagnóstico', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      _buildDrawerItem(calculos[16]), // Resistencia de Cable
                      _buildDrawerItem(calculos[17]), // Energía Consumida (kWh)
                      // Aquí podrías añadir más cálculos relacionados con medidores
                    ],
                  ),
                  const Divider(), // Separador visual
                  // --- Categoría: Didáctico ---
                  ListTile(
                    leading: const Icon(Icons.school, color: Colors.blueGrey),
                    title: const Text('Generar Ejercicio', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: _navigateToExerciseGenerator,
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz, color: Colors.blueGrey), // Icono para el quiz
                    title: const Text('Generar Cuestionario', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: _navigateToQuizGenerator, // Navega al quiz
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Panel DERECHO para HISTORIAL
      endDrawer: Drawer(
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
                historial: _historial,
                onItemTap: cargarCalculoDesdeHistorial,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: refrescarHistorial,
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
      body: CalculoWidget( // El body siempre muestra el cálculo seleccionado
        key: _calculoWidgetGlobalKey, // Sigue usando el GlobalKey para comunicación
        calculo: _selectedCalculo,
        onCalcular: agregarHistorial,
      ),
    );
  }

  // Helper para construir elementos del Drawer
  Widget _buildDrawerItem(Calculo calculo) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0), // Indentación para sub-elementos
        child: Text(calculo.nombre),
      ),
      selected: _selectedCalculo == calculo,
      onTap: () {
        _selectNewCalculation(calculo);
      },
      dense: true, // Hace la lista un poco más compacta
    );
  }
}

// ---- Clases de Modelos de Cálculo (Con explicación y unidad de resultado) ----
class Calculo {
  final String nombre;
  final List<CampoEntrada> campos;
  final double Function(Map<String, double>) formula;
  final String descripcionFormula;
  final String unidadResultado;
  final String explicacionConcepto;
  final String Function(Map<String, double>, double)? operacionExplicada;
  final QuizQuestion? Function(Map<String, double> inputs, double result, NumberFormat formatter)? generateQuizQuestion; // Nueva para Quiz

  Calculo({
    required this.nombre,
    required this.campos,
    required this.formula,
    required this.descripcionFormula,
    required this.unidadResultado,
    required this.explicacionConcepto,
    this.operacionExplicada,
    this.generateQuizQuestion, // Añadir al constructor
  });
}

class CampoEntrada {
  final String etiqueta;
  final String key;
  final String unidad;

  const CampoEntrada({
    required this.etiqueta,
    required this.key,
    required this.unidad,
  });
}

// --- NUEVA CLASE: QuizQuestion ---
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

// ---- Lista de Consejos para "Sabías que...?" ---
final List<String> sabiasQueConsejos = [
  '¿Sabías que la corriente siempre busca el camino de menor resistencia?',
  '¿Sabías que un cortocircuito ocurre cuando la corriente toma un camino no deseado con muy poca resistencia?',
  '¿Sabías que la potencia se mide en Watts y representa la velocidad a la que se consume o produce energía?',
  '¿Sabías que un fusible es un dispositivo de seguridad que protege los circuitos de sobrecargas de corriente?',
  '¿Sabías que el factor de potencia ideal en un circuito de CA es 1 (o 100%), indicando un uso eficiente de la energía?',
  '¿Sabías que un capacitor almacena energía en un campo eléctrico y se opone a los cambios de voltaje?',
  '¿Sabías que un inductor almacena energía en un campo magnético y se opone a los cambios de corriente?',
  '¿Sabías que la Ley de Ohm es la base de la mayoría de los análisis de circuitos eléctricos?',
  '¿Sabías que la electricidad viaja a la velocidad de la luz, pero los electrones individuales se mueven mucho más lento?',
  '¿Sabías que la resistividad de un material mide su oposición al flujo de corriente eléctrica?',
  '¿Sabías que la corriente continua (DC) fluye en una sola dirección, mientras que la corriente alterna (AC) cambia de dirección periódicamente?',
  '¿Sabías que la impedancia es la "resistencia total" en un circuito de corriente alterna, incluyendo resistencia, reactancia inductiva y reactancia capacitiva?',
  '¿Sabías que un multímetro es una herramienta esencial para un técnico eléctrico, permitiendo medir voltaje, corriente y resistencia?',
  '¿Sabías que las pinzas amperimétricas permiten medir la corriente en un cable sin necesidad de cortar el circuito?',
  '¿Sabías que un diodo permite que la corriente fluya en una sola dirección, actuando como una válvula unidireccional?',
  '¿Sabías que el polo a tierra en una instalación eléctrica es una medida de seguridad vital para prevenir descargas eléctricas?',
  '¿Sabías que un transformador puede aumentar o disminuir el voltaje de la corriente alterna usando el principio de inducción electromagnética?',
  '¿Sabías que la frecuencia de la corriente alterna en la mayoría de los hogares es de 50 Hz o 60 Hz, dependiendo de la región?',
  '¿Sabías que el efecto Joule describe cómo la energía eléctrica se convierte en calor cuando la corriente fluye a través de una resistencia?',
  '¿Sabías que los circuitos en serie tienen una sola ruta para la corriente, mientras que los circuitos en paralelo tienen múltiples rutas?',
  '¿Sabías que un megóhmetro se utiliza para medir resistencias de aislamiento muy altas en cables y equipos eléctricos?',
  '¿Sabías que la potencia nominal de un electrodoméstico indica cuánta energía consume cuando está funcionando a plena capacidad?',
  '¿Sabías que una batería almacena energía química y la convierte en energía eléctrica a través de reacciones electroquímicas?',
  '¿Sabías que la ley de Kirchhoff de la corriente establece que la suma de las corrientes que entran a un nodo es igual a la suma de las corrientes que salen?',
  '¿Sabías que la ley de Kirchhoff del voltaje establece que la suma de las caídas de voltaje en un lazo cerrado es igual a la suma de las fuentes de voltaje en ese lazo?',
];


// --- Helper para generar opciones de quiz (corregido) ---
// (Eliminada la versión duplicada para evitar conflicto de nombres)

// ---- Definición de Cálculos (Actualizada con generateQuizQuestion) ----
final List<Calculo> calculos = [
  // --- Cálculos Básicos ---
  // 0. Ley de Ohm (I = V/R)
  Calculo(
    nombre: 'Ley de Ohm (I)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Resistencia', key: 'R', unidad: 'Ω'),
    ],
    formula: (inputs) => inputs['R'] == 0 ? double.infinity : inputs['V']! / inputs['R']!,
    descripcionFormula: 'I = V / R',
    unidadResultado: 'A',
    explicacionConcepto:
        'La Ley de Ohm establece la relación entre la corriente (I), el voltaje (V) y la resistencia (R) en un circuito eléctrico. Calcula la corriente que fluye a través de una resistencia cuando se le aplica un voltaje.',
    operacionExplicada: (inputs, res) =>
        'I = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V / ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R']!)} Ω',
    generateQuizQuestion: (inputs, result, formatter) { // Ahora recibe formatter
      final V = inputs['V']!;
      final R = inputs['R']!;
      final questionText =
          'Si un circuito tiene un Voltaje de ${formatter.format(V)} V y una Resistencia de ${formatter.format(R)} Ω, ¿Cuál es la Corriente (I)?';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(V * R); // V x R
      incorrectOptionsRaw.add(V + R); // V + R
      if (R != 0) incorrectOptionsRaw.add(V / (R * 2)); // R duplicada
      incorrectOptionsRaw.add(V * 2 / R); // V duplicado

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'A', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} A');
      if (correctAnswerIndex == -1) { // Fallback, si la correcta no está, algo salió mal
        return null; // Indica que no se pudo generar una pregunta válida
      }

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'Según la Ley de Ohm, la corriente (I) se calcula dividiendo el voltaje (V) por la resistencia (R): I = V / R.',
      );
    },
  ),
  // 1. Potencia Eléctrica (P = V × I)
  Calculo(
    nombre: 'Potencia Eléctrica (P=VI)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Corriente', key: 'I', unidad: 'A'),
    ],
    formula: (inputs) => inputs['V']! * inputs['I']!,
    descripcionFormula: 'P = V × I',
    unidadResultado: 'W',
    explicacionConcepto:
        'La potencia eléctrica es la cantidad de energía consumida o producida por unidad de tiempo. Esta fórmula es útil cuando conoces el voltaje aplicado y la corriente que fluye.',
    operacionExplicada: (inputs, res) =>
        'P = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A',
    generateQuizQuestion: (inputs, result, formatter) { // Ahora recibe formatter
      final V = inputs['V']!;
      final I = inputs['I']!;
      final questionText =
          'Si un dispositivo tiene un Voltaje de ${formatter.format(V)} V y una Corriente de ${formatter.format(I)} A, ¿Cuál es su Potencia (P)?';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(V + I);
      incorrectOptionsRaw.add(V / I);
      incorrectOptionsRaw.add(V * I * 0.5); // Variación
      incorrectOptionsRaw.add(V * I * 2); // Variación

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'W', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} W');
      if (correctAnswerIndex == -1) return null; // Fallback

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La potencia eléctrica (P) se calcula multiplicando el voltaje (V) por la corriente (I): P = V × I.',
      );
    },
  ),
  // 2. Potencia Eléctrica (P = I² × R)
  Calculo(
    nombre: 'Potencia Eléctrica (P=I²R)',
    campos: const [
      CampoEntrada(etiqueta: 'Corriente', key: 'I', unidad: 'A'),
      CampoEntrada(etiqueta: 'Resistencia', key: 'R', unidad: 'Ω'),
    ],
    formula: (inputs) => pow(inputs['I']!, 2) * inputs['R']!,
    descripcionFormula: 'P = I² × R',
    unidadResultado: 'W',
    explicacionConcepto:
        'Esta fórmula de potencia es ideal cuando conoces la corriente que atraviesa un componente y su resistencia. Muestra cómo la potencia disipada aumenta cuadráticamente con la corriente.',
    operacionExplicada: (inputs, res) =>
        'P = (${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A)² × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R']!)} Ω',
  ),
  // 3. Potencia Eléctrica (P = V² / R)
  Calculo(
    nombre: 'Potencia Eléctrica (P=V²/R)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Resistencia', key: 'R', unidad: 'Ω'),
    ],
    formula: (inputs) => inputs['R'] == 0 ? double.infinity : pow(inputs['V']!, 2) / inputs['R']!,
    descripcionFormula: 'P = V² / R',
    unidadResultado: 'W',
    explicacionConcepto:
        'Usa esta fórmula para calcular la potencia cuando el voltaje y la resistencia son los datos conocidos. Es común para elementos que transforman energía eléctrica en calor o luz.',
    operacionExplicada: (inputs, res) =>
        'P = (${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V)² / ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R']!)} Ω',
  ),
  // --- Cálculos de Circuitos ---
  // 4. Resistencia Equivalente en Serie
  Calculo(
    nombre: 'R_eq en Serie',
    campos: const [
      CampoEntrada(etiqueta: 'R1', key: 'R1', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'R2', key: 'R2', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'R3', key: 'R3', unidad: 'Ω'),
    ],
    formula: (inputs) {
      return (inputs['R1'] ?? 0) + (inputs['R2'] ?? 0) + (inputs['R3'] ?? 0);
    },
    descripcionFormula: 'R_eq = R1 + R2 + R3',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'En un circuito en serie, la resistencia total es simplemente la suma de las resistencias individuales. Esto significa que la corriente tiene un solo camino a seguir.',
    operacionExplicada: (inputs, res) =>
        'R_eq = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R1']!)} Ω + ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R2']!)} Ω + ${NumberFormat('#,##0.##', 'es_ES').format(inputs['R3']!)} Ω',
    generateQuizQuestion: (inputs, result, formatter) { // Ahora recibe formatter
      final R1 = inputs['R1']!;
      final R2 = inputs['R2']!;
      final R3 = inputs['R3'] ?? 0;
      final questionText =
          'Calcula la Resistencia Equivalente (R_eq) de un circuito en serie con ${formatter.format(R1)} Ω, ${formatter.format(R2)} Ω y ${formatter.format(R3)} Ω.';

      List<double> incorrectOptionsRaw = [];
      // Distractor: paralelo de las 3
      double sumInverse = 0;
      if (R1 != 0) sumInverse += 1 / R1;
      if (R2 != 0) sumInverse += 1 / R2;
      if (R3 != 0) sumInverse += 1 / R3;
      if (sumInverse != 0) incorrectOptionsRaw.add(1 / sumInverse);
      
      incorrectOptionsRaw.add(R1 + R2 - R3);
      incorrectOptionsRaw.add(R1 + R2); // Sin R3
      incorrectOptionsRaw.add(result * 1.5); // +-50%

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'Ω', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} Ω');
      if (correctAnswerIndex == -1) return null; // Fallback

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'En un circuito en serie, la resistencia equivalente es la suma directa de todas las resistencias: R_eq = R1 + R2 + R3.',
      );
    },
  ),
  // 5. Resistencia Equivalente en Paralelo
  Calculo(
    nombre: 'R_eq en Paralelo',
    campos: const [
      CampoEntrada(etiqueta: 'R1', key: 'R1', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'R2', key: 'R2', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'R3', key: 'R3', unidad: 'Ω'),
    ],
    formula: (inputs) {
      double sumInverse = 0;
      if (inputs['R1'] != null && inputs['R1']! != 0) sumInverse += 1 / inputs['R1']!;
      if (inputs['R2'] != null && inputs['R2']! != 0) sumInverse += 1 / inputs['R2']!;
      if (inputs['R3'] != null && inputs['R3']! != 0) sumInverse += 1 / inputs['R3']!;
      if (sumInverse == 0) return 0; // Evitar división por cero si todas son infinitas
      return 1 / sumInverse;
    },
    descripcionFormula: '1/R_eq = 1/R1 + 1/R2 + 1/R3',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'Para resistencias en paralelo, la inversa de la resistencia total es la suma de las inversas de las resistencias individuales. La corriente se divide entre los caminos.',
    operacionExplicada: (inputs, res) {
      final formatter = NumberFormat('#,##0.##', 'es_ES');
      String r1 = inputs['R1']! == 0 ? '∞' : '1/${formatter.format(inputs['R1']!)}';
      String r2 = inputs['R2']! == 0 ? '∞' : '1/${formatter.format(inputs['R2']!)}';
      String r3 = inputs['R3']! == 0 ? '∞' : '1/${formatter.format(inputs['R3']!)}';
      return '1/R_eq = $r1 + $r2 + $r3';
    },
    generateQuizQuestion: (inputs, result, formatter) { // Ahora recibe formatter
      final R1 = inputs['R1']!;
      final R2 = inputs['R2']!;
      final R3 = inputs['R3'] ?? 0;
      
      final questionText =
          'Calcula la Resistencia Equivalente (R_eq) de un circuito en paralelo con ${formatter.format(R1)} Ω, ${formatter.format(R2)} Ω y ${formatter.format(R3)} Ω.';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(R1 + R2 + R3); // Distractor: serie
      if (R1 != 0 && R2 != 0) incorrectOptionsRaw.add(R1 * R2 / (R1 + R2)); // Solo dos en paralelo
      incorrectOptionsRaw.add(result * 1.5); // Variación
      incorrectOptionsRaw.add(result / 2); // Variación

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'Ω', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} Ω');
      if (correctAnswerIndex == -1) return null; // Fallback

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'En un circuito en paralelo, la inversa de la resistencia equivalente es la suma de las inversas de las resistencias: 1/R_eq = 1/R1 + 1/R2 + 1/R3.',
      );
    },
  ),
  // 6. Divisor de Voltaje
  Calculo(
    nombre: 'Divisor de Voltaje',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje Total', key: 'Vt', unidad: 'V'),
      CampoEntrada(etiqueta: 'Resistencia a Medir', key: 'Rm', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Resistencia Total (Serie)', key: 'Rt', unidad: 'Ω'),
    ],
    formula: (inputs) => inputs['Rt'] == 0 ? double.infinity : (inputs['Vt']! * inputs['Rm']!) / inputs['Rt']!,
    descripcionFormula: 'Vm = Vt × (Rm / Rt)',
    unidadResultado: 'V',
    explicacionConcepto:
        'El divisor de voltaje permite calcular el voltaje que cae a través de una resistencia específica en un circuito en serie, cuando se conoce el voltaje total y las resistencias.',
    operacionExplicada: (inputs, res) =>
        'Vm = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['Vt']!)} V × (${NumberFormat('#,##0.##', 'es_ES').format(inputs['Rm']!)} Ω / ${NumberFormat('#,##0.##', 'es_ES').format(inputs['Rt']!)} Ω)',
    generateQuizQuestion: (inputs, result, formatter) {
      final Vt = inputs['Vt']!;
      final Rm = inputs['Rm']!;
      final Rt = inputs['Rt']!;
      final questionText =
          'En un divisor de voltaje, si el Voltaje Total es ${formatter.format(Vt)} V, la Resistencia a Medir es ${formatter.format(Rm)} Ω, y la Resistencia Total de la serie es ${formatter.format(Rt)} Ω, ¿Cuál es el voltaje en la Resistencia a Medir (Vm)?';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(Vt * Rm * Rt); // Multiplicación
      if (Rm != 0) incorrectOptionsRaw.add(Vt / (Rm / Rt)); // División invertida
      incorrectOptionsRaw.add(Vt + Rm);
      incorrectOptionsRaw.add(result * 1.1); // Variación

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'V', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} V');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La fórmula del divisor de voltaje es Vm = Vt × (Rm / Rt).',
      );
    },
  ),
  // 7. Divisor de Corriente
  Calculo(
    nombre: 'Divisor de Corriente',
    campos: const [
      CampoEntrada(etiqueta: 'Corriente Total', key: 'It', unidad: 'A'),
      CampoEntrada(etiqueta: 'Resistencia del Otro Brazo', key: 'Ro', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Suma de Resistencias Paralelo', key: 'Rs', unidad: 'Ω'), // Suma de R1 + R2 en divisor de 2 resistencias
    ],
    formula: (inputs) => inputs['Rs'] == 0 ? double.infinity : (inputs['It']! * inputs['Ro']!) / inputs['Rs']!,
    descripcionFormula: 'Im = It × (Ro / Rs)', // Para dos resistencias: Im = It * (R_otro / (R_medida + R_otro))
    unidadResultado: 'A',
    explicacionConcepto:
        'El divisor de corriente permite calcular la corriente que fluye a través de un brazo específico en un circuito en paralelo, cuando se conoce la corriente total y las resistencias de los brazos.',
    operacionExplicada: (inputs, res) =>
        'Im = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['It']!)} A × (${NumberFormat('#,##0.##', 'es_ES').format(inputs['Ro']!)} Ω / ${NumberFormat('#,##0.##', 'es_ES').format(inputs['Rs']!)} Ω)',
    generateQuizQuestion: (inputs, result, formatter) {
      final It = inputs['It']!;
      final Ro = inputs['Ro']!;
      final Rs = inputs['Rs']!;
      final questionText =
          'En un divisor de corriente, si la Corriente Total es ${formatter.format(It)} A, la Resistencia del Otro Brazo es ${formatter.format(Ro)} Ω, y la Suma de Resistencias en paralelo es ${formatter.format(Rs)} Ω, ¿Cuál es la corriente en el brazo medido (Im)?';

      List<double> incorrectOptionsRaw = [];
      incorrectOptionsRaw.add(It * Ro * Rs);
      if (Ro != 0) incorrectOptionsRaw.add(It / (Ro / Rs));
      incorrectOptionsRaw.add(It + Ro);
      incorrectOptionsRaw.add(result * 0.9); // Variación

      List<String> optionsAsStrings = generateQuizOptions(result, incorrectOptionsRaw, 'A', formatter);

      final correctAnswerIndex = optionsAsStrings.indexOf('${formatter.format(result)} A');
      if (correctAnswerIndex == -1) return null;

      return QuizQuestion(
        questionText: questionText,
        options: optionsAsStrings,
        correctAnswerIndex: correctAnswerIndex,
        explanation: 'La fórmula del divisor de corriente es Im = It × (Ro / Rs).',
      );
    },
  ),
  // --- Cálculos de Corriente Alterna (CA) ---
  // 8. Reactancia Inductiva
  Calculo(
    nombre: 'Reactancia Inductiva (XL)',
    campos: const [
      CampoEntrada(etiqueta: 'Frecuencia', key: 'f', unidad: 'Hz'),
      CampoEntrada(etiqueta: 'Inductancia', key: 'L', unidad: 'H'),
    ],
    formula: (inputs) => 2 * pi * inputs['f']! * inputs['L']!,
    descripcionFormula: 'XL = 2πfL',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'La reactancia inductiva es la oposición de un inductor al cambio de corriente en un circuito de CA. Depende de la frecuencia de la señal y la inductancia del componente.',
    operacionExplicada: (inputs, res) =>
        'XL = 2π × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['f']!)} Hz × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['L']!)} H',
  ),
  // 9. Reactancia Capacitiva
  Calculo(
    nombre: 'Reactancia Capacitiva (XC)',
    campos: const [
      CampoEntrada(etiqueta: 'Frecuencia', key: 'f', unidad: 'Hz'),
      CampoEntrada(etiqueta: 'Capacitancia', key: 'C', unidad: 'F'),
    ],
    formula: (inputs) => (2 * pi * inputs['f']! * inputs['C']!) == 0 ? double.infinity : 1 / (2 * pi * inputs['f']! * inputs['C']!),
    descripcionFormula: 'XC = 1 / (2πfC)',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'La reactancia capacitiva es la oposición de un capacitor al cambio de voltaje en un circuito de CA. Disminuye a medida que la frecuencia de la señal aumenta.',
    operacionExplicada: (inputs, res) =>
        'XC = 1 / (2π × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['f']!)} Hz × ${NumberFormat('#,##0.###e0', 'es_ES').format(inputs['C']!)} F)', // Usar notación científica para capacitancia si es muy pequeña
  ),
  // 10. Impedancia RLC Serie
  Calculo(
    nombre: 'Impedancia RLC Serie (Z)',
    campos: const [
      CampoEntrada(etiqueta: 'Resistencia', key: 'R', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Reactancia Inductiva', key: 'XL', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Reactancia Capacitiva', key: 'XC', unidad: 'Ω'),
    ],
    formula: (inputs) {
      double R = inputs['R']!;
      double XL = inputs['XL']!;
      double XC = inputs['XC']!;
      return sqrt(pow(R, 2) + pow(XL - XC, 2));
    },
    descripcionFormula: 'Z = √(R² + (XL - XC)²) ',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'La impedancia es la oposición total al flujo de corriente en un circuito de CA, considerando la resistencia y las reactancias inductiva y capacitiva.',
    operacionExplicada: (inputs, res) =>
        'Z = √(${NumberFormat('#,##0.##', 'es_ES').format(inputs['R']!)}² + (${NumberFormat('#,##0.##', 'es_ES').format(inputs['XL']!)} - ${NumberFormat('#,##0.##', 'es_ES').format(inputs['XC']!)})²)',
  ),
  // 11. Ángulo de Fase (RLC)
  Calculo(
    nombre: 'Ángulo de Fase (φ)',
    campos: const [
      CampoEntrada(etiqueta: 'Resistencia', key: 'R', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Reactancia Inductiva', key: 'XL', unidad: 'Ω'),
      CampoEntrada(etiqueta: 'Reactancia Capacitiva', key: 'XC', unidad: 'Ω'),
    ],
    formula: (inputs) {
      double R = inputs['R']!;
      double XL = inputs['XL']!;
      double XC = inputs['XC']!;
      if (R == 0) {
        if (XL > XC) return 90.0;
        if (XL < XC) return -90.0;
        return 0.0; // R=0, XL=XC (resonancia)
      }
      return atan2(XL - XC, R) * 180 / pi; // Resultado en grados
    },
    descripcionFormula: 'φ = atan((XL - XC) / R)',
    unidadResultado: '°',
    explicacionConcepto:
        'El ángulo de fase indica el desfase temporal entre el voltaje y la corriente en un circuito de CA. Un ángulo positivo significa que el voltaje adelanta a la corriente (circuito inductivo), negativo que se atrasa (capacitivo).',
    operacionExplicada: (inputs, res) {
       final formatter = NumberFormat('#,##0.##', 'es_ES');
       double R = inputs['R']!;
       double XL = inputs['XL']!;
       double XC = inputs['XC']!;
       if (R == 0) {
         if (XL > XC) return 'φ = atan((${formatter.format(XL)} - ${formatter.format(XC)}) / 0) (Inductivo puro)';
         if (XL < XC) return 'φ = atan((${formatter.format(XL)} - ${formatter.format(XC)}) / 0) (Capacitivo puro)';
         return 'φ = atan(0 / 0) (Resonancia con R=0)';
       }
       return 'φ = atan((${formatter.format(XL)} Ω - ${formatter.format(XC)} Ω) / ${formatter.format(R)} Ω)';
    },
  ),
  // 12. Factor de Potencia (FP = cos(φ))
  Calculo(
    nombre: 'Factor de Potencia (FP)',
    campos: const [
      CampoEntrada(etiqueta: 'Ángulo φ', key: 'phi', unidad: '°'),
    ],
    formula: (inputs) => cos(inputs['phi']! * pi / 180), // Ángulo en grados
    descripcionFormula: 'FP = cos(φ)',
    unidadResultado: '(adimensional)',
    explicacionConcepto:
        'El factor de potencia mide la eficiencia con la que se utiliza la energía eléctrica en un circuito de CA. Un valor cercano a 1 (o 100%) indica un uso muy eficiente de la energía, reduciendo pérdidas.',
    operacionExplicada: (inputs, res) =>
        'FP = cos(${NumberFormat('#,##0.##', 'es_ES').format(inputs['phi']!)}°)',
  ),
  // --- NUEVO: Potencia Aparente ---
  // 13. Potencia Aparente (S = V x I)
  Calculo(
    nombre: 'Potencia Aparente (S)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje RMS', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Corriente RMS', key: 'I', unidad: 'A'),
    ],
    formula: (inputs) => inputs['V']! * inputs['I']!,
    descripcionFormula: 'S = V × I',
    unidadResultado: 'VA',
    explicacionConcepto:
        'La potencia aparente es la potencia total que fluye de la fuente de alimentación, incluyendo tanto la potencia activa (útil) como la reactiva. Es el producto del voltaje RMS y la corriente RMS.',
    operacionExplicada: (inputs, res) =>
        'S = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A',
  ),
  // --- NUEVO: Potencia Activa (Real) ---
  // 14. Potencia Activa (P = V x I x cos(phi))
  Calculo(
    nombre: 'Potencia Activa (P=VIcosφ)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje RMS', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Corriente RMS', key: 'I', unidad: 'A'),
      CampoEntrada(etiqueta: 'Ángulo de Fase (φ)', key: 'phi', unidad: '°'),
    ],
    formula: (inputs) => inputs['V']! * inputs['I']! * cos(inputs['phi']! * pi / 180),
    descripcionFormula: 'P = V × I × cos(φ)',
    unidadResultado: 'W',
    explicacionConcepto:
        'La potencia activa (o real) es la potencia que realmente se utiliza para realizar un trabajo útil en un circuito de CA. Es la potencia que se consume y se factura.',
    operacionExplicada: (inputs, res) =>
        'P = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A × cos(${NumberFormat('#,##0.##', 'es_ES').format(inputs['phi']!)}°)',
  ),
  // --- NUEVO: Potencia Reactiva ---
  // 15. Potencia Reactiva (Q = V x I x sin(phi))
  Calculo(
    nombre: 'Potencia Reactiva (Q=VIsinφ)',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje RMS', key: 'V', unidad: 'V'),
      CampoEntrada(etiqueta: 'Corriente RMS', key: 'I', unidad: 'A'),
      CampoEntrada(etiqueta: 'Ángulo de Fase (φ)', key: 'phi', unidad: '°'),
    ],
    formula: (inputs) => inputs['V']! * inputs['I']! * sin(inputs['phi']! * pi / 180),
    descripcionFormula: 'Q = V × I × sin(φ)',
    unidadResultado: 'VAR',
    explicacionConcepto:
        'La potencia reactiva es la potencia que oscila entre la fuente y la carga en un circuito de CA, necesaria para establecer campos magnéticos o eléctricos (en inductores y capacitores), pero no realiza trabajo útil.',
    operacionExplicada: (inputs, res) =>
        'Q = ${NumberFormat('#,##0.##', 'es_ES').format(inputs['V']!)} V × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A × sin(${NumberFormat('#,##0.##', 'es_ES').format(inputs['phi']!)}°)',
  ),
  // --- Cálculos de Mediciones y Diagnóstico ---
  // 16. NUEVO: Resistencia de Cable (Caída de Tensión)
  Calculo(
    nombre: 'Resistencia de Cable',
    campos: const [
      CampoEntrada(etiqueta: 'Voltaje Fuente', key: 'Vs', unidad: 'V'),
      CampoEntrada(etiqueta: 'Voltaje Carga', key: 'Vl', unidad: 'V'),
      CampoEntrada(etiqueta: 'Corriente Medida', key: 'I', unidad: 'A'),
    ],
    formula: (inputs) => inputs['I'] == 0 ? double.infinity : (inputs['Vs']! - inputs['Vl']!) / inputs['I']!,
    descripcionFormula: 'R_cable = (Vs - Vl) / I',
    unidadResultado: 'Ω',
    explicacionConcepto:
        'Esta fórmula permite calcular la resistencia aproximada de un cable basándose en la caída de voltaje que ocurre a lo largo de él y la corriente que lo atraviesa. Útil para diagnósticos de circuitos.',
    operacionExplicada: (inputs, res) =>
        'R_cable = (${NumberFormat('#,##0.##', 'es_ES').format(inputs['Vs']!)} V - ${NumberFormat('#,##0.##', 'es_ES').format(inputs['Vl']!)} V) / ${NumberFormat('#,##0.##', 'es_ES').format(inputs['I']!)} A',
  ),
  // 17. Energía Consumida (kWh)
  Calculo(
    nombre: 'Energía Consumida (kWh)',
    campos: const [
      CampoEntrada(etiqueta: 'Potencia', key: 'P', unidad: 'W'),
      CampoEntrada(etiqueta: 'Tiempo', key: 't', unidad: 'horas'),
    ],
    formula: (inputs) => (inputs['P']! / 1000) * inputs['t']!, // Convertir W a kW
    descripcionFormula: 'E = (P / 1000) × t',
    unidadResultado: 'kWh',
    explicacionConcepto:
        'La energía consumida es la cantidad total de energía utilizada por un dispositivo durante un período de tiempo. Se mide comúnmente en kilowatts-hora (kWh) para la facturación eléctrica.',
    operacionExplicada: (inputs, res) =>
        'E = (${NumberFormat('#,##0.##', 'es_ES').format(inputs['P']!)} W / 1000) × ${NumberFormat('#,##0.##', 'es_ES').format(inputs['t']!)} horas',
  ),
];

// --- Helper para generar opciones de quiz (corregido y robustecido) ---
List<String> generateQuizOptions(double correctResult, List<double> incorrectOptionsRaw, String unit, NumberFormat formatter) {
  final Random random = Random();
  List<String> finalOptions = [];
  
  // Paso 1: Formatear el resultado correcto una vez
  final String correctFormatted = '${formatter.format(correctResult)} $unit';
  finalOptions.add(correctFormatted); // Añadir la opción correcta

  // Paso 2: Generar y añadir distractores
  // Usar un Set de strings formateados para asegurar la unicidad visual
  Set<String> uniqueDistractors = {};

  // Añadir distractores de la lista raw, filtrando no finitos/NaN y duplicados visuales
  for (var opt in incorrectOptionsRaw) {
    if (opt.isFinite && !opt.isNaN) {
      String formattedOpt = '${formatter.format(opt)} $unit';
      if (formattedOpt != correctFormatted) { // Asegurarse de que no sea igual a la correcta
        uniqueDistractors.add(formattedOpt);
      }
    }
  }

  // Si no tenemos suficientes distractores, generar más aleatorios
  int attempts = 0;
  while (uniqueDistractors.length < 3 && attempts < 20) { // Necesitamos 3 distractores
    // Generar un distractor variando la opción correcta
    double variationFactor = 0.5 + random.nextDouble() * 1.5; // Multiplicador entre 0.5 y 2.0
    double newDistractorValue = correctResult * variationFactor;

    // Evitar valores muy pequeños o muy grandes si la operación da 0 o infinito
    if (correctResult.abs() < 0.001 && newDistractorValue.abs() < 0.001) {
        newDistractorValue = random.nextDouble() * 100 + 1; // Un valor más normal si el resultado es casi cero
    } else if (correctResult.isInfinite || correctResult.isNaN) {
        newDistractorValue = random.nextDouble() * 1000; // Solo un número aleatorio si la correcta es infinita/NaN
    }


    if (newDistractorValue.isFinite && !newDistractorValue.isNaN) {
      String formattedDistractor = '${formatter.format(newDistractorValue)} $unit';
      if (formattedDistractor != correctFormatted) {
        uniqueDistractors.add(formattedDistractor);
      }
    }
    attempts++;
  }

  // Tomar hasta 3 distractores únicos
  finalOptions.addAll(uniqueDistractors.take(3));

  // Paso 3: Asegurarse de tener exactamente 4 opciones y mezclarlas
  // Si por alguna razón hay menos de 4, rellenar con variaciones aleatorias genéricas.
  while (finalOptions.length < 4) {
    double fillerValue = correctResult + (random.nextDouble() - 0.5) * correctResult.abs() * 0.3 + 10; // Variación + offset
    if (!fillerValue.isFinite || fillerValue.isNaN) {
      fillerValue = random.nextDouble() * 100; // Fallback genérico
    }
    String formattedFiller = '${formatter.format(fillerValue)} $unit';
    if (!finalOptions.contains(formattedFiller)) { // Asegurar unicidad
      finalOptions.add(formattedFiller);
    }
  }

  // Asegurarse de que tengamos exactamente 4 opciones (podrían haberse generado más de 4 si los distractores originales eran muchos)
  if (finalOptions.length > 4) {
      // Si tenemos más de 4 opciones, queremos mantener la correcta y 3 distractores
      // Para ello, barajamos todas las opciones y luego tomamos las 4 primeras.
      // Esto es seguro porque la correcta ya está garantizada en uniqueFormattedOptions.
      finalOptions.shuffle();
      finalOptions = finalOptions.take(4).toList();
      // Un último check por si la correcta fue eliminada al hacer take(4) después de un shuffle
      // (esto puede pasar si la lista original ya tenía la correcta y muchos distractores únicos
      // y la correcta quedaba en las posiciones > 3 después del shuffle)
      if (!finalOptions.contains(correctFormatted)) {
        finalOptions[0] = correctFormatted; // Forzarla si es necesario
        finalOptions.shuffle(); // Re-mezclar para evitar que sea siempre la primera
      }
  }


  finalOptions.shuffle(); // Mezclar el orden final de las 4 opciones

  return finalOptions;
}

// ---- Widget para los cálculos individuales (sin cambios mayores) ----
class CalculoWidget extends StatefulWidget {
  final Calculo calculo;
  final Function(String, String, String, Map<String, double>) onCalcular;

  const CalculoWidget({
    super.key,
    required this.calculo,
    required this.onCalcular,
  });

  @override
  State<CalculoWidget> createState() => CalculoWidgetState();
}

class CalculoWidgetState extends State<CalculoWidget> {
  final Map<String, TextEditingController> controllers = {};
  String operacionCalculada = '';
  String resultadoFinalDisplay = '';
  double? _valorNumericoResultado;
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
  void didUpdateWidget(covariant CalculoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calculo != oldWidget.calculo) {
      _disposeControllers();
      _initializeControllers();
      limpiar(); // Limpia los campos y resultados del cálculo anterior.
      _updateDisplayDefaults(); // Actualiza el display por defecto para el nuevo cálculo
      _loadNewSabiasQue(); // Carga un nuevo consejo al cambiar de cálculo
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
      _valorNumericoResultado = null;
      isErrorState = false;
    });
  }

  void _loadNewSabiasQue() {
    setState(() {
      _currentSabiasQue = sabiasQueConsejos[_random.nextInt(sabiasQueConsejos.length)];
    });
  }

  void loadInputs(Map<String, double> inputsToLoad) {
    limpiar(); // Limpiar antes de cargar nuevos valores
    setState(() {
      for (var entry in inputsToLoad.entries) {
        if (controllers.containsKey(entry.key)) {
          // Formatea el valor numérico para que se vea bien en el TextField
          controllers[entry.key]?.text = _inputFormatter.format(entry.value);
        }
      }
      calcular(); // Recalcular con los inputs cargados automáticamente
    });
  }

  void calcular() {
    Map<String, double> inputs = {};
    bool anyInputEmptyOrInvalid = false;

    for (var campo in widget.calculo.campos) {
      String text = controllers[campo.key]?.text ?? '';
      // Reemplaza la coma por punto para que double.tryParse lo reconozca
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
        _valorNumericoResultado = null;
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
        _valorNumericoResultado = res;
        resultadoFinalDisplay = '${_numberFormatter.format(res)} ${widget.calculo.unidadResultado}';
        operacionCalculada = currentOperacionText;
        isErrorState = false;
      });

      widget.onCalcular(
        widget.calculo.nombre,
        '$currentOperacionText = ${_numberFormatter.format(res)} ${widget.calculo.unidadResultado}', // Guardar operación completa en historial
        resultadoFinalDisplay,
        inputs,
      );
    } catch (e) {
      setState(() {
        resultadoFinalDisplay = 'Error de cálculo: ${e.toString()}';
        operacionCalculada = '';
        _valorNumericoResultado = null;
        isErrorState = true;
      });
    }
  }

  void limpiar() {
    for (var c in controllers.values) {
      c.clear();
    }
    _updateDisplayDefaults(); // Usa la función que restablece todos los valores a su estado por defecto
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Añade padding inferior para evitar que el teclado oculte contenido
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      children: [
        // PANTALLA DE RESULTADO (ARRIBA)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.topRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido de la columna arriba
            children: [
              // Explicación del Concepto
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
              // Fórmula Teórica
              Text(
                widget.calculo.descripcionFormula,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 8),
              // Operación con valores sustituidos
              Text(
                operacionCalculada, // Ya se inicializa a 'Operación' o tiene el cálculo
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Resultado Final
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
                  resultadoFinalDisplay, // Ahora viene ya formateado y con unidad
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.end,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20), // Espacio entre el área de resultados y los inputs

        // FÓRMULAS Y BOTONES (ABAJO)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Los campos de entrada
              ...widget.calculo.campos.map(
                (campo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: controllers[campo.key],
                    decoration: InputDecoration(
                      labelText: '${campo.etiqueta} (${campo.unidad})',
                      prefixIcon: _getIconForUnit(campo.unidad),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final text = newValue.text.replaceAll('.', ',');
                        return newValue.copyWith(text: text, selection: newValue.selection);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: calcular,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calcular'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: limpiar,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // --- Sección "¿Sabías que...?" ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.blueGrey.shade100,
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
      case 'V':
        return const Icon(Icons.flash_on);
      case 'A':
        return const Icon(Icons.bolt);
      case 'Ω':
        return const Icon(Icons.power);
      case 'W':
        return const Icon(Icons.lightbulb_outline);
      case 'Hz':
        return const Icon(Icons.waves);
      case 'H':
        return const Icon(Icons.electrical_services);
      case 'F':
        return const Icon(Icons.sd_card);
      case '°':
        return const Icon(Icons.timeline);
      case 'horas':
        return const Icon(Icons.timer);
      default:
        return const Icon(Icons.input);
    }
  }
}

// ---- Widget para el Historial (Sin cambios, pero ahora recibe datos más completos) ----
class HistorialWidget extends StatelessWidget {
  final List<Map<String, String>> historial;
  final Function(Map<String, String>) onItemTap;

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
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No hay cálculos recientes',
              style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
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
          child: InkWell(
            onTap: () => onItemTap(item),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['titulo'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Operación: ${item['operacion']}', // Esta es la cadena completa ahora
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    maxLines: 2, // Aumenta a 2 líneas para la operación completa
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Resultado: ${item['resultado']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
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

// --- NUEVO: Generador de Ejercicios ---
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

  final NumberFormat _valueFormatter = NumberFormat('###.##', 'es_ES'); // Formateador para los valores en los ejercicios

  void _generateExercise() {
    _showAnswer = false; // Ocultar respuesta anterior
    // Filtrar cálculos que son demasiado complejos o no tienen sentido para ejercicios aleatorios simples
    final availableCalculos = calculos.where((c) =>
        c.campos.length <= 3 && // Limitar a 3 campos para simplicidad
        c.nombre != 'R_eq en Serie' && // No generar R_eq con 3 campos fijos
        c.nombre != 'R_eq en Paralelo' && // No generar R_eq con 3 campos fijos
        !c.nombre.contains('RLC') && // Excluir RLC para evitar complejidad de CA en ejercicios básicos
        !c.nombre.contains('Reactancia') && // Excluir Reactancia por ahora
        !c.nombre.contains('Factor de Potencia') && // Excluir FP por ahora
        !c.nombre.contains('Potencia Aparente') && // Excluir Potencia Aparente
        !c.nombre.contains('Potencia Activa') && // Excluir Potencia Activa
        !c.nombre.contains('Potencia Reactiva') // Excluir Potencia Reactiva
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
    String calculationStep = selectedCalculo.descripcionFormula; // La fórmula teórica

    try {
      // Generar valores aleatorios para los inputs
      for (var campo in selectedCalculo.campos) {
        double value;
        // Rango de valores razonable para cada unidad
        if (campo.unidad == 'V') {
          value = _random.nextDouble() * 230 + 10; // 10V a 240V
        } else if (campo.unidad == 'A') {
          value = _random.nextDouble() * 10 + 0.1; // 0.1A a 10.1A
        } else if (campo.unidad == 'Ω') {
          value = _random.nextDouble() * 1000 + 1; // 1Ω a 1001Ω
        } else if (campo.unidad == 'W') {
          value = _random.nextDouble() * 2000 + 10; // 10W a 2010W
        } else if (campo.unidad == 'Hz') {
          value = _random.nextDouble() * 100 + 50; // 50Hz a 150Hz
        } else if (campo.unidad == 'H') {
          value = (_random.nextDouble() * 0.1 + 0.001); // 1mH a 101mH
        } else if (campo.unidad == 'F') {
          value = (_random.nextDouble() * 0.00001 + 0.00000001); // 0.01µF a 10µF (usar valor pequeño)
        } else if (campo.unidad == '°') {
          value = _random.nextDouble() * 90; // 0 a 90 grados
        } else if (campo.unidad == 'horas') {
          value = _random.nextDouble() * 24 + 1; // 1 a 25 horas
        } else {
          value = _random.nextDouble() * 100 + 1;
        }

        // Asegurar que las capacitancias pequeñas se muestren en notación científica si es necesario
        if (campo.unidad == 'F' && value < 0.000001) { // Si es menor a 1 microfaradio
          final scientificFormatter = NumberFormat('0.###E0', 'es_ES');
          problemText += '- ${campo.etiqueta}: ${scientificFormatter.format(value)} ${campo.unidad}\n';
        } else {
          problemText += '- ${campo.etiqueta}: ${_valueFormatter.format(value)} ${campo.unidad}\n';
        }

        inputs[campo.key] = value;
      }

      // Manejo especial para el divisor de corriente donde Rs es la suma de Ro y Rm (si no son campos independientes)
      if (selectedCalculo.nombre == 'Divisor de Corriente' && inputs['Rs'] == null) {
          // Asumimos que Rm es la resistencia a medir y Ro es la resistencia del otro brazo
          double rm = inputs['Rm'] ?? 1.0;
          double ro = inputs['Ro'] ?? 1.0;
          inputs['Rs'] = rm + ro; // Calcula la suma si no es un campo de entrada explícito.
      }
      // Manejo especial para Resistencia de Cable: Vs debe ser mayor que Vl
      if (selectedCalculo.nombre == 'Resistencia de Cable') {
          double vs = inputs['Vs']!;
          double vl = inputs['Vl']!;
          if (vs <= vl) { // Asegura que haya una caída de tensión positiva
              vs = vl + (_random.nextDouble() * 5 + 1); // Vs = Vl + (1 a 6V de caída)
              inputs['Vs'] = vs;
              // Ajusta el texto del problema si es necesario
              problemText = 'Problema de Resistencia de Cable:\n\n'
                            '- Voltaje Fuente: ${_valueFormatter.format(vs)} V\n'
                            '- Voltaje Carga: ${_valueFormatter.format(vl)} V\n'
                            '- Corriente Medida: ${_valueFormatter.format(inputs['I']!)} A\n\n'
                            'Calcula el/la Resistencia de Cable.';
          }
      }

      final result = selectedCalculo.formula(inputs);
      problemText += '\nCalcula el/la ${selectedCalculo.nombre.split('(').first.trim()}.'; // Ej: "Calcula el/la Ley de Ohm."

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
            const SizedBox(height: 40), // Espacio al final
          ],
        ),
      ),
    );
  }
}

// --- NUEVO: Quiz Screen ---
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
  final NumberFormat _valueFormatter = NumberFormat('###.##', 'es_ES'); // Formateador para los valores en los ejercicios

  @override
  void initState() {
    super.initState();
    _generateQuizQuestion();
  }

  void _generateQuizQuestion() {
    _selectedOptionIndex = null;
    _feedbackShown = false;
    _isCorrect = false;

    // Filtra las fórmulas que tienen lógica de generación de quiz
    final quizAvailableCalculos = calculos.where((c) => c.generateQuizQuestion != null).toList();

    if (quizAvailableCalculos.isEmpty) {
      setState(() {
        _currentQuizQuestion = QuizQuestion(
          questionText: 'No hay preguntas de cuestionario disponibles. (quizAvailableCalculos está vacío)',
          options: ['N/A'],
          correctAnswerIndex: 0,
        );
      });
      return;
    }

    // Intentar generar una pregunta válida. Iterar hasta encontrar una o agotar intentos.
    QuizQuestion? generatedQuestion;
    int attempts = 0;
    while (generatedQuestion == null && attempts < 10) { // Limitar intentos
      final selectedCalculo = quizAvailableCalculos[_random.nextInt(quizAvailableCalculos.length)];
      final Map<String, double> inputs = {};

      // Generar inputs aleatorios para el cálculo seleccionado
      for (var campo in selectedCalculo.campos) {
        double value;
        // Rango de valores razonable para cada unidad
        if (campo.unidad == 'V') {
          value = _random.nextDouble() * 230 + 10; // 10V a 240V
        } else if (campo.unidad == 'A') {
          value = _random.nextDouble() * 10 + 0.1; // 0.1A a 10.1A
        } else if (campo.unidad == 'Ω') {
          value = _random.nextDouble() * 1000 + 1; // 1Ω a 1001Ω
        } else if (campo.unidad == 'H') {
          value = (_random.nextDouble() * 0.1 + 0.001); // 1mH a 101mH
        } else if (campo.unidad == 'F') {
          value = (_random.nextDouble() * 0.00001 + 0.00000001); // 0.01µF a 10µF (usar valor pequeño)
        } else if (campo.unidad == '°') {
          value = _random.nextDouble() * 90; // 0 a 90 grados
        } else if (campo.unidad == 'horas') {
          value = _random.nextDouble() * 24 + 1; // 1 a 25 horas
        } else {
          value = _random.nextDouble() * 100 + 1;
        }
        
        // Manejo especial para Divisor de Corriente si el input Rs no es explícito pero la fórmula lo usa
        if (selectedCalculo.nombre == 'Divisor de Corriente' && campo.key == 'Rs') {
          // Asumiendo que 'Ro' y 'Rm' están en inputs. Esto es una simplificación.
          // Idealmente, deberías generar Ro y Rm, y luego calcular Rs = Ro + Rm
          // Por ahora, solo asegurémonos de que no sea 0.
          value = inputs['Ro'] != null && inputs['Rm'] != null ? inputs['Ro']! + inputs['Rm']! : _random.nextDouble() * 100 + 10;
        }

        inputs[campo.key] = value;
      }

      try {
        // Asegurarse de que no haya división por cero o NaN en los inputs para la fórmula
        bool inputsAreValidForFormula = true;
        for (var campo in selectedCalculo.campos) {
          if (inputs[campo.key] == 0 && (selectedCalculo.descripcionFormula.contains('/') || selectedCalculo.descripcionFormula.contains('tan'))) {
            inputsAreValidForFormula = false; // Evita divisiones por cero problemáticas
            break;
          }
        }

        if (inputsAreValidForFormula) {
          final result = selectedCalculo.formula(inputs);
          // Asegurarse de que el resultado sea finito y no NaN para el quiz
          if (result.isFinite && !result.isNaN) {
            generatedQuestion = selectedCalculo.generateQuizQuestion!(inputs, result, _valueFormatter);
            // Asegurarse de que la pregunta generada sea válida (tenga opciones, correcta exista)
            if (generatedQuestion != null && generatedQuestion.options.isEmpty || generatedQuestion!.correctAnswerIndex == -1) {
              generatedQuestion = null; // Reiniciar para intentar de nuevo
            }
          }
        }
      } catch (e) {
        // Capturar errores durante la ejecución de la fórmula o generación de quiz
        print('Error al generar quiz para ${selectedCalculo.nombre}: $e');
        generatedQuestion = null; // Invalidar la pregunta para reintentar
      }
      attempts++;
    }

    setState(() {
      if (generatedQuestion != null) {
        _currentQuizQuestion = generatedQuestion;
      } else {
        _currentQuizQuestion = QuizQuestion(
          questionText: 'No se pudo generar una pregunta válida después de varios intentos. Posibles problemas con las fórmulas o distractores.',
          options: ['N/A'],
          correctAnswerIndex: 0,
          explanation: 'Revisa la implementación de generateQuizQuestion para las fórmulas disponibles.',
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
        title: const Text('Cuestionario Eléctrico'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pregunta:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
                  // Opciones de respuesta
                  ..._currentQuizQuestion!.options.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String option = entry.value;
                    bool isSelected = _selectedOptionIndex == idx;
                    bool showCorrectness = _feedbackShown;
                    bool isCorrectOption = idx == _currentQuizQuestion!.correctAnswerIndex;

                    Color tileColor = Colors.white;
                    if (showCorrectness) {
                      if (isCorrectOption) {
                        tileColor = Colors.green.shade100; // Correcta
                      } else if (isSelected && !isCorrectOption) {
                        tileColor = Colors.red.shade100; // Incorrecta seleccionada
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: tileColor,
                      elevation: 1,
                      child: RadioListTile<int>(
                        value: idx,
                        groupValue: _selectedOptionIndex,
                        onChanged: _feedbackShown ? null : (int? value) { // Deshabilitar si ya se dio feedback
                          setState(() {
                            _selectedOptionIndex = value;
                          });
                        },
                        title: Text(option),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    );
                  }),
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
                  const SizedBox(height: 40), // Espacio al final
                ],
              ),
            ),
    );
  }
}