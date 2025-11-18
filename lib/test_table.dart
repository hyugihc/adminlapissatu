import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin_lapissatu/atoms/widgets_data.dart';

class TestChart extends StatelessWidget {
  const TestChart({super.key});

  static const Map<String, dynamic> atribute = {
    'category': 0,
    'chart': 1,
    'column': [
      {'id_row': 0},
      {'tahun': 4},
      {'biaya': 7},
      {'tanggal': 6},
      {'keterangan': 2},
      {'jumlah': 1},
      {'bulan': 5},
      {'created_at': 3},
    ],
  };

  static List<Map<String, dynamic>> data = [
    {
      'id_row': 1,
      'tahun': 2023,
      'biaya': 150000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Massal',
      'jumlah': 100,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 2,
      'tahun': 2024,
      'biaya': 250000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Individu',
      'jumlah': 50,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 3,
      'tahun': 2022,
      'biaya': 175000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Keluarga',
      'jumlah': 75,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 4,
      'tahun': 2021,
      'biaya': 200000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Komunitas',
      'jumlah': 120,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 5,
      'tahun': 2020,
      'biaya': 300000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Perusahaan',
      'jumlah': 200,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 6,
      'tahun': 2019,
      'biaya': 225000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Sekolah',
      'jumlah': 80,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 7,
      'tahun': 2018,
      'biaya': 275000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Universitas',
      'jumlah': 150,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 8,
      'tahun': 2017,
      'biaya': 350000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Pemerintah',
      'jumlah': 300,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 9,
      'tahun': 2016,
      'biaya': 400000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Lembaga',
      'jumlah': 250,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
    {
      'id_row': 10,
      'tahun': 2015,
      'biaya': 450000,
      'tanggal': Timestamp.now(),
      'keterangan': 'Penggenjotan Organisasi',
      'jumlah': 180,
      'bulan': Timestamp.now(),
      'created_at': Timestamp.now(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Page')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Center(
              child: DesignedTableData(atribute: atribute, data: data),
            ),
            Center(
              child: DesignedBarChart(atribute: atribute, data: data),
            ),
            Center(
              child: DesignedLineChart(atribute: atribute, data: data),
            ),
          ],
        ),
      ),
    );
  }
}
