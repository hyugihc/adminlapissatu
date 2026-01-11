import 'package:admin_lapissatu/atoms/enum_var.dart';

class AppVar {
  static const Map<Category, List<String>> subCategory = {
    Category.penduduk: [
      'Kependudukan dan Migrasi',
      'Tenaga Kerja',
      'Pendidikan',
      'Kesehatan',
      'Konsumsi dan Pendapatan',
      'Perlindungan Sosial',
      'Pemukiman dan Perumahan',
      'Hukum dan Kriminal',
      'Budaya',
      'Aktivitas Politik dan Komunitas Lainnya',
      'Penggunaan Waktu',
    ],
    Category.ekonomi: [
      'Statistik Makroekonomi',
      'Neraca Ekonomi',
      'Statistik Bisnis',
      'Statistik Sektoral',
      'Keuangan Pemerintah, Fiskal dan Statistik Sektor Publik',
      'Perdagangan Internasional dan Neraca Pembayaran',
      'Harga-Harga',
      'Biaya Tenaga Kerja',
      'Ilmu Pengetahuan, Teknologi, dan Inovasi',
      'Pertanian, Kehutanan, Perikanan',
      'Energi',
      'Pertambangan, Manufaktur, Konstruksi',
      'Transportasi',
      'Pariwisata',
      'Perbankan, Asuransi dan Finansial',
    ],
    Category.multidomain: [
      'Lingkungan',
      'Statistik Regional dan Statistik Area Kecil',
      'Statistik dan Indikator Multi-Domain',
      'Buku Tahunan dan Ringkasan Sejenis',
      'Kondisi Tempat Tinggal, Kemiskinan, dan Permasalahan Sosial Lintas Sektor',
      'Gender dan Kelompok Populasi Khusus',
      'Masyarakat Informasi',
      'Globalisasi',
      'Indikator Millenium Development Goals (MDGs)',
      'Perkembangan Berkelanjutan',
      'Kewiraswastaan',
    ],
  };

  static const Map<String, int> monthMap = {
    // Januari
    'januari': 1, 'january': 1, 'jan': 1,
    // Februari
    'februari': 2, 'february': 2, 'feb': 2,
    // Maret
    'maret': 3, 'march': 3, 'mar': 3,
    // April
    'april': 4, 'apr': 4,
    // Mei
    'mei': 5, 'may': 5,
    // Juni
    'juni': 6, 'june': 6, 'jun': 6,
    // Juli
    'juli': 7, 'july': 7, 'jul': 7,
    // Agustus (ID sering menyingkat Agt atau Agu)
    'agustus': 8, 'august': 8, 'agu': 8, 'agt': 8, 'aug': 8,
    // September
    'september': 9, 'sep': 9, 'sept': 9,
    // Oktober
    'oktober': 10, 'october': 10, 'okt': 10, 'oct': 10,
    // November
    'november': 11, 'nov': 11,
    // Desember
    'desember': 12, 'december': 12, 'des': 12, 'dec': 12,
  };
}
