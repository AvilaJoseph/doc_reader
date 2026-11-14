/// Tamaño legible: 532 B, 12 KB, 2,4 MB.
String formatFileSize(int bytes, {String decimalSeparator = ','}) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 || value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', decimalSeparator);
  return '$text ${units[unit]}';
}
