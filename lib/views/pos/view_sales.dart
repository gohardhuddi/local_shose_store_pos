import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({super.key});

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(GetAllSalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(CustomStrings.salesHistory),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                context.read<SalesBloc>().add(
                  SearchSalesEvent(value),
                ); // 🔥 LIVE SEARCH
              },
              decoration: InputDecoration(
                hintText: CustomStrings.searchByDate,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          context.read<SalesBloc>().add(SearchSalesEvent(''));
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<SalesBloc, SalesStates>(
              builder: (context, state) {
                if (state is SalesLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is GetAllSalesSuccessState) {
                  final sales = state.sales;
                  if (sales.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: sales.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final s = sales[index];
                      final sale = s.sale;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectionArea(
                          child: ExpansionTile(
                            key: PageStorageKey('sale_${sale.saleId}'),
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: const Icon(Icons.receipt_long),
                            ),
                            title: Text(
                              '${CustomStrings.saleID} ${sale.saleId}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${CustomStrings.saleID} ${CustomStrings.currency}${sale.totalAmount}  |  '
                              '${DateFormat('dd MMM yyyy').format(DateTime.parse(sale.dateTime))}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            children: s.lines.map((line) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  '${CustomStrings.sku} ${line.sku}',
                                  style: theme.textTheme.titleSmall,
                                ),
                                subtitle: Text(
                                  '${CustomStrings.qty} ${line.line.qty}  |  '
                                  '${CustomStrings.price}: ${CustomStrings.currency} ${line.line.unitPrice}  |  '
                                  '${CustomStrings.lineTotal}: ${CustomStrings.currency} ${line.line.lineTotal}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (state is SalesErrorState) {
                  return Center(child: Text('Error: ${state.error}'));
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            CustomStrings.noSales,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      final start = DateFormat('yyyy-MM-dd').format(range.start);
      final end = DateFormat('yyyy-MM-dd').format(range.end);

      context.read<SalesBloc>().add(
        GetSalesByDateRangeEvent(startDate: start, endDate: end),
      );
    }
  }
}
