import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_states.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/view_helpers/search_helper.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import 'cart_screen.dart';

class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key, this.onOpenDetails});
  final void Function(String sku)? onOpenDetails;

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  List<StockModel> _allStock = [];
  List<StockModel> _filteredStock = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<AddStockBloc>().add(GetStockFromDB());
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStock = SearchHelper.filterStock(_allStock, query);
    });
  }

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // compute breakpoint once
    final breakpoint = 700.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final wide = screenWidth >= breakpoint;

    // Search field
    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: CustomStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
      ),
    );

    // Sales list widget (not wrapped in Expanded here)
    final Widget salesListWidget = BlocListener<SalesBloc, SalesStates>(
      listener: (BuildContext context, state) {
        if (state is VariantAddedToCartSuccessState) {
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
            _allStock = state.stockList;
            if (_searchQuery.isNotEmpty) {
              _filteredStock = SearchHelper.filterStock(
                _allStock,
                _searchQuery,
              );
            } else {
              return Center(child: Text("Today Sales 12000"));
            }

            if (_filteredStock.isEmpty) {
              return Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? CustomStrings.noStock
                      : CustomStrings.noStockYet,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.builder(
                key: const PageStorageKey('stock_list'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredStock.length,
                itemBuilder: (context, index) {
                  final p = _filteredStock[index];

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
                        child: Text(p.brand.isNotEmpty ? p.brand[0] : '?'),
                      ),
                      title: Text(
                        '${p.brand} - ${p.articleCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${CustomStrings.qtyTotal} ${p.totalQty}  |  ${CustomStrings.variants} ${p.variantCount}',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                              '${CustomStrings.sku} ${v.sku}\n${CustomStrings.sizeLabel} ${v.size}\n${CustomStrings.colorLabel} ${v.colorName}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${CustomStrings.qty}: ${v.qty}   ${CustomStrings.buy}: ${v.purchasePrice.toStringAsFixed(0)}   ${CustomStrings.sell}: ${v.salePrice.toStringAsFixed(0)}',
                                ),
                                const Divider(thickness: 2),
                              ],
                            ),
                            onTap: () {
                              context.read<SalesBloc>().add(
                                    AddVariantToCart(variant: v),
                                  );
                              setState(() {
                                _searchQuery = "";
                              });
                              _onSearchChanged(_searchQuery);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          return Center(child: Text(CustomStrings.noStock));
        },
      ),
    );

    // Mobile layout
    if (!wide) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(CustomStrings.saleScreenHeading),
          centerTitle: true,
        ),
        body: Column(
          children: [
            searchField,
            Expanded(child: salesListWidget),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'sales',
          onPressed: () {
            searchController.clear();
            PersistentNavBarNavigator.pushNewScreen(
              context,
              screen: CartScreen(),
              withNavBar: false,
              pageTransitionAnimation: PageTransitionAnimation.cupertino,
            ).then((_) => _load());
          },
          label: Row(
            children: [
              const Icon(Icons.shopping_cart),
              const SizedBox(width: 8),
              Text(CustomStrings.viewCartButton),
            ],
          ),
        ),
      );
    }

    // Wide layout - show cart side-by-side
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(CustomStrings.saleScreenHeading),
        centerTitle: true,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                searchField,
                Expanded(child: salesListWidget),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Column(
              children: const [
                SizedBox(height: 8),
                Expanded(child: CartBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
