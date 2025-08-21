import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/add_stock_screen.dart';
import 'package:local_shoes_store_pos/views/edit_stock_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class ViewStockScreen extends StatefulWidget {
  const ViewStockScreen({super.key, this.onOpenDetails});
  final void Function(String sku)? onOpenDetails;

  @override
  State<ViewStockScreen> createState() => _ViewStockScreenState();
}

class _ViewStockScreenState extends State<ViewStockScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<AddStockBloc>().add(GetStockFromDB());
    context.read<AddStockBloc>().add(GetUnSyncedStockFromDB());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('${CustomStrings.shopName} Stock'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (q) =>
                  context.read<AddStockBloc>().add(SearchQueryChanged(q)),
              decoration: InputDecoration(
                hintText: 'Search brand, article, SKU, color, size…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: BlocListener<AddStockBloc, AddStockStates>(
              listener: (BuildContext context, state) {
                if (state is DeleteVariantByIdSuccessState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.success),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _load();
                }
              },
              child: BlocBuilder<AddStockBloc, AddStockStates>(
                builder: (context, state) {
                  if (state is AddStockLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is GetStockFromDBSuccessState) {
                    final List<StockModel> items = state.stockList;
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No stock yet. Add some!'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              key: const PageStorageKey('stock_list'),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final p = items[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ExpansionTile(
                                    key: PageStorageKey(
                                      'expansion_${p.productId}_${p.articleCode}',
                                    ),
                                    leading: CircleAvatar(
                                      child: Text(
                                        (p.brand.isNotEmpty ?? false)
                                            ? p.brand[0]
                                            : '?',
                                      ),
                                    ),
                                    title: Text(
                                      '${p.brand ?? ''} - ${p.articleCode ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Qty ${p.totalQty ?? 0}  |  Variants ${p.variantCount ?? 0}',
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    children: [
                                      ...p.variants.map(
                                        (v) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Image.asset(
                                              CustomImagesPaths.shoeBlackIcon,
                                            ),
                                          ),
                                          title: Text(
                                            'SKU: ${v.sku}\nSize: ${v.size}\nColor: ${v.colorName}',
                                          ),
                                          subtitle: Text(
                                            'Qty: ${v.qty}   Buy: ${v.purchasePrice?.toStringAsFixed(0)}   Sell: ${v.salePrice?.toStringAsFixed(0)}',
                                          ),
                                          trailing: SizedBox(
                                            width: 100,
                                            child: Row(
                                              spacing: 3,
                                              children: [
                                                IconButton(
                                                  tooltip: "Edit",
                                                  onPressed: () {
                                                    PersistentNavBarNavigator.pushNewScreen(
                                                      context,
                                                      screen: EditStockScreen(
                                                        stock: p,
                                                        varient: v,
                                                      ),
                                                      withNavBar: true,
                                                      pageTransitionAnimation:
                                                          PageTransitionAnimation
                                                              .cupertino,
                                                    ).then((_) => _load());
                                                  },
                                                  icon: Icon(Icons.edit),
                                                ),
                                                IconButton(
                                                  tooltip: "Delete",
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text(
                                                            "Confirm Delete",
                                                          ),
                                                          content: Text(
                                                            "Are you sure you want to delete this?",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(); // Close the dialog
                                                              },
                                                              child: Text(
                                                                "Cancel",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                context
                                                                    .read<
                                                                      AddStockBloc
                                                                    >()
                                                                    .add(
                                                                      DeleteVariantByIdEvent(
                                                                        variantID:
                                                                            v.variantId,
                                                                      ),
                                                                    );
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              },
                                                              style: TextButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors.red,
                                                              ),
                                                              child: Text(
                                                                "Delete",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  icon: Icon(Icons.delete),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            // callback for details if you want
                                            widget.onOpenDetails?.call(
                                              v.sku ?? '',
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Tapped ${v.sku}',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Fallback for any other state (e.g., initial)
                  return const Center(child: Text("No stock"));
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: AddStockScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          ).then((_) => _load()); // refresh after returning
        },
        label: const Row(
          children: [Icon(Icons.add), SizedBox(width: 8), Text('Add Stock')],
        ),
      ),
    );
  }
}
