import 'dart:io';
import 'dart:ffi';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  late Database _db;

  DbHelper._init() {
    // Windows için DLL dosyasının tam yolunu belirtiyoruz
    open.overrideFor(OperatingSystem.windows, _openOnWindows);

    // Veritabanı dosyasını açıyoruz veya oluşturuyoruz
    _db = sqlite3.open('evsel_enerji.db');
    _tablolariOlustur();
  }

  // FFI kullanarak DLL dosyasını yükleyen yardımcı fonksiyon
  DynamicLibrary _openOnWindows() {
    final scriptDir = File(Platform.script.toFilePath()).parent.path;
    // DLL dosyasının backend klasöründe olduğunu varsayıyoruz
    final libraryNextToScript = File('$scriptDir\\sqlite3.dll');

    // Eğer sunucu çalıştırılırken script dizini farklı görünüyorsa, doğrudan geçerli dizine bakıyoruz
    final currentDirLibrary = File('${Directory.current.path}\\sqlite3.dll');

    if (currentDirLibrary.existsSync()) {
      return DynamicLibrary.open(currentDirLibrary.path);
    } else if (libraryNextToScript.existsSync()) {
      return DynamicLibrary.open(libraryNextToScript.path);
    }

    // Eğer bulamazsa, sistemin System32 gibi kendi yollarında aramasını bekliyoruz
    return DynamicLibrary.open('sqlite3.dll');
  }

  void _tablolariOlustur() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cihazlar (
        id INTEGER PRIMARY KEY,
        ad TEXT,
        oda TEXT,
        acikMi INTEGER,
        tuketim REAL
      )
    ''');

    // Arkadaşının AutoCAD Yükleme Cetveline Göre 7 Yeni Cihaz
    final ResultSet result = _db.select('SELECT COUNT(*) as count FROM cihazlar');
    if (result.first['count'] == 0) {
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (1, 'Havuz Pompası', 'Bahçe', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (2, 'Klima 1', 'Salon', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (3, 'Klima 2', 'Yatak Odası', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (4, 'Çamaşır Makinesi', 'Banyo', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (5, 'Bulaşık Makinesi', 'Mutfak', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (6, 'Elektrikli Fırın', 'Mutfak', 0, 0.0)");
      _db.execute("INSERT INTO cihazlar (id, ad, oda, acikMi, tuketim) VALUES (7, 'Çevre Aydınlatma', 'Bahçe', 0, 0.0)");
    }
  }

  List<Map<String, dynamic>> cihazlariGetir() {
    final ResultSet result = _db.select('SELECT * FROM cihazlar');
    return result.map((row) => {
      'id': row['id'],
      'ad': row['ad'],
      'oda': row['oda'],
      'acikMi': row['acikMi'] == 1,
      'tuketim': row['tuketim'],
    }).toList();
  }

  void cihazDurumuGuncelle(int id, bool acikMi) {
    if (acikMi) {
      _db.execute('UPDATE cihazlar SET acikMi = 1 WHERE id = ?', [id]);
    } else {
      _db.execute('UPDATE cihazlar SET acikMi = 0, tuketim = 0.0 WHERE id = ?', [id]);
    }
  }

  void cihazTuketimGuncelle(int id, double tuketim) {
    bool acikMi = tuketim > 0;
    _db.execute('UPDATE cihazlar SET tuketim = ?, acikMi = ? WHERE id = ?', [tuketim, acikMi ? 1 : 0, id]);
  }
}