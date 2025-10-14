import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/views/pos/pos_home_screen.dart';
import 'package:local_shoes_store_pos/views/pos/view_sales.dart';
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
  String _appBarTitle = CustomStrings.saleScreenHeading;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _controller.addListener(_updateTitle);
  }

  void _updateTitle() {
    if (!mounted) return;
    setState(() {
      switch (_controller.index) {
        case 0:
          _appBarTitle = CustomStrings.saleScreenHeading;
          break;
        case 1:
          _appBarTitle = CustomStrings.stockTitle;
          break;
        case 2:
          _appBarTitle = CustomStrings.profilePage;
          break;
        case 3:
          _appBarTitle = CustomStrings.more;
          break;
        default:
          _appBarTitle = 'Home';
      }
      _selectedIndex = _controller.index;
    });
  }

  List<Widget> get _screensMobile => const [
    POSHomeScreen(),
    ViewStockScreen(),
    Center(child: Text('Profile Page')),
    MoreScreen(),
  ];
  List<Widget> get _screensDesktop => const [
    POSHomeScreen(),
    ViewStockScreen(),
    Center(child: Text('Profile Page')),
    MoreScreen(),
    ViewSalesScreen(),
  ];

  List<PersistentBottomNavBarItem> _navItems(BuildContext context) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.primary;
    final inactive = theme.disabledColor;

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
        icon: const Icon(CupertinoIcons.person),
        title: CustomStrings.profilePage,
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

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;

    return SafeArea(
      child: Column(
        children: [
          AppBar(title: Text(_appBarTitle), centerTitle: true),
          Expanded(
            child: PersistentTabView(
              context,
              controller: _controller,
              screens: _screensMobile,
              items: _navItems(context),
              backgroundColor: bgColor,
              handleAndroidBackButtonPress: true,
              resizeToAvoidBottomInset: true,
              stateManagement: true,
              navBarStyle: NavBarStyle.style6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _controller.index = index;
                _updateTitle();
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_sharp),
                label: Text(CustomStrings.sale),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.stacked_bar_chart),
                label: Text(CustomStrings.stock),
              ),
              NavigationRailDestination(
                icon: Icon(CupertinoIcons.person),
                label: Text(CustomStrings.profilePage),
              ),
              NavigationRailDestination(
                icon: Icon(CupertinoIcons.settings),
                label: Text(CustomStrings.settings),
              ),
              NavigationRailDestination(
                icon: Icon(CupertinoIcons.table),
                label: Text(CustomStrings.salesRecord),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screensDesktop[_selectedIndex]),
        ],
      ),
    );
  }

  bool get _isDesktopLayout {
    final width = MediaQuery.of(context).size.width;
    return width > 800 || kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    return _isDesktopLayout
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }
}
