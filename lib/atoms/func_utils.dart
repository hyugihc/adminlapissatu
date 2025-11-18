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
