import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../controller/sales_bloc/sales_bloc.dart';
import '../../controller/sales_bloc/sales_events.dart';
import '../../controller/sales_bloc/sales_states.dart';

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({super.key});

  @override
  State<ViewSalesScreen> createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(GetAllSalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History'), centerTitle: true),
      body: BlocBuilder<SalesBloc, SalesStates>(
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
                  child: ExpansionTile(
                    key: PageStorageKey('sale_${sale.saleId}'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.receipt_long),
                    ),
                    title: Text(
                      'Sale ID: ${sale.saleId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Total: \$${sale.totalAmount}  |  ${DateFormat('dd MMM yyyy').format(DateTime.parse(sale.dateTime))}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    children: s.lines.map((line) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          'SKU: ${line.sku}',
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Qty: ${line.line.qty}  |  Price: \$${line.line.unitPrice}  |  Line Total: \$${line.line.lineTotal}',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
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
            'No sales recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
