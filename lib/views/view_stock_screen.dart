import 'package:flutter/material.dart';

class ViewStockScreen extends StatefulWidget {
  const ViewStockScreen({super.key});

  @override
  State<ViewStockScreen> createState() => _ViewStockScreenState();
}

class _ViewStockScreenState extends State<ViewStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/viewStockScreen');
        },
        label: Text("Add Stock"),
      ),
    );
  }
}
