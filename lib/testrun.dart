void main() {
  var raw = "StockMovementType.purchaseIn";
  raw = raw.trim();

  // Handle enum-style values: "stockmovementtype.purchasein"
  if (raw.startsWith('StockMovementType.')) {
    raw = raw.replaceFirst('StockMovementType.', '');
  }

  var test = raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]}_${m[2]}'.toLowerCase(),
  );
  print(test);
}
