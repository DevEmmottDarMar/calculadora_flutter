import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;

class CalculadoraPantalla extends StatefulWidget {
  const CalculadoraPantalla({super.key});

  @override
  _CalculadoraPantallaState createState() => _CalculadoraPantallaState();
}

class _CalculadoraPantallaState extends State<CalculadoraPantalla> {
  String _pantalla = '';
  String _resultado = '0';
  final List<String> _historial = [];
  final int _maxLongitud = 100;

  void _presionarBoton(String valor) {
    setState(() {
      if (_pantalla.length >= _maxLongitud) return;
      if (_pantalla.isEmpty && "+*/".contains(valor)) {
        if (valor == '-') _pantalla += valor;
        return;
      }
      if ('+-×÷'.contains(valor) &&
          _pantalla.isNotEmpty &&
          '+-×÷'.contains(_pantalla[_pantalla.length - 1])) {
        _pantalla = _pantalla.substring(0, _pantalla.length - 1) + valor;
        return;
      }
      if (valor == '.') {
        final RegExp numRegex = RegExp(r'(\d+\.?\d*|\.)+$');
        final match = numRegex.firstMatch(_pantalla);
        if (match != null && match.group(0)!.contains('.')) return;
        if (_pantalla.isEmpty || '+-×÷'.contains(_pantalla[_pantalla.length - 1])) {
          _pantalla += '0.';
          return;
        }
      }
      _pantalla += valor;
    });
  }

  void _calcular() {
    try {
      String expressionToParse = _pantalla.replaceAll('×', '*').replaceAll('÷', '/');
      Parser p = Parser();
      Expression exp = p.parse(expressionToParse);
      double eval = exp.evaluate(EvaluationType.REAL, ContextModel());
      String resultadoStr = eval.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');

      if (_historial.length >= 20) _historial.removeLast();
      _historial.insert(0, '$_pantalla = $resultadoStr');

      setState(() {
        _resultado = resultadoStr;
        _pantalla = resultadoStr;
      });
    } catch (e) {
      setState(() {
        _resultado = 'Error';
        _pantalla = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de cálculo. Revisa la expresión.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiar() {
    setState(() {
      _pantalla = '';
      _resultado = '0';
    });
  }

  void _borrarUltimo() {
    setState(() {
      if (_pantalla.isNotEmpty) {
        _pantalla = _pantalla.substring(0, _pantalla.length - 1);
        if (_pantalla.isEmpty) _resultado = '0';
      }
    });
  }

  void _mostrarTienda() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🛒 Tienda de Funciones Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.science, color: Colors.grey),
              title: const Text('Calculadora Científica'),
              subtitle: const Text('🔒 Disponible próximamente'),
              onTap: () {
                Navigator.pop(context);
                _mostrarProximamente('Calculadora Científica');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.grey),
              title: const Text('Calculadora Eléctrica'),
              subtitle: const Text('🔒 Disponible próximamente'),
              onTap: () {
                Navigator.pop(context);
                _mostrarProximamente('Calculadora Eléctrica');
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows, color: Colors.grey),
              title: const Text('Conversor de Unidades'),
              subtitle: const Text('🔒 Disponible próximamente'),
              onTap: () {
                Navigator.pop(context);
                _mostrarProximamente('Conversor de Unidades');
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.lock_open),
              title: Text('Todas las funciones desbloqueadas'),
              subtitle: Text('Próximamente con versión PRO'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarProximamente(String modulo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('🔒 $modulo'),
        content: const Text(
          'Esta función estará disponible en una próxima actualización de la app. ¡Gracias por tu paciencia!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _crearBoton(
    String texto, {
    Color color = Colors.blueGrey,
    Color textColor = Colors.white,
    Function()? onTap,
    bool isOperator = false,
    bool isZero = false,
  }) {
    return Expanded(
      flex: isZero ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            textStyle: TextStyle(
              fontSize: isOperator ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onTap,
          child: Text(texto),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryHeight = MediaQuery.of(context).size.height;
    final displayHeight = mediaQueryHeight * 0.22;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calculadora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.store, color: Colors.amberAccent),
            onPressed: _mostrarTienda,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.lightBlueAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF2C2C2C),
                  title: const Text('Historial de Cálculos', style: TextStyle(color: Colors.white)),
                  content: _historial.isEmpty
                      ? const Text('El historial está vacío.', style: TextStyle(color: Colors.grey))
                      : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _historial.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(_historial[index], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                            ),
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar', style: TextStyle(color: Colors.lightBlueAccent)),
                    ),
                    if (_historial.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _historial.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Borrar Historial', style: TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E2C), Color(0xFF232931)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: displayHeight,
                padding: const EdgeInsets.all(10),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _pantalla.isEmpty ? '0' : _pantalla,
                          style: TextStyle(
                            fontSize: mediaQueryHeight > 700 ? 36 : 28,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _resultado,
                          style: TextStyle(
                            fontSize: mediaQueryHeight > 700 ? 64 : 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    for (var fila in [
                      ['C', '(', ')', '⌫', '÷'],
                      ['7', '8', '9', '×'],
                      ['4', '5', '6', '-'],
                      ['1', '2', '3', '+'],
                      ['0', '.', '=']
                    ])
                      Expanded(
                        child: Row(
                          children: fila.map((valor) {
                            return _crearBoton(
                              valor,
                              color: _colorear(valor),
                              textColor: Colors.white,
                              onTap: () {
                                if (valor == 'C') return _limpiar();
                                if (valor == '⌫') return _borrarUltimo();
                                if (valor == '=') return _calcular();
                                return _presionarBoton(valor);
                              },
                              isOperator: '+-×÷=C⌫'.contains(valor),
                              isZero: valor == '0',
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorear(String valor) {
    switch (valor) {
      case 'C':
        return const Color(0xFFD32F2F);
      case '⌫':
        return const Color(0xFF616161);
      case '÷':
      case '×':
      case '-':
      case '+':
        return const Color(0xFFFB8C00);
      case '=':
        return const Color(0xFF43A047);
      case '(':
      case ')':
      case '.':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF424242);
    }
  }
}
