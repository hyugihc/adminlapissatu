import 'dart:io';

import 'package:admin_lapissatu/atoms/enum_var.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void sortListMaps({
  required List<Map<String, dynamic>> data,
  required String colName,
  required bool ascending,
}) {
  data.sort((a, b) {
    final valA = a[colName];
    final valB = b[colName];

    final int comparison = _compareDynamic(valA, valB);
    return ascending ? comparison : -comparison;
  });
}

int _compareDynamic(dynamic valA, dynamic valB) {
  if (valA == null && valB == null) return 0;
  if (valA == null) return 1;
  if (valB == null) return -1;

  if (valA is Comparable) {
    try {
      return valA.compareTo(valB);
    } catch (e) {
      print(e);
    }
  }
  return valA.toString().compareTo(valB.toString());
}

Map<String, List> findColumnFitName({required List<Map> columnMaster}) {
  List<String> xLabel = [];
  List<String> yCol = [];

  for (var col in (columnMaster)) {
    var tempvar = DataType.values[col.values.first as int];
    if (col.keys.first == 'id_row') {
      continue;
    }
    if ([
      DataType.string,
      DataType.year,
      DataType.month,
      DataType.date,
      DataType.datetime,
    ].contains(tempvar)) {
      xLabel.add(col.keys.first);
    } else if ([
      DataType.integer,
      DataType.float,
      DataType.money,
    ].contains(tempvar)) {
      yCol.add(col.keys.first);
    }
  }
  Map<String, List> xyLabel = {'xlabel': xLabel, 'ylabel': yCol};
  return xyLabel;
}

void showErrorDialog({required BuildContext context, required String message}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error Login'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('Oke'),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
      ],
    ),
  );
}

class LoadingHelper {
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      // Mencegah dialog ditutup saat user mengetuk area di luar dialog
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Menyimpan data..."),
              ],
            ),
          ),
        );
      },
    );
  }

  static void closeLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class SnackbarHelper {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    final Color backgroundColor;
    final IconData iconData;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = Colors.green[600]!;
        iconData = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red[600]!;
        iconData = Icons.error_outline;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blue[600]!;
        iconData = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(
        children: [
          Icon(iconData, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class FireBaseDB {
  static Future<String?> uploadImage({
    required File file,
    required String cloudPath,
    String? fileName,
  }) async {
    try {
      fileName = fileName ?? file.path.split('/').last;
      String newfileName =
          'img_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference storageRef = FirebaseStorage.instance.ref().child(
        '$cloudPath/$newfileName',
      );
      UploadTask uploadTask = storageRef.putFile(file);
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          double progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('Upload is $progress% done');
        },
        onError: (e) {
          print('Error pada stream: $e');
        },
      );
      TaskSnapshot snapshot = await uploadTask;
      String publicURL = await snapshot.ref.getDownloadURL();
      print('[UPLOAD IMAGE SUCCESSFULLY]');
      return publicURL;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> deleteImageByUrl(String publicUrl) async {
    try {
      Reference ref = FirebaseStorage.instance.refFromURL(publicUrl);

      // 2. Lakukan penghapusan
      await ref.delete();
      print('File berhasil dihapus!');
    } catch (e) {
      print('Gagal menghapus file: $e');
    }
  }

  static Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> newData,
  }) async {
    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(docId)
        .set(newData);
  }

  static Future<Map<String, dynamic>> loadDocument({
    required String collectionPath,
    required String docId,
  }) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(docId)
        .get();
    Map<String, dynamic> dataDoc = Map.from(
      snapshot.data() as Map<String, dynamic>,
    );
    dataDoc['id'] = docId;
    return dataDoc;
  }
}

Future<File?> copyPickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );
  if (result != null) {
    PlatformFile pickedFile = result.files.first;
    File sourceFile = File(pickedFile.path!);
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = '${appDir.path}/${pickedFile.name}';
    try {
      final File newFile = await sourceFile.copy(newPath);
      return newFile;
    } catch (e) {
      print(e);
      return null;
    }
  }
  return null;
}
