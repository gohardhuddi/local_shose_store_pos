import 'package:flutter/material.dart';

class PaymentSheet extends StatefulWidget {
  final double billTotal;
  const PaymentSheet({super.key, required this.billTotal});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String entered = "";
  double? _change;

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        entered = "";
      } else if (value == '⌫') {
        if (entered.isNotEmpty) {
          entered = entered.substring(0, entered.length - 1);
        }
      } else {
        entered += value;
      }

      final amount = double.tryParse(entered) ?? 0;
      _change = amount - widget.billTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Bill Total: RS ${widget.billTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entered.isEmpty ? "0" : entered,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_change != null)
              Text(
                _change! < 0
                    ? "Insufficient Cash"
                    : "Change: RS ${_change!.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _change! < 0 ? Colors.red : Colors.green,
                ),
              ),

            const Spacer(),

            // Keypad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              mainAxisSpacing: 1,
              crossAxisSpacing: 3,
              children: [
                for (var btn in [
                  "1",
                  "2",
                  "3",
                  "4",
                  "5",
                  "6",
                  "7",
                  "8",
                  "9",
                  "C",
                  "0",
                  "⌫",
                ])
                  ElevatedButton(
                    onPressed: () => _tap(btn),
                    child: Text(btn, style: const TextStyle(fontSize: 20)),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Done", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
