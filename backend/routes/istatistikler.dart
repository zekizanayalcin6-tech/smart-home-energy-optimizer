import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  // AutoCAD listesine uygun yeni istatistik renk ve isim haritası
  final istatistikVerisi = [
    {'cihaz': 'Havuz Pompası', 'tuketim': 35.2, 'renk': '0xFF3B82F6'}, // Mavi
    {'cihaz': 'Klima 1', 'tuketim': 45.0, 'renk': '0xFF10B981'},       // Yeşil
    {'cihaz': 'Klima 2', 'tuketim': 42.5, 'renk': '0xFF059669'},       // Koyu Yeşil
    {'cihaz': 'Çam. Makinesi', 'tuketim': 18.4, 'renk': '0xFFF59E0B'}, // Turuncu
    {'cihaz': 'Bulaşık Mak.', 'tuketim': 15.2, 'renk': '0xFFD97706'},  // Koyu Turuncu
    {'cihaz': 'Fırın', 'tuketim': 22.0, 'renk': '0xFFEF4444'},         // Kırmızı
    {'cihaz': 'Aydınlatma', 'tuketim': 8.5, 'renk': '0xFFEC4899'},     // Pembe
  ];

  return Response.json(body: istatistikVerisi);
}