import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/sales/payment_sheet.dart';

import '../../controller/add_stock_bloc/add_stock_states.dart';
import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';
import '../../helper/constants.dart';
import '../view_helpers/resueables/custom_button.dart';

class CartBody extends StatefulWidget {
  const CartBody({super.key});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  // Keep controllers per variantId
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
    double width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocListener<SalesBloc, SalesStates>(
        listener: (BuildContext context, state) {},
        child: BlocBuilder<SalesBloc, SalesStates>(
          builder: (context, state) {
            if (state is AddStockLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is VariantAddedToCartSuccessState) {
              final cartItems = state.cartItems;

              return Column(
                children: [
                  // ---------------- Items List ----------------
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = cartItems[index];

                        // Get or create persistent controller for this item
                        final controller = _priceControllers.putIfAbsent(
                          item.variantId, // Use variantId as unique key
                          () => TextEditingController(
                            text: item.salePrice.toInt().toString(),
                          ),
                        );

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SKU + Delete button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text("SKU : ", style: headingStyle()),
                                        Text(item.sku, style: headingStyle()),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        // Dispose controller when removing item
                                        _priceControllers[item.variantId]
                                            ?.dispose();
                                        _priceControllers.remove(
                                          item.variantId,
                                        );

                                        context.read<SalesBloc>().add(
                                              RemoveVariantFromCart(
                                                variant: state.cartItems[index],
                                              ),
                                            );
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),

                                // Stock
                                Row(
                                  children: [
                                    Text(
                                      "In Stock : ",
                                      style: headingStyle(),
                                    ),
                                    Text("${item.qty}", style: bodyStyle()),
                                  ],
                                ),

                                // Quantity selector
                                Row(
                                  children: [
                                    Text(
                                      "Quantity : ",
                                      style: headingStyle(),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (item.qtyCart < item.qty) {
                                            item.qtyCart += 1;
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Not enough stock available",
                                                ),
                                              ),
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                    Text(
                                      "${item.qtyCart}",
                                      style: bodyStyle(),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (item.qtyCart > 1) {
                                            item.qtyCart -= 1;
                                          }
                                        });
                                      },
                                      icon: Transform.translate(
                                        offset: const Offset(0, -8),
                                        child: const Icon(
                                          Icons.minimize_sharp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Price editable
                                Row(
                                  children: [
                                    Text("Price", style: headingStyle()),
                                    SizedBox(width: width * 0.02),
                                    SizedBox(
                                      width: 130,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        controller: controller,
                                        onChanged: (val) {
                                          setState(() {
                                            item.salePrice = double.parse(
                                              val.isEmpty ? "0" : val,
                                            );
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
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

                  // ---------------- Summary & Buttons ----------------
                  Card(
                    color: Theme.of(context).splashColor,
                    elevation: 5,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        spacing: 5,
                        children: [
                          // Total price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Price", style: totalPriceFont()),
                              Text(
                                _calculateTotalPrice(cartItems),
                                style: totalPriceFont(),
                              ),
                            ],
                          ),

                          // Number of items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total No. of Items",
                                style: totalPriceFont(),
                              ),
                              Text(
                                cartItems.length.toString(),
                                style: totalPriceFont(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Cash button
                          CustomButton(
                            minSize: const Size(40, 40),
                            maxSize: const Size(190, 90),
                            onPressed: state.cartItems.isNotEmpty
                                ? () {
                                    // Use different presentation on web/desktop
                                    final isMobile = !kIsWeb &&
                                        (defaultTargetPlatform ==
                                            TargetPlatform.android ||
                                            defaultTargetPlatform ==
                                                TargetPlatform.iOS);

                                    if (isMobile) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => PaymentSheet(
                                          billTotal: double.parse(
                                            _calculateTotalPrice(cartItems),
                                          ),
                                          cartItems: state.cartItems,
                                        ),
                                      );
                                    } else {
                                      // Desktop/Web: show a bottom-right aligned dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (ctx) {
                                          return Align(
                                            alignment: Alignment.bottomRight,
                                            child: FractionallySizedBox(
                                              widthFactor: 0.35,
                                              heightFactor: 0.5,
                                              child: Material(
                                                elevation: 8,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: PaymentSheet(
                                                  billTotal: double.parse(
                                                    _calculateTotalPrice(cartItems),
                                                  ),
                                                  cartItems: state.cartItems,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }
                                : null,
                            buttonTitle: "Cash",
                          ),

                          // Pay later button
                          CustomButton(
                            minSize: const Size(40, 40),
                            maxSize: const Size(190, 90),
                            onPressed: () {
                              // TODO: implement pay later flow
                            },
                            buttonTitle: "Pay Later",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text("No Items in Cart"));
          },
        ),
      ),
    );
  }

  TextStyle headingStyle() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  TextStyle bodyStyle() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.normal);

  TextStyle totalPriceFont() =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  /// Sum of qty * salePrice
  String _calculateTotalPrice(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      final qty = item.qtyCart;
      final price = item.salePrice;
      total += qty * price;
    }
    return total.toStringAsFixed(0);
  }
}

// Keep a thin Scaffold wrapper for full-screen cart route
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