// lib/views/view_helpers/resueables/connectivity_overlay_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/connectivity_controller/connectivity_events.dart';

import '../../../controller/connectivity_controller/connectivity_bloc.dart';
import '../../../controller/connectivity_controller/connectivity_state.dart';

class ConnectivityOverlayBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityOverlayBanner({super.key, required this.child});

  @override
  State<ConnectivityOverlayBanner> createState() =>
      _ConnectivityOverlayBannerState();
}

class _ConnectivityOverlayBannerState extends State<ConnectivityOverlayBanner> {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    // Fire once after the first frame so context is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectivityBloc>().add(
        const CheckInternetConnectivityEvent(),
      );
    });
  }

  @override
  void dispose() {
    _removeBanner();
    super.dispose();
  }

  double _bottomOffset(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom; // >0 when keyboard is visible
    final sysPadding = mq.padding.bottom; // system nav bar / gesture area
    return keyboard > 0 ? keyboard : sysPadding;
  }

  void _showBanner({required String text, required Color color}) {
    void insertNow() {
      final overlay = _overlayKey.currentState;
      if (overlay == null) return;

      _removeBanner(); // remove existing if any

      _entry = OverlayEntry(
        builder: (context) {
          final bottom = _bottomOffset(context);
          return Positioned(
            left: 0,
            right: 0,
            bottom: bottom, // 👈 stick to bottom (above keyboard/nav bar)
            child: Material(
              elevation: 6,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8), // small gap from edge
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: color,
                child: SafeArea(
                  top: false,
                  bottom: false, // we're already offsetting for bottom insets
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(_entry!);
    }

    // If the overlay isn't ready yet (first build), do it next frame.
    if (_overlayKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => insertNow());
    } else {
      insertNow();
    }
  }

  void _removeBanner() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        switch (state.status) {
          case ConnectivityStatus.noInternet:
            _showBanner(text: "You're offline", color: Colors.red);
            break;
          case ConnectivityStatus.internetOnlyBackendDown:
            _showBanner(
              text:
                  'Internet is working, but the backend is unavailable. Try again later.',
              color: Colors.orange,
            );
            break;
          case ConnectivityStatus.online:
            _removeBanner();
            break;
        }
      },
      // Provide our own Overlay so Overlay.of(...) is never required
      child: Overlay(
        key: _overlayKey,
        initialEntries: [OverlayEntry(builder: (_) => widget.child)],
      ),
    );
  }
}
