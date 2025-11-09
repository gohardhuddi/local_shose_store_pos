import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

import '../../controller/return_bloc/return_bloc.dart';
import '../../controller/return_bloc/return_events.dart';
import '../../controller/return_bloc/return_state.dart';
import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';
import '../../models/cart_model.dart';
import '../../models/stock_model.dart';

class ReturnHomeScreen extends StatefulWidget {
  const ReturnHomeScreen({super.key});

  @override
  State<ReturnHomeScreen> createState() => _ReturnHomeScreenState();
}

class _ReturnHomeScreenState extends State<ReturnHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _returnIdController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();

  String _searchQuery = '';
  dynamic _selectedSale;
  List<dynamic> _selectedItems = [];

  PersistentBottomSheetController? _sheetController;

  @override
  void dispose() {
    _searchController.dispose();
    _returnIdController.dispose();
    _customerNameController.dispose();
    _returnReasonController.dispose();
    super.dispose();
  }

  // 🔍 Automatically opens search results
  void _ensureSheetVisible(BuildContext context) {
    if (_sheetController != null) return;

    _sheetController = showBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: BlocBuilder<SalesBloc, SalesStates>(
            builder: (context, state) {
              if (state is SalesLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is GetAllSalesSuccessState ||
                  state is SearchSalesSuccessState) {
                final sales = (state as dynamic).sales;
                if (sales.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                }

                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final s = sales[index];
                    final sale = s.sale;

                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text('Sale ID: ${sale.saleId}'),
                      subtitle: Text(
                        '${CustomStrings.currency}${sale.totalAmount} | '
                        '${DateFormat('dd MMM yyyy').format(DateTime.parse(sale.dateTime))}',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _sheetController = null;
                        _selectSale(s);
                      },
                    );
                  },
                );
              }

              if (state is SalesErrorState) {
                return Center(child: Text('Error: ${state.error}'));
              }

              return const Center(
                child: Text('Start typing to search sales...'),
              );
            },
          ),
        );
      },
    );

    _sheetController!.closed.then((_) {
      _sheetController = null;
    });
  }

  void _selectSale(dynamic s) {
    final sale = s.sale;

    setState(() {
      _selectedSale = s;
      _selectedItems = List.from(s.lines);
      _customerNameController.text = 'Walk-in Customer';
      _returnIdController.text =
          'RET-${sale.saleId}-${DateFormat('HHmmss').format(DateTime.now())}';
    });
  }

  void _removeItem(dynamic line) {
    setState(() => _selectedItems.remove(line));
  }

  void _submitReturn() {
    if (_selectedSale == null || _selectedItems.isEmpty) return;

    final totalRefund = _selectedItems.fold<double>(
      0,
      (sum, item) => sum + (item.line.unitPrice * item.line.qty),
    );

    final items = _selectedItems.map<CartItemModel>((item) {
      final line = item.line;

      // Build a VariantModel from the sale line info
      final variant = VariantModel(
        variantId: line.variantId,
        sku: item.sku ?? '',
        size: 0, // or actual size if available
        colorName: '', // optional
        colorHex: '', // optional
        qty: line.qty,
        purchasePrice: 0.0, // not needed for return
        salePrice: line.unitPrice,
        createdAt: '',
        updatedAt: '',
        isSynced: false,
        isActive: true,
      );

      return CartItemModel(variant: variant, cartQty: line.qty);
    }).toList();

    context.read<ReturnBloc>().add(
      ProcessReturnEvent(
        saleId: _selectedSale.sale.saleId,
        items: items,
        totalRefund: totalRefund,
        reason: _returnReasonController.text,
        createdBy: _customerNameController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ReturnBloc, ReturnState>(
      listener: (context, state) {
        if (state is ReturnLoading) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Processing return...')));
        } else if (state is ReturnSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Return processed successfully (${state.returnId})',
              ),
            ),
          );
          setState(() {
            _selectedSale = null;
            _selectedItems.clear();
            _searchController.clear();
            _searchQuery = '';
          });
        } else if (state is ReturnError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ Error: ${state.message}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${CustomStrings.shopName} ${CustomStrings.returnSale}'),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔍 Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                    if (value.trim().isNotEmpty) {
                      context.read<SalesBloc>().add(SearchSalesEvent(value));
                      _ensureSheetVisible(context);
                    } else {
                      context.read<SalesBloc>().add(ClearSalesSearchEvent());
                      _sheetController?.close();
                      _sheetController = null;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search sale by ID, date, or amount',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              context.read<SalesBloc>().add(
                                ClearSalesSearchEvent(),
                              );
                              _sheetController?.close();
                              _sheetController = null;
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🧾 Return Info
                Text(
                  'Return Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _returnIdController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Return ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _returnReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Return Reason',
                    hintText: 'Damaged, wrong size, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                if (_selectedSale != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items to Return',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedItems.length,
                        itemBuilder: (context, index) {
                          final line = _selectedItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(line.line.variantId ?? 'Product'),
                              subtitle: Text(
                                'SKU: ${line.sku} | Qty: ${line.line.qty} | '
                                'Price: ${CustomStrings.currency}${line.line.unitPrice}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItem(line),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      Divider(),

                      Text(
                        'Total Refund: ${CustomStrings.currency}${_selectedItems.fold<double>(0, (sum, item) => sum + (item.line.unitPrice * item.line.qty)).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _selectedItems.isNotEmpty
                            ? _submitReturn
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Process Return'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
