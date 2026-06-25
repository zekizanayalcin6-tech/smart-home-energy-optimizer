# 🌍 Yapay Zekâ Destekli Evsel Enerji Optimizasyonu ve Dijital İkiz Uygulaması

Bu proje, evsel enerji tüketimini gerçek zamanlı izlemek ve yapay zekâ destekli otonom kararlarla (Standby avcısı, puant saati yönetimi) enerji israfını en aza indirmek için geliştirilmiş çok disiplinli bir IoT / Akıllı Ev sistemidir.

## 🚀 Teknolojik Mimari (Tech Stack)
* **Frontend:** Flutter, Dart, Firebase Auth, SharedPreferences
* **Backend:** Dart Frog (RESTful API, GET/POST/PUT)
* **Veritabanı:** SQLite
* **Donanım Simülasyonu (Dijital İkiz):** Fiziksel sensörler yerine ESP32 mikrodenetleyicisini ve röleleri simüle eden asenkron Dart betiği.

## 💡 Temel Özellikler
* **Canlı Tüketim Takibi:** Cihazların anlık kW tüketimlerinin asenkron olarak sunucudan çekilmesi.
* **Sanal Röle Kontrolü:** Mobil arayüz üzerinden cihaz şalterlerinin manuel kontrolü ve Optimistic UI güncellemeleri.
* **Yapay Zekâ Otopilotu:** Gece (02:00-06:00) bekleme modundaki cihazların fişini çeken ve 17:00-22:00 puant saatlerinde ağır yükleri engelleyen agresif otonom sistem.

## ⚙️ Nasıl Çalıştırılır? (How to Run)
1. Backend klasöründe sunucuyu başlatın: `dart pub global run dart_frog_cli:dart_frog dev`
2. ESP32 simülatörünü çalıştırın: `dart run sanal_esp32.dart`
3. Ana dizinde mobil uygulamayı derleyin: `flutter run`
