import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_bloc.dart';
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_events.dart';
import 'package:local_shoes_store_pos/controller/sales_bloc/sales_states.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/view_helpers/search_helper.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'cart_screen.dart';

class POSHomeScreen extends StatefulWidget {
  const POSHomeScreen({super.key, this.onOpenDetails});
  final void Function(String sku)? onOpenDetails;

  @override
  State<POSHomeScreen> createState() => _POSHomeScreenState();
}

class _POSHomeScreenState extends State<POSHomeScreen> {
  List<StockModel> _allStock = [];
  List<StockModel> _filteredStock = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
      _searchQuery = query.trim();
      _filteredStock = SearchHelper.filterStock(_allStock, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double breakpoint = 800;
    final bool isWide = MediaQuery.of(context).size.width >= breakpoint;

    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: CustomStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );

    final stockList = BlocListener<SalesBloc, SalesStates>(
      listener: (context, state) {
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
            _filteredStock = _searchQuery.isEmpty
                ? _allStock
                : SearchHelper.filterStock(_allStock, _searchQuery);

            if (_filteredStock.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredStock.length,
                itemBuilder: (context, index) {
                  final stock = _filteredStock[index];
                  return _buildStockCard(context, stock);
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );

    // ✅ Mobile layout (FAB visible)
    if (!isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(CustomStrings.saleScreenHeading),
          centerTitle: true,
          elevation: 2,
        ),
        body: Column(
          children: [
            searchField,
            Expanded(child: stockList),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'pos-fab',
          onPressed: () {
            _searchController.clear();
            PersistentNavBarNavigator.pushNewScreen(
              context,
              screen: const CartScreen(),
              withNavBar: false,
              pageTransitionAnimation: PageTransitionAnimation.cupertino,
            ).then((_) => _load());
          },
          icon: const Icon(Icons.shopping_cart),
          label: Text(CustomStrings.viewCartButton),
        ),
      );
    }

    // ✅ Desktop / tablet layout (side-by-side)
    return Scaffold(
      appBar: AppBar(
        title: Text(CustomStrings.saleScreenHeading),
        centerTitle: true,
        elevation: 2,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                searchField,
                Expanded(child: stockList),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey.shade300),
          Expanded(
            flex: 1,
            child: Column(
              children: const [
                SizedBox(height: 12),
                Expanded(child: CartBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, StockModel stock) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            stock.brand.isNotEmpty ? stock.brand[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${stock.brand} - ${stock.articleCode}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${CustomStrings.qtyTotal} ${stock.totalQty} | ${CustomStrings.variants} ${stock.variantCount}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
        children: stock.variants.map((variant) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Image.asset(CustomImagesPaths.shoeBlackIcon),
              ),
              title: Text(
                '${CustomStrings.sku}: ${variant.sku}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${CustomStrings.sizeLabel}: ${variant.size} | ${CustomStrings.colorLabel}: ${variant.colorName}\n'
                  '${CustomStrings.qty}: ${variant.qty}  •  '
                  '${CustomStrings.buy}: ${variant.purchasePrice.toStringAsFixed(0)}  •  '
                  '${CustomStrings.sell}: ${variant.salePrice.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
              onTap: () {
                context.read<SalesBloc>().add(
                  AddVariantToCart(variant: variant),
                );
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? CustomStrings.noStock
                : 'No stock found.\nTap the + button to add your first item.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
