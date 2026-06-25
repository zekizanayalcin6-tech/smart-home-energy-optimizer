import 'dart:io';
import 'dart:async';

void main() {
  // Senin güncel IP adresini içeren sunucu linkin
  final String serverUrl = 'http://10.114.9.47:8080/cihazlar';

  // AutoCAD Yükleme Cetveli Haritalandırması
  final List<int> cihazIds = [1, 2, 3, 4, 5, 6, 7];
  final List<String> cihazAdlari = [
    "Havuz Pompası", "Klima 1 (Salon)", "Klima 2 (Yatak Odası)",
    "Çamaşır Makinesi", "Bulaşık Makinesi", "Elektrikli Fırın", "Çevre Aydınlatma"
  ];
  final List<double> cihazGucleri = [600.0, 2000.0, 2000.0, 2500.0, 2500.0, 2000.0, 1500.0];

  int aktifCihazIndex = 0;
  int simuleSaat = DateTime.now().hour;

  print("🤖 Sanal Donanım (ESP32) Simülatörü Başlatıldı...");
  print("Durdurmak için terminalde Ctrl + C yapabilirsiniz.\n");

  // 5 saniyede bir çalışacak döngü (Arkadaşının C++ kodundaki delay(5000) mantığı)
  Timer.periodic(Duration(seconds: 5), (timer) async {
    int mevcutId = cihazIds[aktifCihazIndex];
    double hamGucKw = cihazGucleri[aktifCihazIndex] / 1000.0;
    double tarifeCarpani = 1.0;

    // Türkiye 3 Zamanlı Tarife Simülasyonu
    if (simuleSaat >= 17 && simuleSaat < 22) {
      tarifeCarpani = 1.2;
    } else if (simuleSaat >= 22 || simuleSaat < 6) {
      tarifeCarpani = 0.4;
    } else {
      tarifeCarpani = 0.8;
    }

    double hesaplananTuketim = hamGucKw * tarifeCarpani;

    // Veriyi JSON formatına çeviriyoruz (Tüketimi virgülden sonra 2 hane ile sınırla)
    String tuketimFormatli = hesaplananTuketim.toStringAsFixed(2);
    String jsonVerisi = '{"id": $mevcutId, "tuketim": $tuketimFormatli}';

    // Sunucuya POST isteği atma işlemi
    try {
      final HttpClient client = HttpClient();
      final request = await client.postUrl(Uri.parse(serverUrl));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonVerisi);

      final response = await request.close();

      print("----------------------------------------");
      print("Simüle Edilen Saat: $simuleSaat:00");
      print("Cihaz: ${cihazAdlari[aktifCihazIndex]}");
      print("Gönderilen Veri: $jsonVerisi");
      print("Sunucu Yanıt Kodu: ${response.statusCode}"); // 200 Dönerse Başarılı!

    } catch (e) {
      print("Bağlantı hatası: Sunucu çalışmıyor olabilir. Hata: $e");
    }

    // Bir sonraki cihaza ve saate geç
    aktifCihazIndex = (aktifCihazIndex + 1) % cihazIds.length;

  });
}