// lib/config.dart
class AppConfig {
  // BİLGİSAYARININ GÜNCEL IP ADRESİNİ BURAYA YAZ:
  // (Komut satırına 'ipconfig' veya Mac'te 'ifconfig' yazarak IPv4 adresini bulabilirsin)
  static const String sunucuIp = '10.114.9.47'; // Örn: 192.168.1.25 gibi değişmiş olabilir

  static const String apiUrl = 'http://$sunucuIp:8080/cihazlar';
  // YENİ EKLEDİĞİMİZ SATIR:
  static const String haftalikUrl = 'http://$sunucuIp:8080/haftalik_tuketim';
  // YENİ EKLEDİĞİMİZ AI BAĞLANTISI:
  static const String aiOneriUrl = 'http://$sunucuIp:8080/ai_onerileri';

  // YENİ EKLEDİĞİMİZ İSTATİSTİK BAĞLANTISI:
  static const String istatistikUrl = 'http://$sunucuIp:8080/istatistikler';
  static const String ayarlarUrl = 'http://$sunucuIp:8080/ayarlar';
}