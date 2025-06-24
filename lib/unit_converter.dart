// unit_converter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formateo de números
import 'package:flutter/services.dart'; // ¡AÑADE ESTA LÍNEA!

// ====================================================================
// ========================= MODELOS DE DATOS =========================
// ====================================================================

// Clase para representar una Unidad (ej. "metros", "kilogramos")
class Unit {
  final String symbol; // Símbolo de la unidad (ej. "m", "kg")
  final String
  name; // Nombre completo de la unidad (ej. "metros", "kilogramos")
  // Factor de conversión a la unidad estándar de su categoría.
  // Ej: para Longitud (estándar: metros), 1 km = 1000, 1 cm = 0.01, 1 pulgada = 0.0254
  final double conversionFactorToStandard;

  const Unit({
    required this.symbol,
    required this.name,
    required this.conversionFactorToStandard,
  });

  // Método para convertir de esta unidad a la unidad estándar
  double toStandard(double value) => value * conversionFactorToStandard;
  // Método para convertir de la unidad estándar a esta unidad
  double fromStandard(double standardValue) =>
      standardValue / conversionFactorToStandard;
}

// Clase para representar una Categoría de Unidades (ej. "Longitud", "Temperatura")
class UnitCategory {
  final String name; // Nombre de la categoría (ej. "Longitud")
  final List<Unit> units; // Lista de unidades dentro de esta categoría
  final String
  standardUnitSymbol; // Símbolo de la unidad "base" de esta categoría (ej. "m" para longitud)

  const UnitCategory({
    required this.name,
    required this.units,
    required this.standardUnitSymbol,
  });

  // Encuentra la unidad estándar por su símbolo
  Unit get standardUnit =>
      units.firstWhere((unit) => unit.symbol == standardUnitSymbol);
}

// ====================================================================
// ======================== DEFINICIÓN DE UNIDADES ====================
// ====================================================================

// Nota: La unidad "estándar" de cada categoría tiene un factor de 1.0
// Las conversiones de temperatura son más complejas y se manejan en la fórmula directamente.

final List<UnitCategory> allUnitCategories = [
  // ------------------------- Longitud -------------------------
  UnitCategory(
    name: 'Longitud',
    standardUnitSymbol: 'm',
    units: [
      Unit(symbol: 'm', name: 'metros', conversionFactorToStandard: 1.0),
      Unit(symbol: 'cm', name: 'centímetros', conversionFactorToStandard: 0.01),
      Unit(
        symbol: 'km',
        name: 'kilómetros',
        conversionFactorToStandard: 1000.0,
      ),
      Unit(symbol: 'mm', name: 'milímetros', conversionFactorToStandard: 0.001),
      Unit(symbol: 'in', name: 'pulgadas', conversionFactorToStandard: 0.0254),
      Unit(symbol: 'ft', name: 'pies', conversionFactorToStandard: 0.3048),
      Unit(symbol: 'yd', name: 'yardas', conversionFactorToStandard: 0.9144),
      Unit(symbol: 'mi', name: 'millas', conversionFactorToStandard: 1609.34),
    ],
  ),
  // ------------------------- Volumen -------------------------
  UnitCategory(
    name: 'Volumen',
    standardUnitSymbol: 'm³',
    units: [
      Unit(
        symbol: 'm³',
        name: 'metros cúbicos',
        conversionFactorToStandard: 1.0,
      ),
      Unit(
        symbol: 'cm³',
        name: 'centímetros cúbicos',
        conversionFactorToStandard: 0.000001,
      ),
      Unit(symbol: 'L', name: 'litros', conversionFactorToStandard: 0.001),
      Unit(
        symbol: 'mL',
        name: 'mililitros',
        conversionFactorToStandard: 0.000001,
      ),
      Unit(
        symbol: 'gal',
        name: 'galones (US liq)',
        conversionFactorToStandard: 0.00378541,
      ),
      Unit(
        symbol: 'pt',
        name: 'pintas (US liq)',
        conversionFactorToStandard: 0.000473176,
      ),
      Unit(
        symbol: 'fl oz',
        name: 'onzas líquidas (US)',
        conversionFactorToStandard: 0.0000295735,
      ),
    ],
  ),
  // ------------------------- Masa/Peso -------------------------
  UnitCategory(
    name: 'Masa/Peso',
    standardUnitSymbol: 'kg',
    units: [
      Unit(symbol: 'kg', name: 'kilogramos', conversionFactorToStandard: 1.0),
      Unit(symbol: 'g', name: 'gramos', conversionFactorToStandard: 0.001),
      Unit(symbol: 'lb', name: 'libras', conversionFactorToStandard: 0.453592),
      Unit(symbol: 'oz', name: 'onzas', conversionFactorToStandard: 0.0283495),
      Unit(
        symbol: 't',
        name: 'toneladas métricas',
        conversionFactorToStandard: 1000.0,
      ),
    ],
  ),
  // ------------------------- Temperatura -------------------------
  // Nota: Conversiones de temperatura son lineales, no multiplicativas a una base.
  // Se manejarán con funciones específicas. El factor es para distinguir la unidad.
  UnitCategory(
    name: 'Temperatura',
    standardUnitSymbol:
        '°C', // Usaremos Celsius como "estándar" para cálculos intermedios
    units: [
      Unit(symbol: '°C', name: 'Celsius', conversionFactorToStandard: 1.0),
      Unit(
        symbol: '°F',
        name: 'Fahrenheit',
        conversionFactorToStandard: 1.0,
      ), // Factor simbólico
      Unit(
        symbol: 'K',
        name: 'Kelvin',
        conversionFactorToStandard: 1.0,
      ), // Factor simbólico
    ],
  ),
  // ------------------------- Tiempo -------------------------
  UnitCategory(
    name: 'Tiempo',
    standardUnitSymbol: 's',
    units: [
      Unit(symbol: 's', name: 'segundos', conversionFactorToStandard: 1.0),
      Unit(symbol: 'min', name: 'minutos', conversionFactorToStandard: 60.0),
      Unit(symbol: 'h', name: 'horas', conversionFactorToStandard: 3600.0),
      Unit(symbol: 'd', name: 'días', conversionFactorToStandard: 86400.0),
      Unit(symbol: 'wk', name: 'semanas', conversionFactorToStandard: 604800.0),
      Unit(
        symbol: 'yr',
        name: 'años (aprox. 365.25 d)',
        conversionFactorToStandard: 31557600.0,
      ),
    ],
  ),
  // ------------------------- Velocidad -------------------------
  UnitCategory(
    name: 'Velocidad',
    standardUnitSymbol: 'm/s',
    units: [
      Unit(
        symbol: 'm/s',
        name: 'metros/segundo',
        conversionFactorToStandard: 1.0,
      ),
      Unit(
        symbol: 'km/h',
        name: 'kilómetros/hora',
        conversionFactorToStandard: 1000 / 3600,
      ),
      Unit(
        symbol: 'mph',
        name: 'millas/hora',
        conversionFactorToStandard: 1609.34 / 3600,
      ),
      Unit(
        symbol: 'kt',
        name: 'nudos (nautical miles/hour)',
        conversionFactorToStandard: 1852 / 3600,
      ),
    ],
  ),
  // ------------------------- Área -------------------------
  UnitCategory(
    name: 'Área',
    standardUnitSymbol: 'm²',
    units: [
      Unit(
        symbol: 'm²',
        name: 'metros cuadrados',
        conversionFactorToStandard: 1.0,
      ),
      Unit(
        symbol: 'cm²',
        name: 'centímetros cuadrados',
        conversionFactorToStandard: 0.0001,
      ),
      Unit(
        symbol: 'km²',
        name: 'kilómetros cuadrados',
        conversionFactorToStandard: 1000000.0,
      ),
      Unit(
        symbol: 'ha',
        name: 'hectáreas',
        conversionFactorToStandard: 10000.0,
      ),
      Unit(symbol: 'ac', name: 'acres', conversionFactorToStandard: 4046.86),
      Unit(
        symbol: 'ft²',
        name: 'pies cuadrados',
        conversionFactorToStandard: 0.092903,
      ),
    ],
  ),
  // ------------------------- Presión -------------------------
  UnitCategory(
    name: 'Presión',
    standardUnitSymbol: 'Pa',
    units: [
      Unit(symbol: 'Pa', name: 'Pascal', conversionFactorToStandard: 1.0),
      Unit(
        symbol: 'kPa',
        name: 'kilopascal',
        conversionFactorToStandard: 1000.0,
      ),
      Unit(
        symbol: 'psi',
        name: 'libras por pulgada cuadrada',
        conversionFactorToStandard: 6894.76,
      ),
      Unit(
        symbol: 'atm',
        name: 'atmósferas',
        conversionFactorToStandard: 101325.0,
      ),
      Unit(symbol: 'bar', name: 'bar', conversionFactorToStandard: 100000.0),
    ],
  ),
  // ------------------------- Energía -------------------------
  UnitCategory(
    name: 'Energía',
    standardUnitSymbol: 'J',
    units: [
      Unit(symbol: 'J', name: 'Julios', conversionFactorToStandard: 1.0),
      Unit(
        symbol: 'kJ',
        name: 'kilojulios',
        conversionFactorToStandard: 1000.0,
      ),
      Unit(
        symbol: 'cal',
        name: 'calorías (termoquímicas)',
        conversionFactorToStandard: 4.184,
      ),
      Unit(
        symbol: 'kcal',
        name: 'kilocalorías',
        conversionFactorToStandard: 4184.0,
      ),
      Unit(
        symbol: 'Wh',
        name: 'Watts-hora',
        conversionFactorToStandard: 3600.0,
      ),
      Unit(
        symbol: 'kWh',
        name: 'kilowatts-hora',
        conversionFactorToStandard: 3600000.0,
      ),
    ],
  ),
  // ------------------------- Potencia -------------------------
  UnitCategory(
    name: 'Potencia',
    standardUnitSymbol: 'W',
    units: [
      Unit(symbol: 'W', name: 'Watts', conversionFactorToStandard: 1.0),
      Unit(symbol: 'kW', name: 'kilowatts', conversionFactorToStandard: 1000.0),
      Unit(
        symbol: 'hp',
        name: 'caballos de fuerza (métrico)',
        conversionFactorToStandard: 735.499,
      ),
      Unit(
        symbol: 'ft·lb/s',
        name: 'pie-libras por segundo',
        conversionFactorToStandard: 1.35582,
      ),
    ],
  ),
];

// ====================================================================
// ==================== APLICACIÓN CONVERSOR DE UNIDADES ============
// ====================================================================

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor Universal de Unidades',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.blueGrey.shade50,
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
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.blueGrey.shade400,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
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
      home: const UnitConverterHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UnitConverterHome extends StatefulWidget {
  const UnitConverterHome({super.key});

  @override
  State<UnitConverterHome> createState() => _UnitConverterHomeState();
}

class _UnitConverterHomeState extends State<UnitConverterHome> {
  final TextEditingController _inputController = TextEditingController();
  String _convertedResult = '0';
  String _inputUnitSymbol = '';
  String _outputUnitSymbol = '';
  UnitCategory? _selectedCategory;

  final NumberFormat _numberFormatter = NumberFormat(
    '#,##0.####',
    'es_ES',
  ); // Formateador para resultados

  @override
  void initState() {
    super.initState();
    // Inicializar con la primera categoría y sus primeras unidades
    _selectedCategory = allUnitCategories.first;
    _inputUnitSymbol = _selectedCategory!.units.first.symbol;
    _outputUnitSymbol = _selectedCategory!
        .units
        .last
        .symbol; // O cualquier otra unidad por defecto
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _performConversion() {
    final double? inputValue = double.tryParse(
      _inputController.text.replaceAll(',', '.'),
    );

    if (inputValue == null) {
      setState(() {
        _convertedResult = 'Entrada inválida';
      });
      return;
    }

    if (_selectedCategory == null ||
        _inputUnitSymbol.isEmpty ||
        _outputUnitSymbol.isEmpty) {
      setState(() {
        _convertedResult = 'Selecciona unidades';
      });
      return;
    }

    // Encontrar las unidades seleccionadas
    final Unit inputUnit = _selectedCategory!.units.firstWhere(
      (unit) => unit.symbol == _inputUnitSymbol,
    );
    final Unit outputUnit = _selectedCategory!.units.firstWhere(
      (unit) => unit.symbol == _outputUnitSymbol,
    );

    double result;

    // Manejo especial para la temperatura (conversiones no lineales)
    if (_selectedCategory!.name == 'Temperatura') {
      double valueInCelsius;
      if (inputUnit.symbol == '°C') {
        valueInCelsius = inputValue;
      } else if (inputUnit.symbol == '°F') {
        valueInCelsius = (inputValue - 32) * 5 / 9;
      } else if (inputUnit.symbol == 'K') {
        valueInCelsius = inputValue - 273.15;
      } else {
        valueInCelsius = 0; // Fallback
      }

      if (outputUnit.symbol == '°C') {
        result = valueInCelsius;
      } else if (outputUnit.symbol == '°F') {
        result = (valueInCelsius * 9 / 5) + 32;
      } else if (outputUnit.symbol == 'K') {
        result = valueInCelsius + 273.15;
      } else {
        result = 0; // Fallback
      }
    } else {
      // Conversión estándar para la mayoría de las unidades
      double valueInStandardUnit = inputUnit.toStandard(inputValue);
      result = outputUnit.fromStandard(valueInStandardUnit);
    }

    setState(() {
      _convertedResult =
          '${_numberFormatter.format(result)} ${outputUnit.symbol}';
    });
  }

  void _clearFields() {
    _inputController.clear();
    setState(() {
      _convertedResult = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversor Universal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pantalla de resultados
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _inputController.text.isEmpty
                        ? '0'
                        : '${_inputController.text} $_inputUnitSymbol',
                    style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _convertedResult,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selector de Categoría
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UnitCategory>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: const Text('Selecciona Categoría de Unidad'),
                    onChanged: (UnitCategory? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        // Restablecer unidades de entrada/salida a las primeras de la nueva categoría
                        if (_selectedCategory != null &&
                            _selectedCategory!.units.isNotEmpty) {
                          _inputUnitSymbol =
                              _selectedCategory!.units.first.symbol;
                          _outputUnitSymbol =
                              _selectedCategory!.units.last.symbol;
                          _convertedResult = '0'; // Limpiar resultado
                          _inputController.clear(); // Limpiar entrada
                        }
                      });
                    },
                    items: allUnitCategories
                        .map<DropdownMenuItem<UnitCategory>>((
                          UnitCategory category,
                        ) {
                          return DropdownMenuItem<UnitCategory>(
                            value: category,
                            child: Text(category.name),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Entrada de valor
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Valor a convertir',
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*[\.,]?\d*'),
                ), // Solo números y un punto/coma
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(
                    '.',
                    ',',
                  ); // Asegurar que use coma
                  return newValue.copyWith(
                    text: text,
                    selection: newValue.selection,
                  );
                }),
              ],
              onChanged: (text) {
                // Realizar la conversión al escribir, pero con un debounce si se vuelve lento
                // Para simplificar, lo haremos solo al presionar el botón por ahora.
              },
            ),
            const SizedBox(height: 15),

            // Selectores de unidades
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _inputUnitSymbol,
                          hint: const Text('De Unidad'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _inputUnitSymbol = newValue!;
                            });
                          },
                          items:
                              _selectedCategory?.units
                                  .map<DropdownMenuItem<String>>((Unit unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit.symbol,
                                      child: Text(
                                        '${unit.name} (${unit.symbol})',
                                      ),
                                    );
                                  })
                                  .toList() ??
                              [],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_right_alt,
                  size: 30,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _outputUnitSymbol,
                          hint: const Text('A Unidad'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _outputUnitSymbol = newValue!;
                            });
                          },
                          items:
                              _selectedCategory?.units
                                  .map<DropdownMenuItem<String>>((Unit unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit.symbol,
                                      child: Text(
                                        '${unit.name} (${unit.symbol})',
                                      ),
                                    );
                                  })
                                  .toList() ??
                              [],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performConversion,
                    icon: const Icon(Icons.transform),
                    label: const Text('Convertir'),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
