import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../config.dart';

class CihazlarEkrani extends StatefulWidget {
  const CihazlarEkrani({super.key});

  @override
  State<CihazlarEkrani> createState() => _CihazlarEkraniState();
}

class _CihazlarEkraniState extends State<CihazlarEkrani> {
  bool _aiModuAktif = true;
  List<dynamic> _cihazlar = [];
  bool _yukleniyor = true;

  Timer? _veriGuncelleyici;

  @override
  void initState() {
    super.initState();
    _tercihiYukle();
    _cihazlariGetir();

    _veriGuncelleyici = Timer.periodic(const Duration(seconds: 2), (timer) {
      _cihazlariGetir(gizliYenileme: true);
    });
  }

  @override
  void dispose() {
    _veriGuncelleyici?.cancel();
    super.dispose();
  }

  Future<void> _tercihiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiModuAktif = prefs.getBool('ai_modu') ?? true;
    });
  }

  Future<void> _tercihiKaydet(bool deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_modu', deger);
    setState(() {
      _aiModuAktif = deger;
    });
  }

  Future<void> _cihazlariGetir({bool gizliYenileme = false}) async {
    if (!gizliYenileme && _cihazlar.isEmpty) {
      if (mounted) setState(() => _yukleniyor = true);
    }

    try {
      final response = await http.get(Uri.parse(AppConfig.apiUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cihazlar = json.decode(response.body);
            _yukleniyor = false;
          });
        }
      }
    } catch (e) {
      print('Sessiz Bağlantı Hatası: $e');
      if (!gizliYenileme && mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _cihazDurumunuGuncelle(int id, bool yeniDurum, int index) async {
    setState(() {
      _cihazlar[index]['acikMi'] = yeniDurum;

      if (yeniDurum == false) {
        _cihazlar[index]['tuketim'] = 0.0;
      }
    });

    try {
      final response = await http.put(
        Uri.parse(AppConfig.apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'acikMi': yeniDurum}),
      );

      if (response.statusCode != 200) {
        setState(() => _cihazlar[index]['acikMi'] = !yeniDurum);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sunucu hatası: Cihaz güncellenemedi.')));
      }
    } catch (e) {
      setState(() => _cihazlar[index]['acikMi'] = !yeniDurum);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ağ hatası: Sunucuya ulaşılamıyor.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cihaz Yönetimi', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _aiModuAktif ? const Color(0xFF10B981) : (isDark ? Theme.of(context).cardColor : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _aiModuAktif ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                boxShadow: _aiModuAktif && !isDark ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manuel Kontrol Kilidi', style: TextStyle(color: _aiModuAktif ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(_aiModuAktif ? 'Cihazlara elle müdahale kapatıldı.' : 'Manuel kontrol modundasınız.', style: TextStyle(color: _aiModuAktif ? Colors.white70 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600), fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _aiModuAktif,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF047857),
                    inactiveThumbColor: Colors.grey.shade400,
                    onChanged: (deger) {
                      _tercihiKaydet(deger);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _yukleniyor
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : _cihazlar.isEmpty
                  ? Center(child: Text('Cihaz verisi bulunamadı. Sunucu IP: ${AppConfig.sunucuIp}'))
                  : GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
                itemCount: _cihazlar.length,
                itemBuilder: (context, index) => _cihazKarti(_cihazlar[index], index, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cihazKarti(Map<String, dynamic> cihaz, int index, bool isDark) {
    bool acikMi = cihaz['acikMi'];
    IconData ikon = Icons.devices;
    if (cihaz['ad'] == 'Klima') ikon = Icons.ac_unit;
    if (cihaz['ad'] == 'Buzdolabı') ikon = Icons.kitchen;
    if (cihaz['ad'] == 'Televizyon') ikon = Icons.tv;
    if (cihaz['ad'] == 'Çamaşır Makinesi') ikon = Icons.local_laundry_service;
    if (cihaz['ad'] == 'Çalışma Lambası') ikon = Icons.light;
    if (cihaz['ad'] == 'Su Isıtıcı') ikon = Icons.coffee_maker_outlined;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: acikMi
            ? (isDark ? Theme.of(context).cardColor : Colors.white)
            : (isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: acikMi ? const Color(0xFF10B981).withOpacity(0.3) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        boxShadow: acikMi && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(ikon, color: acikMi ? const Color(0xFF10B981) : Colors.grey.shade500, size: 28),
              Switch(
                value: acikMi,
                activeColor: const Color(0xFF10B981),
                onChanged: _aiModuAktif ? null : (deger) {
                  _cihazDurumunuGuncelle(cihaz['id'], deger, index);
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cihaz['ad'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Text(cihaz['oda'], style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 8),
              Text('${cihaz['tuketim']} kW/h', style: TextStyle(color: acikMi ? const Color(0xFF10B981) : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}