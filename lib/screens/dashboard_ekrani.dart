import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config.dart';

class DashboardEkrani extends StatefulWidget {
  const DashboardEkrani({super.key});

  @override
  State<DashboardEkrani> createState() => _DashboardEkraniState();
}

class _DashboardEkraniState extends State<DashboardEkrani> {
  double anlikToplamTuketim = 0.0;
  bool _yukleniyor = true;
  Timer? _veriGuncelleyici;

  List<FlSpot> _grafikNoktalari = [];

  // YAPAY ZEKA İÇİN EKLENEN DEĞİŞKENLER
  String aiOneriBaslik = 'AI Analizi Bekleniyor...';
  String aiOneriMesaji = 'Sistem tüketim alışkanlıklarınızı inceliyor.';
  double aiTasarrufMiktari = 0.0;

  @override
  void initState() {
    super.initState();
    _ilkVerileriGetir();

    _veriGuncelleyici = Timer.periodic(const Duration(seconds: 2), (timer) {
      _toplamTuketimiHesapla(gizliYenileme: true);
    });
  }

  @override
  void dispose() {
    _veriGuncelleyici?.cancel();
    super.dispose();
  }

  Future<void> _ilkVerileriGetir() async {
    setState(() => _yukleniyor = true);
    await Future.wait([
      _toplamTuketimiHesapla(gizliYenileme: true),
      _haftalikGrafikVerisiniGetir(),
      _aiOnerisiniGetir(), // YAPAY ZEKA VERİSİNİ DE ÇEKİYORUZ
    ]);
    if (mounted) {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _toplamTuketimiHesapla({bool gizliYenileme = false}) async {
    try {
      final response = await http.get(Uri.parse(AppConfig.apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> cihazlar = json.decode(response.body);
        double toplam = 0.0;
        for (var cihaz in cihazlar) {
          toplam += (cihaz['tuketim'] as num).toDouble();
        }
        if(mounted) {
          setState(() {
            anlikToplamTuketim = toplam;
          });
        }
      }
    } catch (e) {
      print('Dashboard Cihaz Bağlantı Hatası: $e');
    }
  }

  Future<void> _haftalikGrafikVerisiniGetir() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.haftalikUrl));
      if (response.statusCode == 200) {
        final List<dynamic> veriListesi = json.decode(response.body);
        List<FlSpot> noktalar = [];
        for (int i = 0; i < veriListesi.length; i++) {
          noktalar.add(FlSpot(i.toDouble(), (veriListesi[i]['deger'] as num).toDouble()));
        }
        if (mounted) {
          setState(() {
            _grafikNoktalari = noktalar;
          });
        }
      }
    } catch (e) {
      print('Grafik Verisi Çekilemedi: $e');
    }
  }

  // YENİ: SUNUCUDAN YAPAY ZEKA TAVSİYESİNİ ÇEKEN FONKSİYON
  Future<void> _aiOnerisiniGetir() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.aiOneriUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            aiOneriBaslik = data['baslik'];
            aiOneriMesaji = data['mesaj'];
            aiTasarrufMiktari = (data['tasarrufMiktari'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      print('AI Verisi Çekilemedi: $e');
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
        title: Text('Enerji Analizi', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: false,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _bilgiKarti('Anlık Tüketim', '${anlikToplamTuketim.toStringAsFixed(1)} kW', Icons.bolt, Colors.orange, isDark)),
                const SizedBox(width: 16),
                // AI TASARRUFU ARTIK DİNAMİK
                Expanded(child: _bilgiKarti('AI Tasarrufu', '${aiTasarrufMiktari.toStringAsFixed(1)} kW', Icons.eco, const Color(0xFF10B981), isDark)),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'Son 7 Günün Tüketimi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800),
            ),
            const SizedBox(height: 16),

            Container(
              height: 300,
              padding: const EdgeInsets.only(right: 16, left: 8, top: 24, bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: _grafikNoktalari.isEmpty
                  ? const Center(child: Text('Grafik verisi yüklenemedi.'))
                  : LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                          if (value >= 0 && value < 7) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(gunler[value.toInt()], style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 20,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _grafikNoktalari,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF10B981), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BAŞLIK VE MESAJ ARTIK SUNUCUDAN GELİYOR
                        Text(aiOneriBaslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF10B981))),
                        const SizedBox(height: 4),
                        Text(aiOneriMesaji, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.green.shade800, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _bilgiKarti(String baslik, String deger, IconData ikon, Color renk, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: renk.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(ikon, color: renk, size: 24),
          ),
          const SizedBox(height: 16),
          Text(deger, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(baslik, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}