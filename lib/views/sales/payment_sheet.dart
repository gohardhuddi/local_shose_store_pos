import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_events.dart';

import '../../controller/sales_bloc/sales_bloc.dart';
import '../../models/stock_model.dart';

class PaymentSheet extends StatefulWidget {
  final double billTotal;
  final List<VariantModel> cartItems;
  const PaymentSheet({
    super.key,
    required this.billTotal,
    required this.cartItems,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String entered = "";
  double? _change;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = entered;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {
      entered = value;
      // normalize commas or stray chars
      final sanitized = entered.replaceAll(',', '');
      final amount = double.tryParse(sanitized) ?? 0;
      _change = amount - widget.billTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
  padding: const EdgeInsets.all(16),
  // 30% smaller than previous 0.8 -> 0.8 * 0.7 = 0.56
  height: MediaQuery.of(context).size.height * 0.56,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Bill Total: RS ${widget.billTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Replace display & keypad with an editable TextField for keyboard input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // allow digits and dot
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                      ],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onInputChanged,
                    ),
                  ),

                  // Clear button
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _controller.clear();
                      _onInputChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  ),

                  // Backspace
                  IconButton(
                    tooltip: 'Backspace',
                    onPressed: () {
                      final text = _controller.text;
                      if (text.isNotEmpty) {
                        final newText = text.substring(0, text.length - 1);
                        _controller.text = newText;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: newText.length),
                        );
                        _onInputChanged(newText);
                      }
                    },
                    icon: const Icon(Icons.backspace),
                  ),
                ],
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

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                  context.read<SalesBloc>().add(
                        SoldEvent(
                          cartItems: widget.cartItems,
                          totalAmount: widget.billTotal.toString(),
                          amountPaid: entered,
                          changeReturned: _change.toString(),
                          paymentType: "Cash",
                          createdBy: "manager",
                          isSynced: false,
                        ),
                      );

                  // On mobile devices (Android/iOS) we want to close both
                  // the payment sheet and the cart screen (two pops).
                  // On web/desktop only close the payment sheet (one pop)
                  final isMobile = !kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.android ||
                          defaultTargetPlatform == TargetPlatform.iOS);

                  Navigator.pop(context); // close payment sheet
                  if (isMobile) Navigator.pop(context); // close cart on mobile
                },
              child: const Text("Done", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
