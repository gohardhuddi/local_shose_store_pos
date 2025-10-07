import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/add_stock_screen.dart';
import 'package:local_shoes_store_pos/views/edit_stock_screen.dart';
import 'package:local_shoes_store_pos/views/view_helpers/search_helper.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class ViewStockScreen extends StatefulWidget {
  const ViewStockScreen({super.key, this.onOpenDetails});
  final void Function(String sku)? onOpenDetails;

  @override
  State<ViewStockScreen> createState() => _ViewStockScreenState();
}

class _ViewStockScreenState extends State<ViewStockScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('${CustomStrings.shopName} ${CustomStrings.stockTitle}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: CustomStrings.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _onSearchChanged(''),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // 📊 Total Quantity and Value
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: BlocBuilder<AddStockBloc, AddStockStates>(
                builder: (context, state) {
                  if (state is GetStockFromDBSuccessState) {
                    final totalQuantity = state.stockList.fold<int>(
                      0,
                      (sum, product) =>
                          sum +
                          product.variants.fold<int>(
                            0,
                            (vSum, variant) => vSum + variant.qty,
                          ),
                    );

                    final totalValue = state.stockList.fold<double>(
                      0.0,
                      (sum, product) =>
                          sum +
                          product.variants.fold<double>(
                            0.0,
                            (vSum, variant) =>
                                vSum + (variant.salePrice * variant.qty),
                          ),
                    );

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${CustomStrings.totalQuantity}: $totalQuantity',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${CustomStrings.totalPrice}: \$${totalValue.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 🧱 Stock list
            Expanded(
              child: BlocListener<AddStockBloc, AddStockStates>(
                listener: (context, state) {
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
                      _allStock = state.stockList;
                      _filteredStock = _searchQuery.isNotEmpty
                          ? SearchHelper.filterStock(_allStock, _searchQuery)
                          : _allStock;
                      if (_filteredStock.isEmpty) {
                        return _buildEmptyState();
                      }
                      return Expanded(
                        child: isWide
                            ? _buildGridView(context, _filteredStock)
                            : _buildListView(context, _filteredStock),
                      );
                    }
                    return _buildEmptyState();
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "view_stock",
        onPressed: () {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: AddStockScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          ).then((_) => _load());
        },
        icon: const Icon(Icons.add),
        label: const Text(CustomStrings.addStockButton),
        // tooltip: 'Add new stock',
      ),
    );
  }

  // 🧱 List View for mobile
  Widget _buildListView(BuildContext context, List<StockModel> items) {
    return ListView.builder(
      key: const PageStorageKey('stock_list'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            key: PageStorageKey('expansion_${p.productId}_${p.articleCode}'),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (p.brand.isNotEmpty) ? p.brand[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(
              '${p.brand} - ${p.articleCode}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${CustomStrings.qtyTotal} ${p.totalQty}  |  ${CustomStrings.variants} ${p.variantCount}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ...p.variants.map((v) => _buildVariantTile(context, p, v)),
            ],
          ),
        );
      },
    );
  }

  // 🖥 Grid View for wide/desktop layout
  Widget _buildGridView(BuildContext context, List<StockModel> items) {
    final crossAxisCount = (MediaQuery.of(context).size.width / 350).floor();
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount.clamp(2, 4),
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.brand} - ${p.articleCode}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CustomStrings.qtyTotal}: ${p.totalQty}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${CustomStrings.variants}: ${p.variantCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: p.variants.length,
                    itemBuilder: (context, i) =>
                        _buildVariantTile(context, p, p.variants[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 👟 Variant item UI
  Widget _buildVariantTile(BuildContext context, StockModel p, dynamic v) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Icon(Icons.shopping_bag, color: Colors.grey.shade700),
      ),
      title: Text(
        '${CustomStrings.sku}: ${v.sku}',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${CustomStrings.sizeLabel}: ${v.size}   |   ${CustomStrings.colorLabel}: ${v.colorName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${CustomStrings.qty}: ${v.qty}   ${CustomStrings.buy}: ${v.purchasePrice.toStringAsFixed(0)}   ${CustomStrings.sell}: ${v.salePrice.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            // tooltip: CustomStrings.edit,
            onPressed: () {
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: EditStockScreen(stock: p, varient: v),
                withNavBar: true,
                pageTransitionAnimation: PageTransitionAnimation.cupertino,
              ).then((_) => _load());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: CustomStrings.delete,
            onPressed: () => _confirmDelete(context, v.variantId),
          ),
        ],
      ),
      onTap: () => widget.onOpenDetails?.call(v.sku ?? ''),
    );
  }

  // 🗑 Delete Confirmation Dialog
  void _confirmDelete(BuildContext context, String variantId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(CustomStrings.confirmDelete),
        content: Text(CustomStrings.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(CustomStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<AddStockBloc>().add(
                DeleteVariantByIdEvent(variantID: variantId),
              );
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(CustomStrings.delete),
          ),
        ],
      ),
    );
  }

  // 😴 Empty / Onboarding State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? CustomStrings.noStock
                : 'No stock added yet.\nTap the + button to add your first item!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
