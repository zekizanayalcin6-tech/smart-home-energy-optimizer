import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class IstatistiklerEkrani extends StatefulWidget {
  const IstatistiklerEkrani({super.key});

  @override
  State<IstatistiklerEkrani> createState() => _IstatistiklerEkraniState();
}

class _IstatistiklerEkraniState extends State<IstatistiklerEkrani> {
  List<dynamic> _istatistikVerisi = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _istatistikleriGetir();
  }

  Future<void> _istatistikleriGetir() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.istatistikUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _istatistikVerisi = json.decode(response.body);
            _yukleniyor = false;
          });
        }
      }
    } catch (e) {
      print('İstatistik Bağlantı Hatası: $e');
      if (mounted) setState(() => _yukleniyor = false);
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
        title: Text('Detaylı İstatistikler', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: false,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cihaz Bazlı Tüketim Dağılımı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800)),
            const SizedBox(height: 24),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 50,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= _istatistikVerisi.length) return const Text('');
                          // İsimleri kısaltarak yazıyoruz
                          String tamIsim = _istatistikVerisi[value.toInt()]['cihaz'];
                          String kisaIsim = tamIsim.length > 8 ? '${tamIsim.substring(0, 8)}..' : tamIsim;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(kisaIsim, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_istatistikVerisi.length, (index) {
                    final double tuketim = (_istatistikVerisi[index]['tuketim'] as num).toDouble();
                    final String hexColor = _istatistikVerisi[index]['renk'];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: tuketim,
                          color: Color(int.parse(hexColor)),
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 50,
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Renk lejantı (Açıklamalar)
            Expanded(
              child: ListView.builder(
                itemCount: _istatistikVerisi.length,
                itemBuilder: (context, index) {
                  final cihaz = _istatistikVerisi[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(color: Color(int.parse(cihaz['renk'])), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Text(cihaz['cihaz'], style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                        const Spacer(),
                        Text('${cihaz['tuketim']} kW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}