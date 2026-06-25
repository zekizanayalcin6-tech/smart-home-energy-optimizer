import 'package:dart_frog/dart_frog.dart';

// Yapay zekadan gelecek veriyi tutacağımız geçici bellek
Map<String, dynamic> guncelOneri = {
  'baslik': 'Sistem Analizi Sürüyor...',
  'mesaj': 'Yapay zeka modeli anlık tüketim verilerinizi işliyor.',
  'tasarrufMiktari': 0.0
};

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  // 1. MOBİL UYGULAMA BU KISMI OKUR (GET)
  if (request.method == HttpMethod.get) {
    return Response.json(body: guncelOneri);
  }

  // 2. PYTHON (YAPAY ZEKA) BU KISMA YENİ UYARI GÖNDERİR (POST)
  else if (request.method == HttpMethod.post) {
    try {
      final body = await request.json() as Map<String, dynamic>;

      // Gelen yeni uyarıyı belleğe kaydediyoruz
      guncelOneri = {
        'baslik': body['baslik'],
        'mesaj': body['mesaj'],
        'tasarrufMiktari': (body['tasarrufMiktari'] as num).toDouble(),
      };

      return Response.json(body: {'mesaj': 'Sunucu: Yeni Yapay Zeka uyarısı başarıyla alındı!'});
    } catch (e) {
      return Response.json(statusCode: 400, body: {'hata': 'Bozuk AI verisi'});
    }
  }

  return Response(statusCode: 405, body: 'Sadece GET ve POST desteklenir.');
}