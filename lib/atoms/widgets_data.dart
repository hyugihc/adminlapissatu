import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin_lapissatu/atoms/enum_var.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

class DesignedTableData extends StatefulWidget {
  final Map<String, dynamic> atribute;
  final List<Map<String, dynamic>> data;
  final bool isPreviewMode;
  final Map<String, Function>? functionList;
  const DesignedTableData({
    super.key,
    required this.atribute,
    required this.data,
    this.isPreviewMode = false,
    this.functionList,
  });

  @override
  State<DesignedTableData> createState() {
    return _DesignedTableData();
  }
}

class _DesignedTableData extends State<DesignedTableData> {
  late List<Map<String, dynamic>> _columnStructure;
  late int _totalColumns;

  int? _sortColumnIndex;
  bool _isSortAscending = true;

  @override
  void initState() {
    super.initState();
    _columnStructure = List<Map<String, dynamic>>.from(
      widget.atribute['column'],
    );
    _totalColumns = _columnStructure.length - 1;
    print(widget.data);
  }

  void sortAlgorithm(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _isSortAscending = ascending;

    final String sortColumnName = _columnStructure[columnIndex].keys.first;

    widget.data.sort((a, b) {
      final valA = a[sortColumnName];
      final valB = b[sortColumnName];

      if (valA == null && valB == null) return 0;
      if (valA == null) return 1;
      if (valB == null) return -1;

      int result;
      if (valA is Comparable && valB is Comparable) {
        result = valA.compareTo(valB);
      } else {
        result = valA.toString().compareTo(valB.toString());
      }
      return ascending ? result : -result;
    });
  }

  void _onSort(int columnIndex, bool ascending, {bool firstSort = false}) {
    if (firstSort) {
      sortAlgorithm(columnIndex, ascending);
    } else {
      setState(() {
        sortAlgorithm(columnIndex, ascending);
      });
    }
  }

  List<DataColumn> _buildColumns() {
    final tempList = _columnStructure
        .map(
          (val) => DataColumn2(
            onSort: _onSort,
            label: Center(
              child: val.keys.first == 'id_row'
                  ? const Text('')
                  : Text(val.keys.first),
            ),
            fixedWidth: val.keys.first == 'id_row'
                ? 30
                : val.values.first == 4
                ? 50
                : val.values.first == 3
                ? 90
                : null,
          ),
        )
        .toList();
    if (widget.isPreviewMode) {
      tempList.add(
        DataColumn2(label: Center(child: Text('Aksi')), fixedWidth: 120),
      );
    }
    return tempList;
  }

  String _formatDisplayValue({required DataType tipe, required dynamic value}) {
    if (value is Timestamp) {
      value = value.toDate();
    }
    if (value == null) {
      return '';
    }
    switch (tipe) {
      case DataType.integer:
        return value.toString();
      case DataType.float:
        return value.toString().replaceAll('.', ',');
      case DataType.string:
        return value.toString();
      case DataType.datetime:
        return DateFormat('dd-MM-yyyy HH:mm').format(value);
      case DataType.year:
        value = value.toInt();
        return value.toString();
      case DataType.month:
        if (value is int) return 'TEMPEK';
        return DateFormat('MMMM yyyy', 'id_ID').format(value);
      case DataType.date:
        return DateFormat('dd-MM-yyyy').format(value);
      case DataType.money:
        return 'Rp. ${value.toString().replaceAll('.', ',')}';
    }
  }

  List<DataRow> _buildRows() {
    // Menggunakan List.generate untuk mendapatkan index baris
    return List.generate(widget.data.length, (index) {
      final row = widget.data[index];
      return DataRow2(
        // Menambahkan warna selang-seling untuk kemudahan membaca
        color: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (index.isEven) {
            return Colors.blue.shade50.withValues(alpha: 0.5);
          }
          return null;
        }),
        cells: [
          ..._columnStructure.map((val) {
            return DataCell(
              Center(
                child: Text(
                  _formatDisplayValue(
                    tipe: DataType.values[val.values.first],
                    value: row[val.keys.first],
                  ),
                ),
              ),
            );
          }),
          if (widget.isPreviewMode)
            DataCell(
              Row(
                mainAxisSize:
                    MainAxisSize.min, // Agar row tidak makan banyak tempat
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                    onPressed: () {
                      widget.functionList!['edit']!(idx: index);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Hapus',
                    onPressed: () {
                      widget.functionList!['delete']!(idx: index);
                    },
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  int _isIdRowExist() {
    for (var col in widget.atribute['column']) {
      if (col.keys.first == 'id_row') {
        return 1;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DataTable2(
            fixedLeftColumns: _isIdRowExist(),
            fixedTopRows: 1,
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: widget.isPreviewMode
                ? (90 * _totalColumns) + 140
                : (90 * _totalColumns) + 20,
            headingRowColor: WidgetStateProperty.all(Colors.blue),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _isSortAscending,
            columns: _buildColumns(),
            rows: _buildRows(),
          ),
        ),
      ),
    );
  }
}
