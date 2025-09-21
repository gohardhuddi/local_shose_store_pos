import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/sales/payment_sheet.dart';

import '../../controller/add_stock_bloc/add_stock_states.dart';
import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';
import '../../helper/constants.dart';
import '../view_helpers/resueables/custom_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(CustomStrings.cartScreenHeading),
        centerTitle: true,
      ),
      body: Padding(
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
                                          Text(
                                            item.sku ?? "",
                                            style: headingStyle(),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          // TODO: dispatch bloc event to remove item
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
                                      Text(
                                        "${item.qty ?? 0}",
                                        style: bodyStyle(),
                                      ),
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
                                            if ((item.qtyCart ?? 0) <
                                                (item.qty ?? 0)) {
                                              item.qtyCart =
                                                  (item.qtyCart ?? 0) + 1;
                                            } else {
                                              // Optional: show a warning (e.g. snackbar)
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
                                        "${item.qtyCart ?? 1}",
                                        style: bodyStyle(),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            if ((item.qtyCart ?? 1) > 1) {
                                              item.qtyCart = item.qtyCart! - 1;
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
                                          controller: TextEditingController(
                                            text:
                                                item.salePrice?.toString() ??
                                                "0",
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              item.salePrice =
                                                  double.tryParse(val) ?? 0.0;
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
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => PaymentSheet(
                                          billTotal: double.parse(
                                            _calculateTotalPrice(cartItems),
                                          ),
                                        ),
                                      );
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
      final qty = item.qtyCart ?? 1;
      final price = item.salePrice ?? 0.0;
      total += qty * price;
    }
    return total.toStringAsFixed(2);
  }
}
