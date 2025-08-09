import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_event.dart';
import 'package:local_shoes_store_pos/views/view_stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Pages for navigation

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const Center(child: Text("Home Page")),
      const Center(child: ViewStockScreen()),
      const Center(child: Text("Profile Page")),
      Center(
        child: Switch(
          value: context.watch<ThemeBloc>().state == ThemeMode.light,
          onChanged: (v) {
            context.read<ThemeBloc>().add(
              ThemeChanged(!v),
            ); // invert because v=true means light
          },
        ),
      ),
    ];
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8, // shadow effect
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor, // bar background
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor, // active icon color
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor, // inactive icon color
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed, // keeps all labels visible
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_sharp),
            label: "Sale",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_bar_chart),
            label: "Stock",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.return_icon),
            label: "Return",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
        ],
      ),
    );
  }
}
