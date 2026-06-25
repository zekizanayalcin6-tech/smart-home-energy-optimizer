import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Hatanın çözüldüğü kritik import

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  bool _yukleniyor = false;

  Future<void> _googleIleGirisYap() async {
    setState(() => _yukleniyor = true);
    try {
      // 1. Yeni sistemde önce eklentiyi başlatıyoruz
      await GoogleSignIn.instance.initialize();

      // 2. signIn() yerine authenticate() kullanıyoruz
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        setState(() => _yukleniyor = false);
        return; // Kullanıcı pencereyi kapattı
      }

      // 3. Başındaki "await" kelimesini sildik
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Firebase için artık sadece idToken vermek yeterli
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Giriş başarılı olunca main.dart'taki Trafik Polisi otomatik Dashboard'a atacak

    } catch (e) {
      // Widget hala ekrandaysa hata mesajını göster (Async gap uyarısını çözer)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giriş başarısız: $e')));
      }
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.bolt_rounded, size: 80, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 32),
              const Text('Evsel Enerji Optimizasyonu', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
              const SizedBox(height: 16),
              const Text('Yapay zeka ile enerji tüketiminizi analiz edin, faturalarınızı düşürün ve karbon ayak izinizi küçültün.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5)),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black12, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _yukleniyor ? null : _googleIleGirisYap,
                  child: _yukleniyor
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          // Eğer internet giderse veya resim bozulursa ekranı çökertmek yerine yedek bir ikon göster
                          return const Icon(Icons.account_circle, size: 24, color: Colors.black54);
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text('Google ile Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Giriş yaparak Gizlilik Politikası ve Kullanım Şartlarını kabul etmiş olursunuz.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}