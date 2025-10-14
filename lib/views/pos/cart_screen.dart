import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/pos/payment_sheet.dart';

import '../../controller/add_stock_bloc/add_stock_states.dart';
import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';
import '../../helper/constants.dart';
import '../../models/cart_model.dart';
import '../view_helpers/resueables/custom_button.dart';

class CartBody extends StatefulWidget {
  const CartBody({super.key});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _priceControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: BlocBuilder<SalesBloc, SalesStates>(
        builder: (context, state) {
          if (state is AddStockLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! VariantAddedToCartSuccessState ||
              state.cartItems.isEmpty) {
            return const Center(
              child: Text(
                "🛒 Your cart is empty",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final cartItems = state.cartItems;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final item = cartItems[index];

                    final controller = _priceControllers.putIfAbsent(
                      item.variant.variantId,
                      () => TextEditingController(
                        text: item.variant.salePrice.toInt().toString(),
                      ),
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (Theme.of(context).brightness == Brightness.light)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "SKU: ${item.variant.sku}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    _priceControllers[item.variant.variantId]
                                        ?.dispose();
                                    _priceControllers.remove(
                                      item.variant.variantId,
                                    );
                                    context.read<SalesBloc>().add(
                                      RemoveVariantFromCart(variant: item),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Text(
                              "${item.variant.colorName} • Size ${item.variant.size}",
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Stock Info
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "In Stock: ${item.variant.qty}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),

                                // Editable Price
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            item.variant.salePrice =
                                                double.tryParse(val) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Quantity Selector
                            Row(
                              children: [
                                const Text(
                                  "Qty:",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                _qtyButton(
                                  icon: Icons.remove,
                                  color: Colors.redAccent,
                                  onPressed: () {
                                    setState(() {
                                      if (item.cartQty > 1) {
                                        item.cartQty--;
                                      }
                                    });
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    "${item.cartQty}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                _qtyButton(
                                  icon: Icons.add,
                                  color: Colors.green,
                                  onPressed: () {
                                    setState(() {
                                      if (item.cartQty < item.variant.qty) {
                                        item.cartQty++;
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Not enough stock"),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total and Buttons
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "PKR ${_calculateTotalPrice(cartItems)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonTitle: "💵 Cash",
                            onPressed: () => _showPayment(context, cartItems),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant
                                    : Theme.of(context).colorScheme.outline,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                            child: const Text(
                              "🕒 Pay Later",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _showPayment(BuildContext context, List<CartItemModel> cartItems) {
    final total = double.parse(_calculateTotalPrice(cartItems));

    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => PaymentSheet(billTotal: total, cartItems: cartItems),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) {
          return Align(
            alignment: Alignment.bottomRight,
            child: FractionallySizedBox(
              widthFactor: 0.4,
              heightFactor: 0.6,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: PaymentSheet(billTotal: total, cartItems: cartItems),
              ),
            ),
          );
        },
      );
    }
  }

  String _calculateTotalPrice(List<CartItemModel> items) {
    double total = 0;
    for (var item in items) {
      total += item.cartQty * item.variant.salePrice;
    }
    return total.toStringAsFixed(0);
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CustomStrings.cartScreenHeading),
        centerTitle: true,
      ),
      body: const CartBody(),
    );
  }
}
