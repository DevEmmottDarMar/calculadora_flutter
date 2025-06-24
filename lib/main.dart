import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
import 'package:shared_preferences/shared_preferences.dart';

// Importa tus otras calculadoras. Asegúrate de que los nombres de archivo sean correctos.
import 'scientific_calculator.dart';
import 'electric_calculator.dart';
import 'unit_converter.dart';

// Importa la pantalla principal de la calculadora desde su nuevo archivo
import 'home.dart';

// ====================================================================
// ========================== APP PREMIUM SPLASH SCREEN ================
// ====================================================================

class AppPremiumSplashScreen extends StatefulWidget {
  const AppPremiumSplashScreen({super.key});

  @override
  State<AppPremiumSplashScreen> createState() => _AppPremiumSplashScreenState();
}

class _AppPremiumSplashScreenState extends State<AppPremiumSplashScreen> {
  // Claves para Shared Preferences (mantengo por si decides reusar)
  static const String _KEY_IS_PRO_VERSION_APP = 'isProVersionApp';
  static const String _KEY_TRIAL_START_DATE_APP = 'trialStartDateApp';

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isProVersion = prefs.getBool(_KEY_IS_PRO_VERSION_APP) ?? false;
    final String? trialStartDateString = prefs.getString(
      _KEY_TRIAL_START_DATE_APP,
    );

    if (isProVersion) {
      // Si ya tiene la versión Pro, ir directo a la aplicación principal
      _navigateToMainApp();
    } else if (trialStartDateString != null) {
      // Si hay una fecha de inicio de prueba, verificar si expiró
      final DateTime trialStartDate = DateTime.parse(trialStartDateString);
      final int daysElapsed = DateTime.now().difference(trialStartDate).inDays;

      if (daysElapsed < 7) {
        // 7 días de prueba
        _navigateToMainApp();
      } else {
        // Prueba expirada, quedarse en esta pantalla para mostrar la oferta
        print('DEBUG: La prueba gratuita ha expirado.');
        setState(() {}); // Forzar rebuild para mostrar el mensaje
      }
    } else {
      // No es Pro ni tiene prueba activa, mostrar pantalla
      print('DEBUG: No es PRO y no hay prueba activa. Mostrando oferta.');
      setState(() {});
    }
  }

  // Eliminé _startTrial y _purchaseProVersion porque ya no se usan

  void _skipOffer() {
    print('DEBUG: Oferta omitida, navegando a versión gratuita.');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CalculadoraPantalla()),
    );
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CalculadoraPantalla()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey.shade800,
                  Colors.blueGrey.shade600,
                  Colors.blueGrey.shade400,
                ],
                stops: const [0.1, 0.5, 0.9],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.calculate,
                      size: 120,
                      color: Colors.amber.shade200,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Calculadora PRO: Próximamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '¡Próximamente desbloquea todas las calculadoras!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Accede pronto a la Calculadora Científica, Eléctrica y el Conversor de Unidades, sin límites ni anuncios, y con todas las funciones futuras. ¡Estate atento!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton.icon(
                              onPressed: _skipOffer,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Usar versión gratuita'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: _skipOffer,
              tooltip: 'Omitir oferta y usar versión gratuita',
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ==================== MAIN APP ENTRY POINT ==========================
// ====================================================================

void main() {
  runApp(const CalculadoraApp());
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AppPremiumSplashScreen(),
    );
  }
}
