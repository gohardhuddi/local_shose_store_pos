import 'package:flutter/material.dart';
import 'package:local_shoes_store_pos/views/pos/view_sales.dart';
import 'package:local_shoes_store_pos/views/settings_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          buildTile(
            icon: Icons.settings,
            title: "Settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
          buildTile(
            icon: Icons.receipt_long,
            title: "View Sales History",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewSalesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Sales History")));
}
