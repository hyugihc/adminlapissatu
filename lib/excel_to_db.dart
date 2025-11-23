import 'dart:typed_data';
import 'package:admin_lapissatu/atoms/const_var.dart';
import 'package:admin_lapissatu/atoms/func_utils.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:admin_lapissatu/atoms/enum_var.dart';
import 'package:admin_lapissatu/input_manual_page.dart';

class ExcelToDB {
  final BuildContext context;
  ExcelToDB({required this.context});

  Uint8List? _pickedFile;
  final Map<String, dynamic> _atribut = {};
  final List<Map<String, dynamic>> _dataRow = [];
  final List<String> _column = ['id_row'];
  final Map<String, Map<DataType, int>> _typeList = {};

  Future<bool?> pickAndProcessFile() async {
    await _pickFile();

    if (_pickedFile != null) {
      final bool? signRead = await _readExcelFile(fileBytes: _pickedFile!);
      return signRead;
    }
    return false;
  }

  bool _isValidYear({required dynamic value}) {
    if (value == null) return false;

    int? year;
    if (value is DateTime) {
      year = value.year;
    } else if (value is num) {
      if (value is double && value % 1 != 0) return false;
      year = value.toInt();
    } else if (value is String) {
      year = int.tryParse(value.trim());
    }
    if (year != null && year >= 1900 && year <= 2100) {
      return true;
    }
    return false;
  }

  bool _isValidMonth({required dynamic value}) {
    if (value == null || value is! String) return false;
    final String input = value.trim().toLowerCase();

    return AppVar.monthMap.keys.contains(input);
  }

  DateTime? parseMonthToDate(String input, {int? year}) {
    final String cleanedInput = input.trim().toLowerCase();
    final int targetYear = year ?? DateTime.now().year;
    final int? monthIndex = AppVar.monthMap[cleanedInput];

    if (monthIndex != null) {
      return DateTime(targetYear, monthIndex, 1);
    } else {
      return null;
    }
  }

  bool _isValidDouble({required String value}) {
    String cleaned = value.trim();
    cleaned = cleaned.replaceFirst(',', '.');
    return double.tryParse(cleaned) != null;
  }

  Future<void> _pickFile() async {
    FilePickerResult? file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (file != null && file.files.single.bytes != null) {
      _pickedFile = file.files.single.bytes;
      return;
    } else {
      if (context.mounted) {
        SnackbarHelper.show(
          context,
          message: 'Tidak ada File yang di Pilih',
          type: SnackbarType.error,
        );
      }
      return;
    }
  }

  void _addListType({required DataType type, required String columnName}) {
    if (_typeList[columnName] == null) {
      _typeList[columnName] = {type: 1};
    } else {
      _typeList[columnName]!.update(
        type,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }

  Future<bool?> _readExcelFile({required Uint8List fileBytes}) async {
    var excel = Excel.decodeBytes(fileBytes);

    String sheetName = excel.tables.keys.first;
    var table = excel.tables[sheetName];

    if (table == null) {
      SnackbarHelper.show(
        context,
        message: 'Sheet Tidak Ditemukan',
        type: SnackbarType.error,
      );
      return null;
    }

    bool isDefineColumn = true;
    for (var row in table.rows) {
      if (isDefineColumn) {
        for (var col in row) {
          if (col != null) {
            if (col.value == null) {
              String colname = 'Unnamed_${col.columnIndex}';
              _column.add(colname);
              _typeList[colname] = {};
            } else {
              String colname = col.value.toString();
              _column.add(colname);
              _typeList[colname] = {};
            }
          }
        }
        isDefineColumn = false;
        continue;
      }

      Map<String, dynamic> tempDataRow = {};

      for (var cell in row) {
        if (cell == null) {
          continue;
        }
        final columnData = _column[cell.columnIndex + 1];
        final value = cell.value;
        final numFormat = cell.cellStyle?.numberFormat ?? NumFormat.standard_0;

        switch (value) {
          case null:
            tempDataRow[columnData] = value;
          case TextCellValue():
            tempDataRow[columnData] = value.toString();
            if (_isValidMonth(value: value.toString())) {
              tempDataRow[columnData] = parseMonthToDate(value.toString());
              _addListType(type: DataType.month, columnName: columnData);
            } else if (_isValidDouble(value: value.toString())) {
              tempDataRow[columnData] = double.tryParse(
                value.toString().trim().replaceFirst(',', '.'),
              );
              _addListType(type: DataType.float, columnName: columnData);
            } else {
              _addListType(type: DataType.string, columnName: columnData);
            }
          case FormulaCellValue():
          case IntCellValue():
            tempDataRow[columnData] = int.tryParse(value.toString());
            if (numFormat is CustomNumericNumFormat &&
                numFormat.toString().contains('Rp-4Z1')) {
              // 421?
              _addListType(type: DataType.money, columnName: columnData);
            } else if (_isValidYear(value: tempDataRow[columnData])) {
              _addListType(type: DataType.year, columnName: columnData);
            } else {
              _addListType(type: DataType.integer, columnName: columnData);
            }
          case BoolCellValue():
            tempDataRow[columnData] = value.value ? 1 : 0;
            _addListType(type: DataType.integer, columnName: columnData);
          case DoubleCellValue():
            tempDataRow[columnData] = double.tryParse(value.toString());
            if (numFormat is CustomNumericNumFormat &&
                numFormat.toString().contains('Rp-421')) {
              _addListType(type: DataType.money, columnName: columnData);
            } else {
              _addListType(type: DataType.float, columnName: columnData);
            }
          case DateCellValue():
            tempDataRow[columnData] = DateTime.tryParse(
              value.toString(),
            ); // Hapus 'as DateTime'
            if (numFormat.toString().contains('"mmm-yy"') ||
                numFormat.toString().contains('"mm-yyyy"')) {
              _addListType(type: DataType.month, columnName: columnData);
            } else if (numFormat.toString().contains('"yyyy"') ||
                numFormat.toString().contains('"yy"')) {
              _addListType(type: DataType.year, columnName: columnData);
              tempDataRow[columnData] =
                  (tempDataRow[columnData] as DateTime?)?.year;
            } else {
              _addListType(type: DataType.date, columnName: columnData);
            }
          case TimeCellValue():
            tempDataRow[columnData] = DateTime.tryParse(value.toString());
            _addListType(type: DataType.datetime, columnName: columnData);
          case DateTimeCellValue():
            tempDataRow[columnData] = DateTime.tryParse(value.toString());
            _addListType(type: DataType.datetime, columnName: columnData);
        }
      }
      _dataRow.add(tempDataRow);
    }

    final List<Map<String, int>> colAtribute = [];
    for (String key in _typeList.keys) {
      String colName = key;
      int maxVote = 0;
      DataType majorType = DataType.string;

      var keys = _typeList[colName]!.keys;
      if (keys.length == 2 &&
          keys.contains(DataType.integer) &&
          keys.contains(DataType.float)) {
        majorType = DataType.float;
      } else {
        for (var ent in _typeList[colName]!.entries) {
          if (ent.value > maxVote) {
            maxVote = ent.value;
            majorType = ent.key;
          }
        }
      }

      colAtribute.add({colName: DataType.values.indexOf(majorType)});
    }

    _atribut['column'] = colAtribute;

    if (context.mounted) {
      final bool? sign = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ManualInputPage(dataIn: {'atribut': _atribut, 'data': _dataRow}),
        ),
      );
      return sign;
    }
    return false;
  }
}
