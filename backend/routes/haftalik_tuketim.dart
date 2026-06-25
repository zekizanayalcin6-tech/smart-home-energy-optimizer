import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  // Pazartesi'den Pazar'a kadar olan 7 günlük örnek tüketim verisi (kWh cinsinden)
  final haftalikVeri = [
    {'gun': 'Pzt', 'deger': 12.5},
    {'gun': 'Sal', 'deger': 15.2},
    {'gun': 'Çar', 'deger': 10.8},
    {'gun': 'Per', 'deger': 18.4},
    {'gun': 'Cum', 'deger': 14.1},
    {'gun': 'Cmt', 'deger': 8.5},
    {'gun': 'Paz', 'deger': 11.0},
  ];

  return Response.json(body: haftalikVeri);
}