import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/dashboard_ekrani.dart';
import 'screens/istatistikler_ekrani.dart';
import 'screens/cihazlar_ekrani.dart';
import 'screens/ayarlar_ekrani.dart';
import 'screens/giris_ekrani.dart'; // Giriş ekranımızı ekledik

// Tüm uygulamanın temasını anlık olarak değiştirmemizi sağlayacak dinleyici
final ValueNotifier<ThemeMode> temaDinleyicisi = ValueNotifier(ThemeMode.light);

void main() async {
  // SharedPreferences ve Firebase'i main içinde kullanabilmek için Flutter motorunu başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat (Google Auth için zorunlu)
  await Firebase.initializeApp();

  // Kayıtlı tema ayarını okuyoruz
  final prefs = await SharedPreferences.getInstance();
  final bool karanlikMi = prefs.getBool('karanlik_mod') ?? false;

  temaDinleyicisi.value = karanlikMi ? ThemeMode.dark : ThemeMode.light;

  runApp(const EnerjiOptimizasyonuApp());
}

class EnerjiOptimizasyonuApp extends StatelessWidget {
  const EnerjiOptimizasyonuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: temaDinleyicisi,
        builder: (context, guncelTema, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Evsel Enerji',
            themeMode: guncelTema, // Tema dinleyiciden gelen bilgiye göre değişiyor

            // AYDINLIK TEMA AYARLARI
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF10B981),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey.shade50,
              textTheme: const TextTheme(
                titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.black87),
              ),
            ),

            // KARANLIK TEMA AYARLARI
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF10B981),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212), // Koyu arka plan
              cardColor: const Color(0xFF1E1E1E), // Kartlar için koyu renk
              textTheme: const TextTheme(
                titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
              ),
            ),

            // TRAFİK POLİSİ (Kullanıcı giriş yapmış mı?)
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                // Eğer giriş yapmış bir kullanıcı varsa doğrudan Ana Sisteme al
                if (snapshot.hasData) {
                  return const AnaNavigasyon();
                }
                // Giriş yapılmamışsa Giriş Ekranını göster
                return const GirisEkrani();
              },
            ),
          );
        }
    );
  }
}

class AnaNavigasyon extends StatefulWidget {
  const AnaNavigasyon({super.key});

  @override
  State<AnaNavigasyon> createState() => _AnaNavigasyonState();
}

class _AnaNavigasyonState extends State<AnaNavigasyon> {
  int _seciliSayfaIndex = 0;

  final List<Widget> _sayfalar = [
    const DashboardEkrani(),
    const IstatistiklerEkrani(),
    const CihazlarEkrani(),
    const AyarlarEkrani(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _sayfalar[_seciliSayfaIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSayfaIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _seciliSayfaIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Ana Ekran'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analiz'),
          NavigationDestination(icon: Icon(Icons.devices_outlined), selectedIcon: Icon(Icons.devices), label: 'Cihazlar'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}