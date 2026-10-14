String formatVnd(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buffer VNĐ';
}

const double vndPerUsd = 25000;

String formatUsd(num vnd) {
  final usd = vnd / vndPerUsd;
  return '\$${usd.toStringAsFixed(2)}';
}

String formatPrice(num vnd, {required bool international}) {
  return international ? formatUsd(vnd) : formatVnd(vnd);
}