import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/views/sales/sales_home_screen.dart';
import 'package:local_shoes_store_pos/views/view_stock_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'more_view.dart';

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

  List<Widget> _buildScreens() => [
    SalesHomeScreen(),
    ViewStockScreen(),
    Center(child: Text(CustomStrings.profilePage)),
    MoreScreen(),
  ];

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    final active = navTheme.selectedItemColor ?? theme.colorScheme.primary;
    final inactive = navTheme.unselectedItemColor ?? theme.disabledColor;

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.point_of_sale_sharp),
        title: CustomStrings.sale,
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.stacked_bar_chart),
        title: CustomStrings.stock,
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.return_icon),
        title: CustomStrings.returnText,
        activeColorPrimary: active,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.menu),
        title: CustomStrings.more,
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

    return Scaffold(
      body: SafeArea(
        child: PersistentTabView(
          context,
          controller: _controller,
          screens: _buildScreens(),
          items: _navBarsItems(context),
          backgroundColor: bgColor,
          // <- was null before
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
        ),
      ),
    );
  }
}
