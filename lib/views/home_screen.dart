import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/views/view_stock_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';



import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() => const [
    Center(child: Text('Home Page')),
    ViewStockScreen(),
    Center(child: Text('Profile Page')),
    _MoreTab(),
  ];

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    final active = navTheme.selectedItemColor ?? theme.colorScheme.primary;
    final inactive = navTheme.unselectedItemColor ?? theme.disabledColor;

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.point_of_sale_sharp),
        title: 'Sale',
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.stacked_bar_chart),
        title: 'Stock',
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.return_icon),
        title: 'Return',
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.menu),
        title: 'More',
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    // ✅ Guarantee non-null colors
    final bgColor =
        navTheme.backgroundColor ?? theme.colorScheme.surface; // safe fallback
    final behindColor = theme.scaffoldBackgroundColor; // safe fallback

    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(context),

      backgroundColor: bgColor, // <- was null before

      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,


    );
  }
}

/// "More" tab with theme switch via your ThemeBloc.
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final isLight = context.watch<ThemeBloc>().state == ThemeMode.light;

    return  Center(
        child: Switch(
          value: context.watch<ThemeBloc>().state == ThemeMode.light,
          onChanged: (v) {
            context.read<ThemeBloc>().add(
              ThemeChanged(!v),
            ); // invert because v=true means light
          },
        ));
  }
}
