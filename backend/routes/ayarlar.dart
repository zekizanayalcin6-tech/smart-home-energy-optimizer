import 'package:dart_frog/dart_frog.dart';
import '../lib/globals.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  // Mobil uygulama ayar durumunu okumak isterse
  if (request.method == HttpMethod.get) {
    return Response.json(body: {'agresifMod': agresifModAktif});
  }

  // Mobil uygulamadan yeni bir ayar gelirse (Tuşa basıldığında)
  if (request.method == HttpMethod.post) {
    final body = await request.json() as Map<String, dynamic>;
    if (body.containsKey('agresifMod')) {
      agresifModAktif = body['agresifMod'] as bool;
      print("⚙️ Sistem Ayarı Değişti: Agresif Mod = ${agresifModAktif ? 'AÇIK' : 'KAPALI'}");
    }
    return Response.json(body: {'mesaj': 'Ayarlar kaydedildi'});
  }

  return Response(statusCode: 405, body: 'İzin verilmeyen işlem');
}