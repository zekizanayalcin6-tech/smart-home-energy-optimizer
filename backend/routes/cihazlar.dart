import 'package:dart_frog/dart_frog.dart';
import '../lib/database.dart';
import '../lib/globals.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  // 1. MOBİL UYGULAMA LİSTEYİ İSTERSE (GET)
  if (request.method == HttpMethod.get) {
    final cihazlar = DbHelper.instance.cihazlariGetir();
    return Response.json(body: cihazlar);
  }

  // 2. MOBİL UYGULAMADAN MANUEL AÇMA/KAPAMA İSTEĞİ GELİRSE (PUT)
  if (request.method == HttpMethod.put) {
    try {
      final body = await request.json() as Map<String, dynamic>;
      int id = body['id'] as int;
      bool acikMi = body['acikMi'] as bool;

      // Veritabanını telefonun isteğine göre manuel olarak güncelle
      DbHelper.instance.cihazDurumuGuncelle(id, acikMi);
      return Response.json(body: {'mesaj': 'Cihaz manuel olarak güncellendi'});
    } catch (e) {
      return Response(statusCode: 400, body: 'Bozuk JSON formatı');
    }
  }

  // 3. SANAL ESP32'DEN ANLIK TÜKETİM VERİSİ GELİRSE (POST)
  if (request.method == HttpMethod.post) {
    try {
      final body = await request.json() as Map<String, dynamic>;
      int id = body['id'] as int;
      double tuketim = (body['tuketim'] as num).toDouble();

      // 🧠 AGRESIF MOD: YAPAY ZEKA MÜDAHALESİ
      if (agresifModAktif) {
        DateTime suAn = DateTime.now();
        int saat = suAn.hour;

        // KURAL 1: Puant Saatinde Ağır Yüke İzin Verme (17:00-22:00)
        // 4: Çamaşır Makinesi, 5: Bulaşık Makinesi
        if ((saat >= 17 && saat < 22) && (id == 4 || id == 5) && tuketim > 0) {
          print("🚨 AGRESIF MOD: Puant saatinde ağır yük engellendi! (Cihaz ID: $id)");
          tuketim = 0.0; // Elektriği kes
        }

        // KURAL 2: Gece Standby Avcısı (02:00-06:00)
        // Eğer cihaz çalışmıyor ama fişe takılı olduğu için azıcık (0.1 kW altı) akım çekiyorsa
        if ((saat >= 2 && saat < 6) && tuketim > 0 && tuketim < 0.1) {
          print("🚨 AGRESIF MOD: Gece bekleme modundaki cihaz kapatıldı! (Cihaz ID: $id)");
          tuketim = 0.0; // Fişi çek
        }
      }

      // Filtrelenmiş tüketim değerini veritabanına kaydet
      DbHelper.instance.cihazTuketimGuncelle(id, tuketim);
      return Response.json(body: {'mesaj': 'Başarılı', 'islenen_tuketim': tuketim});
    } catch (e) {
      return Response(statusCode: 400, body: 'Bozuk JSON formatı');
    }
  }

  return Response(statusCode: 405, body: 'Geçersiz metod');
}