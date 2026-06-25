import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // HAFIZA İÇİN EKLENDİ
import '../config.dart';
import '../main.dart'; // ANA TEMA MOTORUNA (temaDinleyicisi) ULAŞMAK İÇİN EKLENDİ

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  // _karanlikMod lokal değişkenini sildik, artık doğrudan ana sistemi dinleyeceğiz.
  bool _aiBildirimleri = true;
  bool _enerjiTasarrufModu = false;

  @override
  void initState() {
    super.initState();
    _bildirimAyariniYukle();
  }

  Future<void> _bildirimAyariniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiBildirimleri = prefs.getBool('ai_bildirim_ayari') ?? true;
      _enerjiTasarrufModu = prefs.getBool('ai_otopilot_ayari') ?? false; // YENİ EKLENDİ: Otopilot hafızadan okunuyor
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aktif kullanıcıyı Firebase'den çekiyoruz
    final User? user = FirebaseAuth.instance.currentUser;
    final String kullaniciAdi = user?.displayName ?? "Kullanıcı Bulunamadı";
    final String kullaniciEmail = user?.email ?? "";
    final String profilFoto = user?.photoURL ?? "https://cdn-icons-png.flaticon.com/512/149/149071.png";

    // SİSTEMİN GERÇEK TEMA DURUMUNU OKUYORUZ
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            'Profil ve Ayarlar',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          // 1. DİNAMİK PROFİL KARTI VE ÇIKIŞ YAP
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn.instance.signOut();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: NetworkImage(profilFoto),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            kullaniciAdi,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                        ),
                        const SizedBox(height: 4),
                        Text(
                            kullaniciEmail,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.logout_rounded, color: Colors.redAccent)
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 2. SİSTEM AYARLARI
          Text(
              'Uygulama Ayarları',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800)
          ),
          const SizedBox(height: 12),

          // KARANLIK MOD BUTONU GÜNCELLENDİ
          _buildAyarSecenegi(
            icon: Icons.dark_mode_rounded,
            title: 'Karanlık Tema',
            subtitle: 'Göz yorgunluğunu azaltır',
            value: isDark,
            onChanged: (val) async {
              // 1. Tüm uygulamanın temasını o saniye anında değiştirir (Tüm sayfalara yansır)
              temaDinleyicisi.value = val ? ThemeMode.dark : ThemeMode.light;

              // 2. Uygulama tamamen kapatılıp açıldığında bu tercihi hatırlaması için hafızaya kaydeder
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('karanlik_mod', val);
            },
            isDark: isDark,
          ),

          _buildAyarSecenegi(
            icon: Icons.notifications_active_rounded,
            title: 'Yapay Zeka Bildirimleri',
            subtitle: 'Tasarruf fırsatlarını bildirir',
            value: _aiBildirimleri,
            onChanged: (val) async {
              setState(() => _aiBildirimleri = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('ai_bildirim_ayari', val);
            },
            isDark: isDark,
          ),

          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981)),
              ),
              title: Row(
                children: [
                  // Metnin ekrandan taşmasını engellemek için Expanded ekledik
                  Expanded(
                    child: Text(
                      'Yapay Zeka (AI) Otopilotu',
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      overflow: TextOverflow.ellipsis, // Eğer iyice daralırsa sonuna üç nokta (...) koysun
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _agresifModBilgiGoster(context, isDark),
                    child: Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue.shade400),
                  )
                ],
              ),
              subtitle: Text('Sistem fatura odaklı otonom kararlar alır', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              value: _enerjiTasarrufModu,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF10B981),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              onChanged: (val) async {
                setState(() => _enerjiTasarrufModu = val);

                // YENİ EKLENDİ: Otopilot durumu telefonun hafızasına kazınıyor
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('ai_otopilot_ayari', val);

                try {
                  await http.post(
                    Uri.parse(AppConfig.ayarlarUrl),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'agresifMod': val}),
                  );
                } catch (e) {
                  debugPrint("Ayar gönderilemedi: $e");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyarSecenegi({required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF10B981))),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        value: value,
        activeColor: Colors.white, activeTrackColor: const Color(0xFF10B981),
        inactiveThumbColor: Colors.grey.shade400, inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        onChanged: onChanged,
      ),
    );
  }

  void _agresifModBilgiGoster(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // YENİ: Pencerenin ekrana daha rahat yayılmasını sağlar
      builder: (context) => Container(
        // YENİ: Alt kısımdan biraz daha boşluk bırakarak tam sığmasını garantiler
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // YENİ: Taşmayı engelleyen ve aşağı kaydırmayı sağlayan sihirli widget
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Yapay Zeka Otopilotu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Bu mod aktif edildiğinde, yapay zeka evinizin enerji kontrolünü kısmen devralır ve fatura maliyetini en aza indirmek için şu eylemleri otomatik gerçekleştirir:',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              _bilgiMaddesi(Icons.power_off_rounded, 'Standby Avcısı', 'Gece 02:00 - 06:00 arası bekleme modunda boşuna elektrik çeken cihazların gücünü fiziksel olarak keser.', isDark),
              _bilgiMaddesi(Icons.schedule_rounded, 'Puant Saati Frenlemesi', '17:00 - 22:00 arası elektrik birim fiyatı en pahalı seviyededir. Sistem, acil olmayan ağır yükleri gece tarifesine erteler.', isDark),
              _bilgiMaddesi(Icons.timer_off_rounded, 'Açık Unutulma Koruması', 'Gereksiz yere uzun süre çalışan cihazları (örn: gündüz yanan çevre aydınlatması) tespit edip otomatik kapatır.', isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anladım', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _bilgiMaddesi(IconData icon, String baslik, String aciklama, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(aciklama, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}