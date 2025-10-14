import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_events.dart';

import '../../controller/sales_bloc/sales_bloc.dart';
import '../../models/cart_model.dart';

class PaymentSheet extends StatefulWidget {
  final double billTotal;
  final List<CartItemModel> cartItems;

  const PaymentSheet({
    super.key,
    required this.billTotal,
    required this.cartItems,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final TextEditingController _controller = TextEditingController();
  String entered = "";
  double? _change;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {
      entered = value.replaceAll(',', '');
      final amount = double.tryParse(entered) ?? 0;
      _change = amount - widget.billTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final theme = Theme.of(context);
    final changeColor = _change == null
        ? Colors.grey
        : _change! < 0
        ? Colors.red
        : Colors.green;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.56,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- Header ----------
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              "Total Bill",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            Text(
              "Rs ${widget.billTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ---------- Cash Input ----------
            Text(
              "Cash Received",
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_exchange_rounded,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                      ],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter amount",
                        hintStyle: TextStyle(fontSize: 20),
                      ),
                      onChanged: _onInputChanged,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      _onInputChanged('');
                    },
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------- Change Display ----------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _change == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_change),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: changeColor, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _change! < 0 ? "Insufficient Cash" : "Change",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: changeColor,
                            ),
                          ),
                          Text(
                            "Rs ${_change!.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: changeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const Spacer(),

            // ---------- Action Buttons ----------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.outlineVariant
                            : Theme.of(context).colorScheme.outline,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),

                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: const Text("Done", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                      Navigator.pop(context); // close sheet
                      if (isMobile) Navigator.pop(context); // close cart
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
