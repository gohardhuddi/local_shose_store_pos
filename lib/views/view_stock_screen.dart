import 'package:flutter/material.dart';
import 'package:local_shoes_store_pos/views/add_stock_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../main.dart' show stockDb;        // assumes you exposed `stockDb` in main.dart

class ViewStockScreen extends StatefulWidget {
  const ViewStockScreen({super.key, this.onOpenDetails});

  final void Function(String sku)? onOpenDetails; // optional callback

  @override
  State<ViewStockScreen> createState() => _ViewStockScreenState();
}

class _ViewStockScreenState extends State<ViewStockScreen> {
  final categories = _sampleCategories;
  @override
  Widget build(BuildContext context) {
  return  Scaffold(
    body: ListView.builder(
        key: const PageStorageKey('categories_list'),
        // keeps expansion state on navigation
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              leading: CircleAvatar(child: Text(cat.brand[0])),
              title: Text(
                  cat.brand, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${cat.variants.length} items'),
              // Unique key helps Flutter preserve expanded/collapsed state per tile
              key: PageStorageKey('expansion_${cat.brand}'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ...cat.variants.map((item) =>
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.label_important_outline),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      trailing: Text('\$${item.price.toStringAsFixed(2)}'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped ${item.title}')),
                        );
                      },
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add all'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    floatingActionButton: FloatingActionButton.extended(onPressed: (){
      PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: AddStockScreen(),
        withNavBar: true, // OPTIONAL VALUE. True by default.
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      );

    }, label: Text("Add Stock")),
  );
  }

}

class Category {
  final String brand;
  final String articleCode;
  final String variant;
  final String quantity;
  final List<Item> variants;

  Category({required this.variant, required this.brand, required this.variants,required this.articleCode,required this.quantity});
}

class Item {
  final String title;
  final String subtitle;
  final double price;

  Item({required this.title, required this.subtitle, required this.price});
}

/* ---------- Fake data ---------- */

final _sampleCategories = <Category>[
  Category(brand: 'Shoes', variants: [
    Item(title: 'Runner Pro', subtitle: 'Lightweight road shoe', price: 79.99),
    Item(title: 'Trail Max', subtitle: 'Rugged trail runner', price: 99.50),
  ]),
  Category(brand: 'Hats', variants: [
    Item(title: 'Snapback', subtitle: 'Classic adjustable cap', price: 24.00),
    Item(title: 'Beanie', subtitle: 'Warm knit beanie', price: 18.75),
    Item(title: 'Bucket', subtitle: 'Casual bucket hat', price: 22.30),
  ]),
  Category(brand: 'Accessories', variants: [
    Item(title: 'Socks (3-pack)', subtitle: 'Breathable cotton blend', price: 12.90),
    Item(title: 'Laces', subtitle: 'Flat replacement laces', price: 4.50),
  ]),
];